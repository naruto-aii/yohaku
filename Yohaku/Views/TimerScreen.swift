import SwiftUI
import UIKit

struct TimerScreen: View {
    @Bindable var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var sheet: Sheet?

    private enum Sheet: String, Identifiable {
        case shelf
        case pull
        case settings
        case pay

        var id: String { rawValue }

        var detent: CGFloat {
            switch self {
            case .shelf: 760
            case .pull: 700
            case .settings: 520
            case .pay: 620
            }
        }
    }

    var body: some View {
        ZStack {
            Palette.surface.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 12)
                Text(model.session.phase.title)
                    .font(.system(size: 14))
                    .tracking(3)
                    .foregroundStyle(Palette.soft)
                Text(model.session.clockText)
                    .font(.system(size: 96, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .padding(.top, 18)
                    .contentTransition(.numericText(countsDown: true))
                    .accessibilityLabel(model.session.accessibilityTime)
                streak
                    .padding(.top, 22)
                Spacer(minLength: 16)
                playButton
                Spacer(minLength: 16)
                noiseRow
                if let failure = model.noise.failure {
                    Text(failure)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.soft)
                        .padding(.top, 14)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 36) {
                    quietLink(Copy.shelf) { sheet = .shelf }
                    quietLink(Copy.pull) { sheet = .pull }
                    quietLink(Copy.settings) { sheet = .settings }
                }
                .padding(.top, 26)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .animation(.easeInOut(duration: 0.35), value: model.session.phase)
        .sheet(item: $sheet) { item in
            sheetView(item)
                .presentationDetents([.height(item.detent), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(Palette.surface)
                .presentationBackgroundInteraction(.enabled(upThrough: .large))
        }
        .task { model.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.becameActive()
            }
        }
        .onChange(of: model.session.isRunning) { _, running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
        .onChange(of: model.purchases.isUnlocked) { _, _ in
            model.applyUnlockState()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var streak: some View {
        VStack(spacing: 4) {
            Text("\(model.streak.displayCount)")
                .font(.system(size: 20))
                .monospacedDigit()
                .foregroundStyle(Palette.soft)
            Text(Copy.streak)
                .font(.system(size: 11))
                .tracking(2)
                .foregroundStyle(Palette.soft)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Copy.streak) \(model.streak.displayCount)")
    }

    private var playButton: some View {
        Button {
            model.session.toggle()
        } label: {
            Image(systemName: model.session.isRunning ? "pause" : "play")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.ink)
                .contentTransition(.symbolEffect(.replace))
                .offset(x: model.session.isRunning ? 0 : 2)
        }
        .buttonStyle(CircleDepthStyle(diameter: 104))
        .accessibilityLabel(model.session.isRunning ? Copy.pause : Copy.start)
    }

    private var noiseRow: some View {
        HStack(spacing: 8) {
            ForEach(NoiseKind.allCases) { kind in
                VStack(spacing: 10) {
                    Button {
                        if model.isLocked(kind) {
                            sheet = .pay
                        } else {
                            model.toggleNoise(kind)
                        }
                    } label: {
                        if model.isLocked(kind) {
                            LockMark()
                        } else {
                            Color.clear
                        }
                    }
                    .buttonStyle(CircleDepthStyle(diameter: 60, selected: model.noise.playing == kind))
                    .accessibilityLabel(kind.title)
                    .accessibilityValue(value(for: kind))
                    .accessibilityAddTraits(model.noise.playing == kind ? .isSelected : [])

                    Text(kind.title)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(model.noise.playing == kind ? Palette.ink : Palette.soft)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func sheetView(_ item: Sheet) -> some View {
        switch item {
        case .shelf:
            ShelfSheet(model: model, onClose: { sheet = nil })
        case .pull:
            PullSheet(model: model, onClose: { sheet = nil })
        case .settings:
            SettingsSheet(model: model, onClose: { sheet = nil }, onPay: { sheet = .pay })
        case .pay:
            PaySheet(model: model, onClose: { sheet = nil })
        }
    }

    private func quietLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .tracking(2)
                .foregroundStyle(Palette.soft)
        }
        .buttonStyle(.plain)
    }

    private func value(for kind: NoiseKind) -> String {
        if model.isLocked(kind) { return Copy.locked }
        return model.noise.playing == kind ? Copy.playing : Copy.stopped
    }
}
