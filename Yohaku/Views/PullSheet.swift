import SwiftUI

struct PullSheet: View {
    var model: AppModel
    var onClose: () -> Void
    @State private var pool: GachaPool = .pot

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.pull)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)

                HStack(spacing: 32) {
                    poolButton(.pot)
                    poolButton(.plant)
                }
                .padding(.top, 18)

                Text(Copy.odds)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 18)

                Text("\(Copy.pullThing) \(model.garden.materialLabel)")
                    .font(.system(size: 16))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 16)
                Text(Copy.materialHint)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.faint)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                Button {
                    guard model.garden.canPull else { return }
                    model.garden.pull(pool)
                } label: {
                    Text(Copy.pull)
                }
                .buttonStyle(WideDepthStyle())
                .disabled(!model.garden.canPull)
                .opacity(model.garden.canPull ? 1 : 0.45)
                .padding(.top, 18)

                if let result = model.garden.lastResult {
                    Text(result)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 16)
                }

                seed
                    .padding(.top, 28)

                Button(Copy.close, action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func poolButton(_ item: GachaPool) -> some View {
        Button {
            pool = item
        } label: {
            Text(item.title)
                .font(.system(size: 16))
                .foregroundStyle(pool == item ? Palette.ink : Palette.faint)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(pool == item ? .isSelected : [])
    }

    private var seed: some View {
        VStack(spacing: 8) {
            Text(Copy.seedTitle)
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
            Text(Copy.seedDetail)
                .font(.system(size: 13))
                .foregroundStyle(Palette.soft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if let product = model.purchases.seedProduct {
                Text(product.displayPrice)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 8)
            } else {
                Text(model.purchases.isLoading ? Copy.loadingPrice : Copy.priceUnavailable)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            if model.purchases.seedProduct == nil, !model.purchases.isLoading {
                Text(Copy.seedMissing)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard model.purchases.seedProduct != nil, !model.purchases.isBuyingSeed else { return }
                Task { await model.purchases.purchaseSeed() }
            } label: {
                Text(model.purchases.isBuyingSeed ? Copy.purchasing : Copy.addSeed)
            }
            .buttonStyle(WideDepthStyle())
            .padding(.top, 8)

            if let note = model.purchases.seedNote {
                Text(note)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
