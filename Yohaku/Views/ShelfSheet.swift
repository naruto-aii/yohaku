import SwiftUI

struct ShelfSheet: View {
    var model: AppModel
    var onClose: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.shelf)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)

                if let plant = model.garden.currentPlant, let pot = model.garden.currentPot {
                    growing(plant: plant, pot: pot)
                } else {
                    idle
                }

                if model.garden.shelf.isEmpty {
                    Text(Copy.shelfEmpty)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.soft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(model.garden.shelf) { placed in
                            placedPair(placed)
                        }
                    }
                    .padding(.top, 28)
                }

                Button(Copy.close, action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 22)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func growing(plant: PlantSpec, pot: PotSpec) -> some View {
        VStack(spacing: 8) {
            Text(plant.name)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 18)
            Text(plant.rarity.label)
                .font(.system(size: 11))
                .foregroundStyle(Palette.faint)
            HStack(spacing: 8) {
                Text(pot.name)
                Text(pot.rarity.label)
            }
            .font(.system(size: 12))
            .foregroundStyle(Palette.soft)

            PotPlantView(pot: pot, plant: plant, stage: model.garden.stage, side: 210)
                .padding(.top, 6)

            if let progress = model.garden.progressLabel {
                Text(progress)
                    .font(.system(size: 16))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
            }
            Text(model.garden.stageLabel)
                .font(.system(size: 12))
                .tracking(2)
                .foregroundStyle(Palette.soft)

            if model.garden.canRetarget {
                pickers
            }
        }
    }

    private var idle: some View {
        VStack(spacing: 8) {
            Text(Copy.notGrowing)
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
                .padding(.top, 22)
            if model.garden.pendingHours > 0 {
                Text(Copy.pendingHours(GrowthMath.hourText(model.garden.pendingHours)))
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
            }
            pickers
            Button {
                model.garden.begin()
            } label: {
                Text(Copy.grow)
            }
            .buttonStyle(WideDepthStyle())
            .padding(.top, 16)
        }
    }

    private var pickers: some View {
        VStack(alignment: .leading, spacing: 14) {
            choiceRow(Copy.plantWord, specs: model.garden.ownedPlantSpecs.map { ($0.name, $0.rarity.label) }, selected: model.garden.selectedPlantName) { name in
                model.garden.choosePlant(name)
            }
            choiceRow(Copy.potWord, specs: model.garden.ownedPotSpecs.map { ($0.name, $0.rarity.label) }, selected: model.garden.selectedPotName) { name in
                model.garden.choosePot(name)
            }
        }
        .padding(.top, 16)
    }

    private func choiceRow(_ title: String, specs: [(String, String)], selected: String, onPick: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11))
                .tracking(2)
                .foregroundStyle(Palette.faint)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(specs, id: \.0) { item in
                        Button {
                            onPick(item.0)
                        } label: {
                            VStack(spacing: 2) {
                                Text(item.0)
                                    .font(.system(size: 14))
                                    .foregroundStyle(item.0 == selected ? Palette.ink : Palette.faint)
                                Text(item.1)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Palette.faint)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func placedPair(_ placed: PlacedPair) -> some View {
        if let pot = Catalog.pot(placed.pot), let plant = Catalog.plant(placed.plant) {
            VStack(spacing: 4) {
                PotPlantView(pot: pot, plant: plant, stage: 4, side: 112)
                Text(plant.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(pot.name)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.soft)
                    .lineLimit(1)
            }
        }
    }
}
