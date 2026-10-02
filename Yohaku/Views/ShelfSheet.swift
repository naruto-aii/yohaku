import SwiftUI

struct ShelfSheet: View {
    var model: AppModel
    var onClose: () -> Void
    @State private var nickname = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Copy.shelf)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)

                if let waiting = model.garden.awaiting {
                    Text(waiting.shelfTitle)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 16)
                    TextField(Copy.nickname, text: $nickname)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.insetFill))
                        .padding(.top, 12)
                    Text(Copy.nicknameHint)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.faint)
                        .padding(.top, 6)
                    Button(Copy.place) {
                        model.garden.placeNamed(nickname)
                        nickname = ""
                    }
                    .buttonStyle(WideDepthStyle())
                    .padding(.top, 10)
                }

                if let plant = model.garden.currentPlant, let pot = model.garden.currentPot {
                    GrowingPairView(plant: plant, pot: pot, progress: model.garden.displayProgress, side: 160)
                        .padding(.top, 16)
                    Text(model.garden.pairTitle ?? "")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.soft)
                    if let progress = model.garden.progressLabel {
                        Text(progress)
                            .font(.system(size: 14))
                            .monospacedDigit()
                            .foregroundStyle(Palette.ink)
                            .padding(.top, 4)
                    }
                    Text("\(model.garden.stageLabel) \(Copy.stageCount(model.garden.stageIndex))")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.faint)
                        .padding(.top, 2)
                }

                if model.garden.shelf.isEmpty && model.garden.awaiting == nil {
                    Text(Copy.shelfEmpty)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.soft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(model.garden.shelf) { placed in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(placed.shelfTitle)
                                    .font(.system(size: 16))
                                    .foregroundStyle(Palette.ink)
                                if !placed.nickname.isEmpty {
                                    Text(placed.nickname)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Palette.soft)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 24)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}
