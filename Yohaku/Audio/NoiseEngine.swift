import AVFoundation
import Foundation
import MediaPlayer
import Observation

enum NoiseKind: Int, CaseIterable, Identifiable {
    case white = 0
    case pink = 1
    case brown = 2
    case rain = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .white: Copy.white
        case .pink: Copy.pink
        case .brown: Copy.brown
        case .rain: Copy.rain
        }
    }

    var isFree: Bool { self == .white }
}

@MainActor
@Observable
final class NoiseEngine {
    private(set) var playing: NoiseKind?
    private(set) var failure: String?

    @ObservationIgnored private let dsp = DSPBox()
    @ObservationIgnored private var engine = AVAudioEngine()
    @ObservationIgnored private var prepared = false
    @ObservationIgnored private var commandsInstalled = false
    @ObservationIgnored private var idleToken = 0
    @ObservationIgnored private var lastKind: NoiseKind?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    func start(_ kind: NoiseKind) {
        idleToken += 1
        lastKind = kind
        playing = kind
        failure = nil
        dsp.with { state in
            state.pendingKind = kind.rawValue
        }
        do {
            try ensureRunning()
            publishNowPlaying(kind)
        } catch {
            playing = nil
            dsp.with { $0.pendingKind = -1 }
            failure = Copy.audioFailed
        }
    }

    func stop() {
        playing = nil
        failure = nil
        dsp.with { state in
            state.pendingKind = -1
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        scheduleIdleStop(after: 0.45)
    }

    func playChime() {
        do {
            try ensureRunning()
        } catch {
            failure = Copy.audioFailed
            return
        }
        failure = nil
        dsp.with { state in
            state.toneLeft = Int(0.72 * state.sampleRate)
            state.tonePhase = 0
            state.tonePhase2 = 0
        }
        if playing == nil {
            scheduleIdleStop(after: 1.3)
        }
    }

    func resumeEngineIfNeeded() {
        guard playing != nil else { return }
        try? ensureRunning()
    }

    private func ensureRunning() throws {
        if !prepared {
            try prepare()
        }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        if !engine.isRunning {
            try engine.start()
        }
    }

    private func prepare() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        let rate = session.sampleRate > 0 ? session.sampleRate : 44_100
        let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2)
        dsp.with { $0.sampleRate = Float(rate) }
        let node = Self.makeNode(format: format, dsp: dsp)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.prepare()
        prepared = true
        installCommandsIfNeeded()
        observeSession()
    }

    private nonisolated static func makeNode(format: AVAudioFormat, dsp: DSPBox) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { isSilence, _, frameCount, audioBufferList in
            let silent = dsp.render(frames: Int(frameCount), list: audioBufferList)
            isSilence.pointee = ObjCBool(silent)
            return noErr
        }
    }

    private func scheduleIdleStop(after delay: TimeInterval) {
        idleToken += 1
        let token = idleToken
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self?.stopIfIdle(token: token)
        }
    }

    private func stopIfIdle(token: Int) {
        guard token == idleToken, playing == nil else { return }
        let busy = dsp.with { $0.toneLeft > 0 || $0.gain > 0.01 }
        if busy {
            scheduleIdleStop(after: 0.3)
            return
        }
        engine.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func publishNowPlaying(_ kind: NoiseKind) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = Copy.appName
        info[MPMediaItemPropertyArtist] = kind.title
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func installCommandsIfNeeded() {
        guard !commandsInstalled else { return }
        commandsInstalled = true
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = true
        commands.pauseCommand.isEnabled = true
        commands.togglePlayPauseCommand.isEnabled = true
        commands.nextTrackCommand.isEnabled = false
        commands.previousTrackCommand.isEnabled = false
        commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resumeLast() }
            return .success
        }
        commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.stop() }
            return .success
        }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.playing == nil {
                    self.resumeLast()
                } else {
                    self.stop()
                }
            }
            return .success
        }
    }

    private func resumeLast() {
        guard let lastKind else { return }
        start(lastKind)
    }

    private func observeSession() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                self?.handleInterruption(note)
            }
        })
        observers.append(center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildAfterReset()
            }
        })
    }

    private func handleInterruption(_ note: Notification) {
        guard
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }
        guard type == .ended, playing != nil else { return }
        let optionsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
        if options.contains(.shouldResume) {
            try? ensureRunning()
        }
    }

    private func rebuildAfterReset() {
        engine.stop()
        engine = AVAudioEngine()
        prepared = false
        if playing != nil {
            try? ensureRunning()
        }
    }

}

private final class DSPBox: @unchecked Sendable {
    private let lock = NSLock()
    private var state = DSP()

    func with<T>(_ body: (inout DSP) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&state)
    }

    func render(frames: Int, list: UnsafeMutablePointer<AudioBufferList>) -> Bool {
        let buffers = UnsafeMutableAudioBufferListPointer(list)
        guard frames > 0, let first = buffers.first, let data = first.mData else {
            return true
        }
        let pointer = data.assumingMemoryBound(to: Float.self)
        let channels = Int(first.mNumberChannels)
        return with { state in
            if buffers.count >= 2, let rightData = buffers[1].mData {
                let right = rightData.assumingMemoryBound(to: Float.self)
                return state.renderSplit(frames: frames, left: pointer, right: right)
            }
            if channels <= 1 {
                return state.renderSplit(frames: frames, left: pointer, right: nil)
            }
            return state.renderInterleaved(frames: frames, pointer: pointer, channels: channels)
        }
    }
}

