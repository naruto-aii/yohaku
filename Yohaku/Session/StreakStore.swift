import Foundation
import Observation

/// Completed focus blocks across consecutive local days.
/// A gap of one calendar day ends the run. The next completion starts again at 1.
@MainActor
@Observable
final class StreakStore {
    private(set) var count = 0
    private(set) var clock = Date()

    @ObservationIgnored private var lastStamp: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    var displayCount: Int {
        guard let lastStamp else { return 0 }
        let today = stamp(for: clock)
        if lastStamp == today || lastStamp == stamp(for: yesterday(before: clock)) {
            return count
        }
        return 0
    }

    func noteTime(_ date: Date = .now) {
        clock = date
    }

    func recordCompletion(persist: Bool, now: Date = .now) {
        clock = now
        let today = stamp(for: now)
        if lastStamp == today || lastStamp == stamp(for: yesterday(before: now)) {
            count += 1
        } else {
            count = 1
        }
        lastStamp = today
        if persist {
            write()
        }
    }

    /// Paid history replaces the session. If nothing was saved, keep what is on screen and write it.
    func adoptSavedHistory() {
        if let savedCount = defaults.object(forKey: Keys.count) as? Int,
           let day = defaults.string(forKey: Keys.day) {
            count = savedCount
            lastStamp = day
        } else {
            write()
        }
        noteTime()
    }

    private func write() {
        defaults.set(count, forKey: Keys.count)
        if let lastStamp {
            defaults.set(lastStamp, forKey: Keys.day)
        }
    }

    private func stamp(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private func yesterday(before date: Date) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: -1, to: start) ?? start
    }

    private enum Keys {
        static let count = "yohaku.streak.count"
        static let day = "yohaku.streak.day"
    }
}
