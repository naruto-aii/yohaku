import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let session = FocusSession()
    let noise = NoiseEngine()
    let purchases = PurchaseManager()
    let streak = StreakStore()
    let garden = GardenStore()

    @ObservationIgnored private var didStart = false
    @ObservationIgnored private var appliedUnlock: Bool?

    init() {
        session.onFocusElapsed = { [weak self] seconds in
            self?.garden.recordFocus(seconds: seconds)
        }
        purchases.onConsumable = { [weak self] id, productID in
            self?.garden.grantPack(transactionID: id, productID: productID)
        }
        session.onFocusBegan = { [weak self] in
            self?.garden.noteFocusBegan()
        }
        session.onFocusCompleted = { [weak self] in
            guard let self else { return }
            self.streak.recordCompletion(persist: self.purchases.isUnlocked)
            self.garden.noteSessionEnded()
        }
        session.onChime = { [weak self] in
            self?.noise.playChime()
        }
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        purchases.startListening()
        Task {
            await purchases.load()
            applyUnlockState()
        }
    }

    func becameActive() {
        session.catchUp()
        streak.noteTime()
        noise.resumeEngineIfNeeded()
        Task {
            await purchases.refreshEntitlements()
            applyUnlockState()
        }
    }

    func isLocked(_ kind: NoiseKind) -> Bool {
        !kind.isFree && !purchases.isUnlocked
    }

    func toggleNoise(_ kind: NoiseKind) {
        if isLocked(kind) { return }
        if noise.playing == kind {
            noise.stop()
        } else {
            noise.start(kind)
        }
    }

    func stepFocus(_ delta: Int) {
        guard purchases.isUnlocked else { return }
        session.setFocusMinutes(session.focusMinutes + delta, persist: true)
    }

    func stepBreak(_ delta: Int) {
        guard purchases.isUnlocked else { return }
        session.setBreakMinutes(session.breakMinutes + delta, persist: true)
    }

    func applyUnlockState() {
        let unlocked = purchases.isUnlocked
        if appliedUnlock == unlocked { return }
        let previous = appliedUnlock
        appliedUnlock = unlocked
        if unlocked {
            session.loadSavedDurations()
            streak.adoptSavedHistory()
        } else if previous == true {
            session.applyFreeDefaults()
        }
    }
}
