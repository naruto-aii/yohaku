import SwiftUI
import UIKit

struct GrowingPairView: View {
    var plant: CatalogItem
    var pot: CatalogItem
    var progress: Double
    var side: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                plantArt
            }
            .frame(width: side, height: side * 0.78)
            .clipped()
            stageMarks
            potArt
                .frame(width: side * 0.78, height: side * 0.42)
        }
        .frame(width: side)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plant.name)ー\(pot.name)")
    }

    private var stage: Int {
        GrowthMath.stageIndex(display: progress, bloomed: progress >= 1)
    }

    private var stageMarks: some View {
        HStack(spacing: 3) {
            ForEach(0..<GrowthMath.stageCount, id: \.self) { index in
                Circle()
                    .fill(index < stage ? Palette.soft : Palette.faint.opacity(0.35))
                    .frame(width: 5, height: 5)
            }
        }
    }

    @ViewBuilder
    private var plantArt: some View {
        let flower = 22 + CGFloat(stage) * 5
        let height = flower / 0.51
        if let image = plant.bundledImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: side * 0.72, height: height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        } else {
            VStack(spacing: 6) {
                Spacer(minLength: 0)
                Capsule()
                    .fill(Palette.soft.opacity(0.55))
                    .frame(width: 3, height: max(8, height * 0.72))
                Text(plant.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.soft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var potArt: some View {
        if let image = pot.bundledImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            VStack(spacing: 4) {
                Ellipse()
                    .stroke(Palette.soft, lineWidth: 1.5)
                    .frame(width: side * 0.46, height: side * 0.16)
                Text(pot.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.soft)
            }
        }
    }
}
