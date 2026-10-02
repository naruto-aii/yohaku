import Foundation
import Observation

enum GachaPool: String, CaseIterable, Identifiable {
    case pot
    case plant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pot: "鉢"
        case .plant: "植物"
        }
    }
}

struct GrowState: Codable, Equatable {
    var plant: String
    var pot: String
    var hours: Double
}

struct PlacedPair: Codable, Identifiable, Equatable {
    var id: UUID
    var plant: String
    var pot: String
}

@MainActor
@Observable
final class GardenStore {
    private(set) var ownedPots: [String]
    private(set) var ownedPlants: [String]
    private(set) var grow: GrowState?
    private(set) var shelf: [PlacedPair]
    private(set) var materialHalves: Int
    private(set) var pendingHours: Double
    private(set) var lastResult: String?

    private var draftPlant: String
    private var draftPot: String
    @ObservationIgnored private var focusRemainder: Double
    @ObservationIgnored private var granted: [UInt64]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = Self.load(from: defaults)
        ownedPots = saved.ownedPots.filter { Catalog.pot($0) != nil }
        ownedPlants = saved.ownedPlants.filter { Catalog.plant($0) != nil }
        if ownedPots.isEmpty { ownedPots = [Self.starterPot] }
        if ownedPlants.isEmpty { ownedPlants = [Self.starterPlant] }
        if let grow = saved.grow, Catalog.plant(grow.plant) != nil, Catalog.pot(grow.pot) != nil {
            self.grow = grow
        } else {
            grow = nil
        }
        shelf = saved.shelf.filter { Catalog.plant($0.plant) != nil && Catalog.pot($0.pot) != nil }
        materialHalves = max(0, saved.materialHalves)
        focusRemainder = max(0, saved.focusRemainder)
        pendingHours = max(0, saved.pendingHours)
        granted = saved.granted
        if grow == nil, shelf.isEmpty {
            grow = GrowState(plant: Self.starterPlant, pot: Self.starterPot, hours: 0)
        }
        draftPlant = grow?.plant ?? ownedPlants[0]
        draftPot = grow?.pot ?? ownedPots[0]
        if saved.ownedPots.isEmpty {
            save()
        }
    }

    var materialLabel: String {
        if materialHalves % 2 == 0 {
            return "\(materialHalves / 2)"
        }
        return String(format: "%.1f", Double(materialHalves) / 2)
    }

    var canPull: Bool { materialHalves >= 2 }

    var canRetarget: Bool {
        guard let grow else { return true }
        return grow.hours == 0
    }

    var selectedPlantName: String { grow?.plant ?? draftPlant }
    var selectedPotName: String { grow?.pot ?? draftPot }

    var currentPlant: PlantSpec? {
        guard let grow else { return nil }
        return Catalog.plant(grow.plant)
    }

    var currentPot: PotSpec? {
        guard let grow else { return nil }
        return Catalog.pot(grow.pot)
    }

    var requiredHours: Double? {
        guard let plant = currentPlant, let pot = currentPot else { return nil }
        return GrowthMath.requiredHours(plant: plant.rarity, pot: pot.rarity)
    }

    var stage: Int {
        guard let grow, let required = requiredHours else { return 0 }
        return GrowthMath.stage(hours: grow.hours, required: required)
    }

    var progressLabel: String? {
        guard let grow, let required = requiredHours else { return nil }
        return "\(GrowthMath.hourText(grow.hours)) / \(GrowthMath.hourText(required)) 時間"
    }

    var stageLabel: String { GrowthMath.stageWord(stage) }

    var ownedPotSpecs: [PotSpec] { ownedPots.compactMap { Catalog.pot($0) } }
    var ownedPlantSpecs: [PlantSpec] { ownedPlants.compactMap { Catalog.plant($0) } }

    func recordFocus(seconds: TimeInterval) {
        guard seconds > 0 else { return }
        focusRemainder += seconds
        while focusRemainder >= 3600 {
            focusRemainder -= 3600
            materialHalves += 2
        }
        let hours = seconds / 3600
        if grow != nil {
            _ = apply(hours)
        } else {
            pendingHours += hours
            save()
        }
    }

    func pull(_ pool: GachaPool) {
        guard canPull else { return }
        let rarity = Rarity.rolled(Double.random(in: 0..<1))
        switch pool {
        case .pot:
            guard let spec = Catalog.pots.filter({ $0.rarity == rarity }).randomElement() else { return }
            materialHalves -= 2
            lastResult = take(name: spec.name, rarity: spec.rarity, kind: pool.title, plants: false)
        case .plant:
            guard let spec = Catalog.plants.filter({ $0.rarity == rarity }).randomElement() else { return }
            materialHalves -= 2
            lastResult = take(name: spec.name, rarity: spec.rarity, kind: pool.title, plants: true)
        }
    }

    func choosePlant(_ name: String) {
        guard ownedPlants.contains(name) else { return }
        if var current = grow {
            guard current.hours == 0 else { return }
            current.plant = name
            grow = current
            draftPlant = name
            save()
        } else {
            draftPlant = name
        }
    }

    func choosePot(_ name: String) {
        guard ownedPots.contains(name) else { return }
        if var current = grow {
            guard current.hours == 0 else { return }
            current.pot = name
            grow = current
            draftPot = name
            save()
        } else {
            draftPot = name
        }
    }

    func begin() {
        guard grow == nil else { return }
        guard ownedPlants.contains(draftPlant), ownedPots.contains(draftPot) else { return }
        grow = GrowState(plant: draftPlant, pot: draftPot, hours: 0)
        let banked = pendingHours
        pendingHours = 0
        if banked > 0 {
            _ = apply(banked)
        } else {
            save()
        }
    }

    func grantSeed(transactionID: UInt64) {
        guard !granted.contains(transactionID) else { return }
        granted.append(transactionID)
        materialHalves += 6
        if grow != nil {
            _ = apply(12)
        } else {
            pendingHours += 12
            save()
        }
    }

    @discardableResult
    private func apply(_ hours: Double) -> Bool {
        guard hours > 0, var current = grow else { return false }
        guard let plant = Catalog.plant(current.plant), let pot = Catalog.pot(current.pot) else { return false }
        let required = GrowthMath.requiredHours(plant: plant.rarity, pot: pot.rarity)
        let sum = current.hours + hours
        if sum + 0.0000001 < required {
            current.hours = sum
            grow = current
            save()
            return false
        }
        let extra = sum - required
        shelf.insert(PlacedPair(id: UUID(), plant: current.plant, pot: current.pot), at: 0)
        draftPlant = current.plant
        draftPot = current.pot
        grow = nil
        if extra > 0.02 {
            pendingHours += extra
        }
        save()
        return true
    }

    private func take(name: String, rarity: Rarity, kind: String, plants: Bool) -> String {
        let owned = plants ? ownedPlants : ownedPots
        if owned.contains(name) {
            if grow != nil {
                let added = rarity.duplicateHours
                let bloomed = apply(added)
                return Copy.duplicateHours(kind: kind, hours: GrowthMath.hourText(added), bloomed: bloomed)
            }
            materialHalves += 1
            save()
            return Copy.duplicateMaterial(kind: kind)
        }
        if plants {
            ownedPlants.append(name)
        } else {
            ownedPots.append(name)
        }
        save()
        return Copy.received(name)
    }

    private func save() {
        let saved = Saved(
            ownedPots: ownedPots,
            ownedPlants: ownedPlants,
            grow: grow,
            shelf: shelf,
            materialHalves: materialHalves,
            focusRemainder: focusRemainder,
            pendingHours: pendingHours,
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
                ownedPots: [],
                ownedPlants: [],
                grow: nil,
                shelf: [],
                materialHalves: 0,
                focusRemainder: 0,
                pendingHours: 0,
                granted: []
            )
        }
        return saved
    }

    private struct Saved: Codable {
        var ownedPots: [String]
        var ownedPlants: [String]
        var grow: GrowState?
        var shelf: [PlacedPair]
        var materialHalves: Int
        var focusRemainder: Double
        var pendingHours: Double
        var granted: [UInt64]
    }

    private enum Keys {
        static let garden = "yohaku.garden"
    }

    private static let starterPot = "丸"
    private static let starterPlant = "薄い菊"
}
