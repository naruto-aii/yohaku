import SwiftUI

struct PaySheet: View {
    @Bindable var model: AppModel
    var onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.unlock)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)

                if model.purchases.isUnlocked {
                    unlocked
                } else {
                    offer
                }

                Button(Copy.close, action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 18)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private var unlocked: some View {
        VStack(spacing: 10) {
            Text(Copy.openNow)
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
                .padding(.top, 28)
            Text(Copy.openDetail)
                .font(.system(size: 14))
                .foregroundStyle(Palette.soft)
                .multilineTextAlignment(.center)
        }
    }

    private var offer: some View {
        VStack(spacing: 0) {
            Text(Copy.once)
                .font(.system(size: 14))
                .foregroundStyle(Palette.soft)
                .padding(.top, 12)

            perk(Copy.sound, Copy.soundValue)
            perk(Copy.time, Copy.timeValue)
            perk(Copy.streak, Copy.streakValue)

            price
                .padding(.top, 28)

            if model.purchases.product == nil, !model.purchases.isLoading {
                Text(Copy.productMissing)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            Button {
                guard model.purchases.product != nil, !model.purchases.isPurchasing else { return }
                Task { await model.purchases.purchase() }
            } label: {
                Text(model.purchases.isPurchasing ? Copy.purchasing : Copy.purchase)
            }
            .buttonStyle(WideDepthStyle())
            .padding(.top, 18)

            Button {
                guard !model.purchases.isPurchasing else { return }
                Task { await model.purchases.restore() }
            } label: {
                Text(Copy.restore)
            }
            .buttonStyle(.plain)
            .font(.system(size: 14))
            .foregroundStyle(Palette.soft)
            .padding(.top, 16)

            if let note = model.purchases.statusNote {
                Text(note)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
        }
    }

    private func perk(_ label: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 12))
                .tracking(2)
                .foregroundStyle(Palette.soft)
            Text(value)
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
        }
        .padding(.top, 22)
    }

    @ViewBuilder
    private var price: some View {
        if model.purchases.isLoading, model.purchases.product == nil {
            Text(Copy.loadingPrice)
                .font(.system(size: 15))
                .foregroundStyle(Palette.soft)
        } else if let product = model.purchases.product {
            Text(product.displayPrice)
                .font(.system(size: 28, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
        } else {
            Text(Copy.priceUnavailable)
                .font(.system(size: 15))
                .foregroundStyle(Palette.soft)
                .multilineTextAlignment(.center)
        }
    }
}