private struct DSP {
    var kind = -1
    var pendingKind = -1
    var targetGain: Float = 0
    var gain: Float = 0
    var seed: UInt32 = 0xA341316C
    var sampleRate: Float = 44_100

    var b0: Float = 0
    var b1: Float = 0
    var b2: Float = 0
    var b3: Float = 0
    var b4: Float = 0
    var b5: Float = 0
    var b6: Float = 0
    var brown: Float = 0
    var highpassX: Float = 0
    var highpassY: Float = 0
    var bed: Float = 0
    var drop: Float = 0
    var dropDecay: Float = 0.998
    var toneLeft = 0
    var tonePhase: Float = 0
    var tonePhase2: Float = 0

    mutating func renderSplit(
        frames: Int,
        left: UnsafeMutablePointer<Float>,
        right: UnsafeMutablePointer<Float>?
    ) -> Bool {
        var silent = true
        if kind < 0, pendingKind < 0, gain < 0.0001, toneLeft == 0 {
            for index in 0..<frames {
                left[index] = 0
                right?[index] = 0
            }
            return true
        }
        for index in 0..<frames {
            let sample = nextSample()
            left[index] = sample
            right?[index] = sample
            if abs(sample) > 0.0001 {
                silent = false
            }
        }
        return silent
    }

    mutating func renderInterleaved(frames: Int, pointer: UnsafeMutablePointer<Float>, channels: Int) -> Bool {
        var silent = true
        for index in 0..<frames {
            let sample = nextSample()
            let base = index * channels
            pointer[base] = sample
            if channels > 1 {
                pointer[base + 1] = sample
            }
            if abs(sample) > 0.0001 {
                silent = false
            }
        }
        return silent
    }

    mutating func nextSample() -> Float {
        reconcileKind()
        let white = unit() * 2 - 1
        let signal: Float
        switch kind {
        case 0:
            signal = white * 0.16
        case 1:
            signal = pink(white) * 0.053
        case 2:
            signal = brownian(white) * 1.16
        case 3:
            signal = rain(white)
        default:
            signal = 0
        }

        let step: Float = 0.00008
        if gain < targetGain {
            gain = min(targetGain, gain + step)
        } else if gain > targetGain {
            gain = max(targetGain, gain - step)
        }

        var mixed = signal * gain
        if toneLeft > 0 {
            let envelope = toneEnvelope()
            let chime = (sin(tonePhase) * 0.9 + sin(tonePhase2) * 0.18) * envelope * 0.07
            advanceTone()
            toneLeft -= 1
            mixed = mixed * (1 - 0.45 * envelope) + chime
        }
        return saturate(mixed)
    }

    mutating func reconcileKind() {
        guard pendingKind != kind else { return }
        if gain > 0.02, kind >= 0 {
            targetGain = 0
            return
        }
        kind = pendingKind
        targetGain = pendingKind >= 0 ? 1 : 0
    }

    mutating func advanceTone() {
        let twoPi: Float = 6.28318530718
        let rate = max(sampleRate, 8_000)
        tonePhase += twoPi * 311 / rate
        tonePhase2 += twoPi * 622 / rate
        if tonePhase > twoPi { tonePhase -= twoPi }
        if tonePhase2 > twoPi { tonePhase2 -= twoPi }
    }

    /// Paul Kellet's economy pink-noise filter.
    mutating func pink(_ white: Float) -> Float {
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        return pink
    }

    mutating func brownian(_ white: Float) -> Float {
        brown = brown * 0.995 + white * 0.02
        let output = brown - highpassX + 0.995 * highpassY
        highpassX = brown
        highpassY = output
        return output
    }

    mutating func rain(_ white: Float) -> Float {
        bed += (white * 0.55 - bed) * 0.01
        if drop < 0.002 {
            if unit() < 0.00055 {
                drop = 0.3 + unit() * 0.9
                dropDecay = 0.996 + unit() * 0.003
            }
        } else {
            drop *= dropDecay
        }
        return (bed * 1.15 + white * drop * 0.62) * 1.22
    }

    mutating func toneEnvelope() -> Float {
        let rate = max(sampleRate, 8_000)
        let total = max(1, Int(0.72 * rate))
        let age = total - toneLeft
        let attack = min(1, Float(max(0, age)) / (0.02 * rate))
        let decay = Float(max(0, toneLeft)) / Float(total)
        return attack * decay * decay
    }

    mutating func unit() -> Float {
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return Float(seed >> 8) * (1.0 / 16_777_216.0)
    }

    func saturate(_ value: Float) -> Float {
        let clamped = max(-1.5, min(1.5, value))
        let square = clamped * clamped
        return clamped * (27 + square) / (27 + 9 * square)
    }
}
