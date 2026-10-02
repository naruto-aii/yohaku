import Foundation
import Observation

struct GrowState: Codable, Equatable {
    var plant: String
    var pot: String
    var hours: Double
    var visualFloor: Double
    var visualAtStart: Double
}

struct PlacedPair: Codable, Identifiable, Equatable {
    var id: UUID
    var plant: String
    var pot: String
    var nickname: String

    var shelfTitle: String { "\(plant)ー\(pot)" }
}

enum TutorialStep: String, Codable {
    case plant
    case pot
    case done
}

@MainActor
@Observable
final class GardenStore {
    private(set) var plantCounts: [String: Int]
    private(set) var potCounts: [String: Int]
    private(set) var grow: GrowState?
    private(set) var awaiting: PlacedPair?
    private(set) var shelf: [PlacedPair]
    private(set) var dropUnits: Int
    private(set) var pendingHours: Double
    private(set) var tutorial: TutorialStep
    private(set) var lastLines: [String]
    private(set) var draftPlant: String
    private(set) var draftPot: String

    @ObservationIgnored private var focusUnitRemainder: Double
    @ObservationIgnored private var granted: [UInt64]
    @ObservationIgnored private let defaults: UserDefaults

    static let unitsPerDrop = 3600
    static let pullCost = 100
    static let tenCost = 1000
    static let tutorialDrops = 200

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = Self.load(from: defaults)
        plantCounts = Self.clean(saved.plantCounts, kind: .plant)
        potCounts = Self.clean(saved.potCounts, kind: .pot)
        if let grow = saved.grow,
           Catalog.plantIndex[grow.plant] != nil,
           Catalog.potIndex[grow.pot] != nil {
            self.grow = grow
        } else {
            grow = nil
        }
        if let awaiting = saved.awaiting,
           Catalog.plantIndex[awaiting.plant] != nil,
           Catalog.potIndex[awaiting.pot] != nil {
            self.awaiting = awaiting
        } else {
            awaiting = nil
        }
        shelf = saved.shelf.filter { Catalog.plantIndex[$0.plant] != nil && Catalog.potIndex[$0.pot] != nil }
        dropUnits = max(0, saved.dropUnits)
        pendingHours = max(0, saved.pendingHours)
        tutorial = saved.tutorial
        focusUnitRemainder = saved.focusUnitRemainder
        granted = saved.granted
        lastLines = []
        draftPlant = grow?.plant ?? Self.firstOwned(plantCounts) ?? Catalog.starterPlant
        draftPot = grow?.pot ?? Self.firstOwned(potCounts) ?? Catalog.starterPot
        if saved.tutorial == .plant && saved.dropUnits == 0 && plantCounts.isEmpty && potCounts.isEmpty {
            dropUnits = Self.tutorialDrops * Self.unitsPerDrop
            save()
        }
    }

    var dropText: String {
        let value = Double(dropUnits) / Double(Self.unitsPerDrop)
        let whole = value.rounded()
        if abs(value - whole) < 0.0001 {
            return String(Int(whole))
        }
        return String(format: "%.1f", value)
    }

    var canSingle: Bool { tutorial == .done && dropUnits >= Self.pullCost * Self.unitsPerDrop }
    var canTen: Bool { tutorial == .done && dropUnits >= Self.tenCost * Self.unitsPerDrop }

    var currentPlant: CatalogItem? {
        guard let grow else { return nil }
        return Catalog.plantIndex[grow.plant]
    }

    var currentPot: CatalogItem? {
        guard let grow else { return nil }
        return Catalog.potIndex[grow.pot]
    }

    var requiredHours: Double? {
        guard let plant = currentPlant, let pot = currentPot else { return nil }
        return GrowthMath.requiredHours(plant: plant.rarity, pot: pot.rarity)
    }

    var realProgress: Double {
        guard let grow, let required = requiredHours, required > 0 else { return 0 }
        return min(1, grow.hours / required)
    }

    var displayProgress: Double {
        guard grow != nil else { return awaiting == nil ? 0 : 1 }
        let real = realProgress
        if real >= 1 { return 1 }
        return min(0.99, max(real, grow?.visualFloor ?? 0))
    }

    var stageIndex: Int {
        GrowthMath.stageIndex(display: displayProgress, bloomed: realProgress >= 1 || awaiting != nil && grow == nil)
    }

    var stageLabel: String { GrowthMath.stageWord(stageIndex) }

    var progressLabel: String? {
        guard let grow, let required = requiredHours else { return nil }
        return "\(GrowthMath.hourText(grow.hours)) / \(GrowthMath.hourText(required)) 時間"
    }

    var pairTitle: String? {
        if let grow { return "\(grow.plant)ー\(grow.pot)" }
        if let awaiting { return awaiting.shelfTitle }
        return nil
    }

    func count(_ name: String, kind: CatalogKind) -> Int {
        switch kind {
        case .plant: plantCounts[name] ?? 0
        case .pot: potCounts[name] ?? 0
        }
    }

    func freeCount(_ name: String, kind: CatalogKind) -> Int {
        max(0, count(name, kind: kind) - reserved(name, kind: kind))
    }

    func ownedNames(_ kind: CatalogKind) -> [String] {
        Catalog.items(kind).map(\.name).filter { count($0, kind: kind) > 0 }
    }

    var canBegin: Bool {
        tutorial == .done && grow == nil && awaiting == nil
            && freeCount(draftPlant, kind: .plant) > 0
            && freeCount(draftPot, kind: .pot) > 0
    }

    func recordFocus(seconds: TimeInterval) {
        guard seconds > 0 else { return }
        focusUnitRemainder += seconds * 100
        let units = Int(floor(focusUnitRemainder + 0.0000001))
        if units > 0 {
            focusUnitRemainder -= Double(units)
            dropUnits += units
        }
        let hours = seconds / 3600
        if grow != nil {
            applyHours(hours)
        } else {
            pendingHours += hours
            save()
        }
    }

    func noteFocusBegan() {
        guard var current = grow, let required = requiredHours, required > 0 else { return }
        let real = min(1, current.hours / required)
        current.visualAtStart = min(0.99, max(real, current.visualFloor))
        grow = current
        save()
    }

    func noteSessionEnded() {
        guard var current = grow, let required = requiredHours, required > 0 else { return }
        let real = min(1, current.hours / required)
        if real >= 1 { return }
        let before = min(0.99, max(real, current.visualFloor))
        let index = GrowthMath.stageIndex(display: before, bloomed: false)
        let nextStage = Double(index + 1) / Double(GrowthMath.stageCount)
        let target = min(0.99, max(before + 0.02, nextStage))
        current.visualFloor = target
        grow = current
        save()
    }

    func pullTutorial() {
        switch tutorial {
        case .plant:
            guard spend(Self.pullCost) else { return }
            _ = receive(Catalog.plantIndex[Catalog.starterPlant]!)
            tutorial = .pot
            lastLines = [Copy.received(Catalog.starterPlant)]
            draftPlant = Catalog.starterPlant
        case .pot:
            guard spend(Self.pullCost) else { return }
            _ = receive(Catalog.potIndex[Catalog.starterPot]!)
            tutorial = .done
            lastLines = [Copy.received(Catalog.starterPot)]
            draftPot = Catalog.starterPot
        case .done:
            return
        }
        save()
    }

    func pull(kind: CatalogKind, times: Int) {
        guard tutorial == .done else { return }
        guard times == 1 || times == 10 else { return }
        let cost = times == 1 ? Self.pullCost : Self.tenCost
        guard spend(cost) else { return }
        var lines: [String] = []
        for _ in 0..<times {
            let item = Catalog.roll(
                kind: kind,
                rarityUnit: Double.random(in: 0..<1),
                indexUnit: Double.random(in: 0..<1)
            )
            lines.append(receive(item))
        }
        lastLines = lines
        save()
    }

    func choosePlant(_ name: String) {
        guard grow == nil, freeCount(name, kind: .plant) > 0 else { return }
        draftPlant = name
    }

    func choosePot(_ name: String) {
        guard grow == nil, freeCount(name, kind: .pot) > 0 else { return }
        draftPot = name
    }

    @discardableResult
    func begin() -> Bool {
        guard canBegin else { return false }
        grow = GrowState(plant: draftPlant, pot: draftPot, hours: 0, visualFloor: 0, visualAtStart: 0)
        let banked = pendingHours
        pendingHours = 0
        if banked > 0 {
            applyHours(banked)
        } else {
            save()
        }
        return true
    }

    func placeNamed(_ nickname: String) {
        guard var waiting = awaiting else { return }
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        waiting.nickname = trimmed
        waiting.id = UUID()
        shelf.insert(waiting, at: 0)
        awaiting = nil
        draftPlant = waiting.plant
        draftPot = waiting.pot
        save()
    }

    func grantPack(transactionID: UInt64, productID: String) {
        guard let pack = DropPack.matching(productID) else { return }
        guard !granted.contains(transactionID) else { return }
        granted.append(transactionID)
        dropUnits += pack.drops * Self.unitsPerDrop
        save()
    }

    private func spend(_ drops: Int) -> Bool {
        let cost = drops * Self.unitsPerDrop
        guard dropUnits >= cost else { return false }
        dropUnits -= cost
        return true
    }

    private func receive(_ item: CatalogItem) -> String {
        let held = count(item.name, kind: item.kind)
        if held >= Catalog.holdingCap {
            let added = item.rarity.completionHours / Double(Catalog.holdingCap)
            if grow != nil {
                applyHours(added)
            } else {
                pendingHours += added
            }
            return Copy.overflow(name: item.name, hours: GrowthMath.hourText(added))
        }
        switch item.kind {
        case .plant:
            plantCounts[item.name] = held + 1
        case .pot:
            potCounts[item.name] = held + 1
        }
        return Copy.received(item.name)
    }

    private func applyHours(_ hours: Double) {
        guard hours > 0, var current = grow else { return }
        guard let plant = Catalog.plantIndex[current.plant], let pot = Catalog.potIndex[current.pot] else { return }
        let required = GrowthMath.requiredHours(plant: plant.rarity, pot: pot.rarity)
        current.hours += hours
        if current.hours + 0.0000001 < required {
            grow = current
            save()
            return
        }
        let extra = current.hours - required
        awaiting = PlacedPair(id: UUID(), plant: current.plant, pot: current.pot, nickname: "")
        grow = nil
        if extra > 0.0001 {
            pendingHours += extra
        }
        save()
    }

    private func reserved(_ name: String, kind: CatalogKind) -> Int {
        var used = shelf.reduce(0) { partial, pair in
            let matches = kind == .plant ? pair.plant == name : pair.pot == name
            return partial + (matches ? 1 : 0)
        }
        if let grow {
            let matches = kind == .plant ? grow.plant == name : grow.pot == name
            if matches { used += 1 }
        }
        if let awaiting {
            let matches = kind == .plant ? awaiting.plant == name : awaiting.pot == name
            if matches { used += 1 }
        }
        return used
    }

    private func save() {
        let saved = Saved(
            plantCounts: plantCounts,
            potCounts: potCounts,
            grow: grow,
            awaiting: awaiting,
            shelf: shelf,
            dropUnits: dropUnits,
            pendingHours: pendingHours,
            tutorial: tutorial,
            focusUnitRemainder: focusUnitRemainder,
            granted: granted
        )
        if let data = try? JSONEncoder().encode(saved) {
            defaults.set(data, forKey: Keys.garden)
        }
    }

    private static func load(from defaults: UserDefaults) -> Saved {
        guard let data = defaults.data(forKey: Keys.garden),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else {
            return Saved(
                plantCounts: [:],
                potCounts: [:],
                grow: nil,
                awaiting: nil,
                shelf: [],
                dropUnits: tutorialDrops * unitsPerDrop,
                pendingHours: 0,
                tutorial: .plant,
                focusUnitRemainder: 0,
                granted: []
            )
        }
        return saved
    }

    private static func clean(_ counts: [String: Int], kind: CatalogKind) -> [String: Int] {
        var next: [String: Int] = [:]
        for (name, count) in counts {
            guard Catalog.item(name, kind: kind) != nil, count > 0 else { continue }
            next[name] = min(Catalog.holdingCap, count)
        }
        return next
    }

    private static func firstOwned(_ counts: [String: Int]) -> String? {
        counts.keys.sorted().first
    }

    private struct Saved: Codable {
        var plantCounts: [String: Int]
        var potCounts: [String: Int]
        var grow: GrowState?
        var awaiting: PlacedPair?
        var shelf: [PlacedPair]
        var dropUnits: Int
        var pendingHours: Double
        var tutorial: TutorialStep
        var focusUnitRemainder: Double
        var granted: [UInt64]
    }

    private enum Keys {
        static let garden = "yohaku.garden.v2"
    }
}
