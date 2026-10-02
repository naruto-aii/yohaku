import SwiftUI

struct PotView: View {
    var spec: PotSpec

    var body: some View {
        Canvas { context, size in
            Self.paint(&context, spec: spec, size: size)
        }
        .accessibilityHidden(true)
    }

    private static func paint(_ context: inout GraphicsContext, spec: PotSpec, size: CGSize) {
        let span = size.width * min(0.94, max(0.34, spec.width * 0.72))
        let bodyH = size.height * min(0.86, max(0.30, spec.height * 0.68))
        let footH = spec.foot > 0.03 ? size.height * min(spec.foot, 0.36) * 0.42 : 0
        let bottom = size.height * 0.90 - footH
        let top = bottom - bodyH
        let midY = (top + bottom) / 2
        let cx = size.width / 2
        let topHalf = min(span * 0.5 * (1 - spec.neck * 0.55), size.width * 0.46)
        let botHalf = min(span * 0.36, size.width * 0.40)
        let midHalf = min(span * (0.42 + spec.belly * 0.45), size.width * 0.48)
        let path = vessel(
            cx: cx,
            top: top,
            bottom: bottom,
            midY: midY,
            topHalf: topHalf,
            midHalf: midHalf,
            botHalf: botHalf,
            corners: spec.corners
        )
        let body = clay(spec)
        context.fill(path, with: .color(body))
        if spec.glaze > 0 {
            context.fill(path, with: .color(glaze(spec.hue).opacity(min(0.55, spec.glaze * 0.5))))
        }
        if spec.facets > 0 {
            context.drawLayer { layer in
                layer.clip(to: path)
                let tone = Color(red: 0.22, green: 0.21, blue: 0.19).opacity(0.18)
                for index in 0..<spec.facets {
                    let t = (CGFloat(index) + 0.5) / CGFloat(spec.facets)
                    let x = cx - topHalf + (topHalf * 2) * t
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: top))
                    line.addLine(to: CGPoint(x: cx - botHalf + (botHalf * 2) * t, y: bottom))
                    layer.stroke(line, with: .color(tone), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                }
            }
        }
        if spec.thin {
            context.stroke(path, with: .color(Palette.soft.opacity(0.45)), style: StrokeStyle(lineWidth: 1.15))
        }
        let mouth = CGRect(x: cx - topHalf, y: top - topHalf * 0.16, width: topHalf * 2, height: max(6, topHalf * 0.28))
        context.fill(Path(ellipseIn: mouth), with: .color(body.opacity(0.92)))
        context.fill(
            Path(ellipseIn: mouth.insetBy(dx: topHalf * 0.12, dy: mouth.height * 0.18)),
            with: .color(Color(red: 0.32, green: 0.28, blue: 0.24).opacity(0.35))
        )
        if footH > 0 {
            let rect = CGRect(x: cx - botHalf * 0.72, y: bottom - 1, width: botHalf * 1.44, height: footH + 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(body))
        }
    }

    private static func vessel(
        cx: CGFloat,
        top: CGFloat,
        bottom: CGFloat,
        midY: CGFloat,
        topHalf: CGFloat,
        midHalf: CGFloat,
        botHalf: CGFloat,
        corners: Int
    ) -> Path {
        var path = Path()
        if corners == 4 {
            path.move(to: CGPoint(x: cx - topHalf, y: top))
            path.addLine(to: CGPoint(x: cx + topHalf, y: top))
            path.addLine(to: CGPoint(x: cx + botHalf, y: bottom))
            path.addLine(to: CGPoint(x: cx - botHalf, y: bottom))
        } else if corners == 6 {
            path.move(to: CGPoint(x: cx, y: top))
            path.addLine(to: CGPoint(x: cx + topHalf, y: top + (bottom - top) * 0.28))
            path.addLine(to: CGPoint(x: cx + botHalf, y: bottom - (bottom - top) * 0.08))
            path.addLine(to: CGPoint(x: cx, y: bottom))
            path.addLine(to: CGPoint(x: cx - botHalf, y: bottom - (bottom - top) * 0.08))
            path.addLine(to: CGPoint(x: cx - topHalf, y: top + (bottom - top) * 0.28))
        } else {
            path.move(to: CGPoint(x: cx - topHalf, y: top))
            path.addQuadCurve(
                to: CGPoint(x: cx - botHalf, y: bottom),
                control: CGPoint(x: cx - midHalf, y: midY)
            )
            path.addLine(to: CGPoint(x: cx + botHalf, y: bottom))
            path.addQuadCurve(
                to: CGPoint(x: cx + topHalf, y: top),
                control: CGPoint(x: cx + midHalf, y: midY)
            )
        }
        path.closeSubpath()
        return path
    }

    private static func clay(_ spec: PotSpec) -> Color {
        Color(
            red: channel(0.40 + spec.tone * 0.48 + spec.warmth * 0.18),
            green: channel(0.36 + spec.tone * 0.44 + spec.warmth * 0.04),
            blue: channel(0.30 + spec.tone * 0.40 - spec.warmth * 0.08)
        )
    }

    private static func glaze(_ hue: Int) -> Color {
        switch hue {
        case 1: Color(red: 0.55, green: 0.60, blue: 0.56)
        case 2: Color(red: 0.28, green: 0.26, blue: 0.24)
        case 3: Color(red: 0.90, green: 0.88, blue: 0.84)
        case 4: Color(red: 0.48, green: 0.36, blue: 0.30)
        case 5: Color(red: 0.58, green: 0.60, blue: 0.62)
        default: Color(red: 0.55, green: 0.56, blue: 0.50)
        }
    }

    private static func channel(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

struct PotPlantView: View {
    var pot: PotSpec
    var plant: PlantSpec
    var stage: Int
    var side: CGFloat = 220

    var body: some View {
        ZStack(alignment: .bottom) {
            PlantView(spec: plant, stage: stage)
                .frame(width: side * 0.92, height: side * 0.62)
                .padding(.bottom, side * 0.30)
            PotView(spec: pot)
                .frame(width: side * 0.78, height: side * 0.40)
        }
        .frame(width: side, height: side)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plant.name)、\(pot.name)、\(GrowthMath.stageWord(stage))")
    }
}
