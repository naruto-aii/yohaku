import SwiftUI

struct PullSheet: View {
    var model: AppModel
    var onClose: () -> Void
    var onOdds: () -> Void
    var onPacks: () -> Void
    @State private var kind: CatalogKind = .plant

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.pull)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)

                HStack(spacing: 28) {
                    kindButton(.plant)
                    kindButton(.pot)
                }
                .padding(.top, 16)

                Text("\(Copy.drops) \(model.garden.dropText)")
                    .font(.system(size: 18))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 16)

                Button(Copy.pull) {
                    model.garden.pull(kind: kind, times: 1)
                }
                .buttonStyle(WideDepthStyle())
                .disabled(!model.garden.canSingle)
                .opacity(model.garden.canSingle ? 1 : 0.45)
                .padding(.top, 16)

                Button(Copy.tenPull) {
                    model.garden.pull(kind: kind, times: 10)
                }
                .buttonStyle(WideDepthStyle())
                .disabled(!model.garden.canTen)
                .opacity(model.garden.canTen ? 1 : 0.45)
                .padding(.top, 10)

                VStack(spacing: 6) {
                    ForEach(Array(model.garden.lastLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 16)

                HStack(spacing: 24) {
                    Button(Copy.oddsTitle, action: onOdds)
                    Button(Copy.packs, action: onPacks)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Palette.soft)
                .padding(.top, 22)

                Button(Copy.close, action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func kindButton(_ item: CatalogKind) -> some View {
        Button {
            kind = item
        } label: {
            Text(item.title)
                .font(.system(size: 16))
                .foregroundStyle(kind == item ? Palette.ink : Palette.soft)
        }
        .buttonStyle(.plain)
    }
}

struct OddsSheet: View {
    var onClose: () -> Void
    @State private var kind: CatalogKind = .plant
    @State private var shown: CatalogItem?

    var body: some View {
        VStack(spacing: 0) {
            Text(Copy.oddsTitle)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 24)
            Text(Copy.oddsLead)
                .font(.system(size: 12))
                .foregroundStyle(Palette.faint)
                .padding(.top, 6)
            HStack(spacing: 28) {
                Button(Copy.plantWord) { kind = .plant }
                    .foregroundStyle(kind == .plant ? Palette.ink : Palette.soft)
                Button(Copy.potWord) { kind = .pot }
                    .foregroundStyle(kind == .pot ? Palette.ink : Palette.soft)
            }
            .buttonStyle(.plain)
            .font(.system(size: 15))
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Catalog.items(kind)) { item in
                        Button {
                            shown = item
                        } label: {
                            HStack {
                                Text(item.name)
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Text(item.rarity.label)
                                    .foregroundStyle(Palette.faint)
                                Text(item.percentText)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.soft)
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .font(.system(size: 15))
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
            }

            Button(Copy.close, action: onClose)
                .buttonStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Palette.soft)
                .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(item: $shown) { item in
            ItemPicture(item: item, onClose: { shown = nil })
        }
    }
}

struct ItemPicture: View {
    var item: CatalogItem
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(item.name)
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Palette.ink)
                .padding(.top, 28)
            Text("\(item.rarity.label)  \(item.percentText)")
                .font(.system(size: 13))
                .foregroundStyle(Palette.soft)
            if let image = item.bundledImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .padding(.top, 8)
            } else {
                Text(Copy.noPicture)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
            }
            if item.standIn {
                Text(Copy.standIn)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.faint)
            }
            Text(item.sourceNote)
                .font(.system(size: 11))
                .foregroundStyle(Palette.faint)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button(Copy.close, action: onClose)
                .buttonStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Palette.soft)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

struct PackSheet: View {
    @Bindable var model: AppModel
    var onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.packs)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)
                Text("\(model.garden.dropText)")
                    .font(.system(size: 22))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 8)
                Text(Copy.packLead)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                ForEach(DropPack.allCases) { pack in
                    Button {
                        Task { await model.purchases.purchase(pack: pack) }
                    } label: {
                        HStack {
                            Text("\(pack.drops)")
                                .monospacedDigit()
                            Spacer()
                            Text(model.purchases.priceText(for: pack))
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.ink)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Palette.insetFill))
                    .disabled(model.purchases.buyingPack != nil)
                    .padding(.top, 10)
                }

                if let note = model.purchases.packNote {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.soft)
                        .padding(.top, 14)
                }

                Button(Copy.close, action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}
