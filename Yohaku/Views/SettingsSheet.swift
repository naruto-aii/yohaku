import SwiftUI

struct SettingsSheet: View {
    @Bindable var model: AppModel
    var onClose: () -> Void
    var onPay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            Text(Copy.settings)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Palette.ink)
            HStack(alignment: .top, spacing: 28) {
                dial(
                    title: Copy.focus,
                    minutes: model.session.focusMinutes,
                    range: 1...120
                ) { delta in
                    step(delta, focus: true)
                }
                dial(
                    title: Copy.rest,
                    minutes: model.session.breakMinutes,
                    range: 1...60
                ) { delta in
                    step(delta, focus: false)
                }
            }
            .padding(.top, 36)

            if model.purchases.isUnlocked {
                Text(Copy.unlocked)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 28)
            } else {
                Text(Copy.lengthsFixed)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 20)

            if !model.purchases.isUnlocked {
                Button(Copy.unlock, action: onPay)
                    .buttonStyle(WideDepthStyle())
                    .padding(.horizontal, 36)
                Button(Copy.restore) {
                    Task { await model.purchases.restore() }
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
                        .padding(.top, 10)
                        .padding(.horizontal, 28)
                }
            }

            Button(Copy.close, action: onClose)
                .buttonStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Palette.soft)
                .padding(.top, 18)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func step(_ delta: Int, focus: Bool) {
        guard model.purchases.isUnlocked else {
            onPay()
            return
        }
        if focus {
            model.stepFocus(delta)
        } else {
            model.stepBreak(delta)
        }
    }

    private func dial(
        title: String,
        minutes: Int,
        range: ClosedRange<Int>,
        onStep: @escaping (Int) -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Text("\(minutes)")
                .font(.system(size: 48, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text(Copy.minutes)
                .font(.system(size: 13))
                .foregroundStyle(Palette.soft)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink)
                .padding(.top, 2)
            HStack(spacing: 22) {
                stepButton(systemName: "minus", enabled: minutes > range.lowerBound) {
                    onStep(-1)
                }
                stepButton(systemName: "plus", enabled: minutes < range.upperBound) {
                    onStep(1)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Palette.ink)
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(CircleDepthStyle(diameter: 44))
        .accessibilityLabel(systemName == "minus" ? "短くする" : "長くする")
    }
}
