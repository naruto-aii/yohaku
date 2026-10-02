import SwiftUI
import UIKit

struct TimerScreen: View {
    @Bindable var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var sheet: Sheet?
    @State private var showingTimer = false

    private enum Sheet: String, Identifiable {
        case shelf
        case pull
        case odds
        case packs
        case settings
        case pay

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Palette.surface.ignoresSafeArea()
            if model.garden.tutorial != .done {
                tutorial
            } else if showingTimer {
                timerFace
            } else {
                prepare
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.session.phase)
        .sheet(item: $sheet) { item in
            sheetView(item)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(Palette.surface)
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

    private var tutorial: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Text(Copy.appName)
                .font(.system(size: 14))
                .tracking(6)
                .foregroundStyle(Palette.soft)
            Text(Copy.tutorialLead)
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.top, 28)
                .padding(.horizontal, 36)
            Text("\(Copy.drops) \(model.garden.dropText)")
                .font(.system(size: 22, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .padding(.top, 28)
            if model.garden.tutorial == .plant {
                Button(Copy.tutorialPlant) { model.garden.pullTutorial() }
                    .buttonStyle(WideDepthStyle())
                    .padding(.top, 28)
            } else {
                Button(Copy.tutorialPot) { model.garden.pullTutorial() }
                    .buttonStyle(WideDepthStyle())
                    .padding(.top, 28)
            }
            if let line = model.garden.lastLines.first {
                Text(line)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 18)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var prepare: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.appName)
                    .font(.system(size: 14))
                    .tracking(6)
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 28)
                if model.garden.grow == nil, model.garden.lastLines.count == 1 {
                    Text(model.garden.lastLines[0])
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 12)
                }

                sectionTitle(Copy.chooseNoise)
                noiseRow
                    .padding(.top, 12)

