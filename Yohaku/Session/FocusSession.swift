import Foundation
import Observation

@MainActor
@Observable
final class FocusSession {
    enum Phase: Equatable {
        case focus
        case rest

        var title: String {
            switch self {
            case .focus: Copy.focus
            case .rest: Copy.rest
            }
        }
    }

    private(set) var phase: Phase = .focus
    private(set) var remaining: TimeInterval = 25 * 60
    private(set) var isRunning = false
    private(set) var focusMinutes = 25
    private(set) var breakMinutes = 5

    @ObservationIgnored var onFocusCompleted: (() -> Void)?
    @ObservationIgnored var onFocusElapsed: ((TimeInterval) -> Void)?
    @ObservationIgnored var onFocusBegan: (() -> Void)?
    @ObservationIgnored var onChime: (() -> Void)?
    @ObservationIgnored private var endDate: Date?
    @ObservationIgnored private var focusAccountedAt: Date?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var focusDuration: TimeInterval { TimeInterval(focusMinutes * 60) }
    var breakDuration: TimeInterval { TimeInterval(breakMinutes * 60) }

    var clockText: String {
        let total = max(0, Int(ceil(remaining - 0.05)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var accessibilityTime: String {
        let total = max(0, Int(ceil(remaining - 0.05)))
        return "\(phase.title)、残り \(total / 60) 分 \(total % 60) 秒"
    }

    func toggle() {
        if isRunning {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !isRunning else { return }
        if remaining <= 0.05 {
            remaining = phase == .focus ? focusDuration : breakDuration
        }
        let now = Date()
        isRunning = true
        endDate = now.addingTimeInterval(remaining)
        focusAccountedAt = phase == .focus ? now : nil
        if phase == .focus {
            onFocusBegan?()
        }
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        settleFocus(now: Date())
        if let endDate {
            remaining = max(0, endDate.timeIntervalSinceNow)
        }
        isRunning = false
        self.endDate = nil
        focusAccountedAt = nil
        stopTicking()
    }

    func catchUp(now: Date = .now) {
        settleFocus(now: now)
        guard isRunning, let end = endDate else { return }
        if now < end {
            remaining = end.timeIntervalSince(now)
            return
        }

        let overrun = now.timeIntervalSince(end)
        if phase == .focus {
            onFocusCompleted?()
            onChime?()
            if overrun < breakDuration {
                phase = .rest
                remaining = breakDuration - overrun
                endDate = now.addingTimeInterval(remaining)
            } else {
                phase = .focus
                remaining = focusDuration
                isRunning = false
                endDate = nil
                stopTicking()
            }
        } else {
            phase = .focus
            remaining = focusDuration
            isRunning = false
            endDate = nil
            onChime?()
            stopTicking()
        }
    }

    func setFocusMinutes(_ minutes: Int, persist: Bool) {
        let next = min(120, max(1, minutes))
        let previous = focusMinutes
        focusMinutes = next
        if !isRunning, phase == .focus, previous != next {
            remaining = TimeInterval(next * 60)
            endDate = nil
        }
        if persist {
            defaults.set(next, forKey: Keys.focus)
        }
    }

    func setBreakMinutes(_ minutes: Int, persist: Bool) {
        let next = min(60, max(1, minutes))
        let previous = breakMinutes
        breakMinutes = next
        if !isRunning, phase == .rest, previous != next {
            remaining = TimeInterval(next * 60)
            endDate = nil
        }
        if persist {
            defaults.set(next, forKey: Keys.rest)
        }
    }

    func loadSavedDurations() {
        if let storedFocus = defaults.object(forKey: Keys.focus) as? Int {
            let next = min(120, max(1, storedFocus))
            let showingFullLength = !isRunning && phase == .focus && abs(remaining - focusDuration) < 1
            focusMinutes = next
            if showingFullLength {
                remaining = TimeInterval(next * 60)
            }
        }
        if let storedBreak = defaults.object(forKey: Keys.rest) as? Int {
            let next = min(60, max(1, storedBreak))
            let showingFullLength = !isRunning && phase == .rest && abs(remaining - breakDuration) < 1
            breakMinutes = next
            if showingFullLength {
                remaining = TimeInterval(next * 60)
            }
        }
    }

    func applyFreeDefaults() {
        let previousFocus = focusMinutes
        let previousBreak = breakMinutes
        focusMinutes = 25
        breakMinutes = 5
        guard !isRunning else { return }
        if phase == .focus, previousFocus != 25 {
            remaining = 25 * 60
            endDate = nil
        }
        if phase == .rest, previousBreak != 5 {
            remaining = 5 * 60
            endDate = nil
        }
    }

    private func settleFocus(now: Date) {
        guard isRunning, phase == .focus, let end = endDate, let from = focusAccountedAt else { return }
        let until = min(now, end)
        let delta = until.timeIntervalSince(from)
        if delta > 0 {
            onFocusElapsed?(delta)
        }
        focusAccountedAt = now < end ? now : nil
    }

    private func startTicking() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.catchUp()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicking() {
        ticker?.invalidate()
        ticker = nil
    }

    private enum Keys {
        static let focus = "yohaku.focusMinutes"
        static let rest = "yohaku.breakMinutes"
    }
}