                sectionTitle(Copy.choosePlant)
                    .padding(.top, 22)
                if model.garden.grow == nil && model.garden.awaiting == nil {
                    choiceList(model.garden.ownedNames(.plant), kind: .plant, selected: model.garden.draftPlant) {
                        model.garden.choosePlant($0)
                    }
                } else if let title = model.garden.pairTitle {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 8)
                }

                sectionTitle(Copy.choosePot)
                    .padding(.top, 18)
                if model.garden.grow == nil && model.garden.awaiting == nil {
                    choiceList(model.garden.ownedNames(.pot), kind: .pot, selected: model.garden.draftPot) {
                        model.garden.choosePot($0)
                    }
                }

                if model.garden.awaiting != nil {
                    Button(Copy.shelf) { sheet = .shelf }
                        .buttonStyle(WideDepthStyle())
                        .padding(.top, 22)
                } else {
                    Button(model.garden.grow == nil ? Copy.begin : Copy.continueGrow) {
                        if model.garden.grow == nil {
                            guard model.garden.begin() else { return }
                        }
                        startChosenNoise()
                        model.session.play()
                        showingTimer = true
                    }
                    .buttonStyle(WideDepthStyle())
                    .disabled(model.garden.grow == nil && !model.garden.canBegin)
                    .opacity(model.garden.grow == nil && !model.garden.canBegin ? 0.45 : 1)
                    .padding(.top, 22)
                }

                HStack(spacing: 22) {
                    quietLink(Copy.oddsTitle) { sheet = .odds }
                    quietLink(Copy.pull) { sheet = .pull }
                    quietLink(Copy.shelf) { sheet = .shelf }
                }
                .padding(.top, 22)
                HStack(spacing: 22) {
                    quietLink(Copy.packs) { sheet = .packs }
                    quietLink(Copy.settings) { sheet = .settings }
                }
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }

    private var timerFace: some View {
        VStack(spacing: 0) {
            HStack {
                Button(Copy.back) {
                    if model.session.isRunning {
                        model.session.pause()
                        model.noise.stop()
                    }
                    showingTimer = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Palette.soft)
                Spacer()
            }
            .padding(.top, 8)

            if let plant = model.garden.currentPlant, let pot = model.garden.currentPot {
                GrowingPairView(
                    plant: plant,
                    pot: pot,
                    progress: model.garden.displayProgress,
                    side: 168
                )
                .padding(.top, 8)
                Text(model.garden.pairTitle ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
                Text("\(model.garden.stageLabel) \(Copy.stageCount(model.garden.stageIndex))")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.faint)
                    .padding(.top, 2)
            } else if model.garden.awaiting != nil {
                naming
            } else {
                Text(Copy.shelfEmpty)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.soft)
                    .padding(.top, 24)
            }

            Spacer(minLength: 8)
            Text(model.session.phase.title)
                .font(.system(size: 14))
                .tracking(3)
                .foregroundStyle(Palette.soft)
            Text(model.session.clockText)
                .font(.system(size: 92, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .padding(.top, 8)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityLabel(model.session.accessibilityTime)
            playButton
                .padding(.top, 16)
            Spacer(minLength: 8)
            Text("\(Copy.drops) \(model.garden.dropText)")
                .font(.system(size: 18, weight: .light))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
    }

    private var naming: some View {
        NamingBlock(model: model)
            .padding(.top, 18)
    }

    private var playButton: some View {
        Button {
            if model.session.isRunning {
                model.session.pause()
                model.noise.stop()
            } else {
                startChosenNoise()
                model.session.play()
            }
        } label: {
            Image(systemName: model.session.isRunning ? "pause" : "play")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.ink)
                .contentTransition(.symbolEffect(.replace))
                .offset(x: model.session.isRunning ? 0 : 2)
        }
        .buttonStyle(CircleDepthStyle(diameter: 96))
        .accessibilityLabel(model.session.isRunning ? Copy.pause : Copy.start)
    }

    private var noiseRow: some View {
        HStack(spacing: 8) {
            ForEach(NoiseKind.allCases) { kind in
                VStack(spacing: 8) {
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
                    .buttonStyle(CircleDepthStyle(diameter: 54, selected: model.noise.playing == kind))
                    .accessibilityLabel(kind.title)
                    Text(kind.title)
                        .font(.system(size: 11))
                        .foregroundStyle(model.noise.playing == kind ? Palette.ink : Palette.soft)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12))
            .tracking(2)
            .foregroundStyle(Palette.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
    }

    private func choiceList(_ names: [String], kind: CatalogKind, selected: String, choose: @escaping (String) -> Void) -> some View {
        VStack(spacing: 8) {
            if names.isEmpty {
                Text(Copy.nothingFree)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.soft)
            }
            ForEach(names, id: \.self) { name in
                let free = model.garden.freeCount(name, kind: kind)
                Button {
                    choose(name)
                } label: {
                    HStack {
                        Text(name)
                        Spacer()
                        Text("\(free)")
                            .monospacedDigit()
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(free > 0 ? Palette.ink : Palette.faint)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(name == selected && free > 0 ? Palette.insetFill : Color.clear)
                )
                .disabled(free == 0)
            }
        }
        .padding(.top, 6)
    }

    private func startChosenNoise() {
        if model.noise.playing == nil {
            model.noise.start(.white)
        }
    }

    @ViewBuilder
    private func sheetView(_ item: Sheet) -> some View {
        switch item {
        case .shelf:
            ShelfSheet(model: model, onClose: { sheet = nil })
        case .pull:
            PullSheet(model: model, onClose: { sheet = nil }, onOdds: { sheet = .odds }, onPacks: { sheet = .packs })
        case .odds:
            OddsSheet(onClose: { sheet = nil })
        case .packs:
            PackSheet(model: model, onClose: { sheet = nil })
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
                .tracking(1)
                .foregroundStyle(Palette.soft)
        }
        .buttonStyle(.plain)
    }
}

private struct NamingBlock: View {
    var model: AppModel
    @State private var text = ""

    var body: some View {
        VStack(spacing: 10) {
            Text(model.garden.awaiting?.shelfTitle ?? "")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Palette.ink)
            TextField(Copy.nickname, text: $text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.insetFill))
            Text(Copy.nicknameHint)
                .font(.system(size: 12))
                .foregroundStyle(Palette.faint)
            Button(Copy.place) {
                model.garden.placeNamed(text)
                text = ""
            }
            .buttonStyle(WideDepthStyle())
        }
    }
}
