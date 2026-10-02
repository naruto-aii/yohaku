import SwiftUI

struct PlantView: View {
    var spec: PlantSpec
    var stage: Int

    var body: some View {
        Canvas { context, size in
            Self.paint(&context, spec: spec, stage: min(4, max(0, stage)), size: size)
        }
        .accessibilityHidden(true)
    }

    private static func paint(_ context: inout GraphicsContext, spec: PlantSpec, stage: Int, size: CGSize) {
        guard stage > 0 else { return }
        if spec.flower == 6 {
            dusk(&context, stage: stage, size: size)
            return
        }
        let reach = size.height * spec.scale * [0, 0.30, 0.56, 0.76, 1][stage]
        let origin = CGPoint(x: size.width * (0.50 + spec.lean * 0.35), y: size.height * 0.98)
        let stem = leaf(spec.green)
        let tips: [CGPoint]
        switch spec.habit {
        case 1:
            tips = rosette(&context, origin: origin, reach: reach, count: spec.count, color: stem)
        case 2:
            tips = upright(&context, origin: origin, reach: reach, count: spec.count, color: stem)
        case 3:
            tips = spray(&context, origin: origin, reach: reach, count: spec.count, color: stem, size: size)
        case 4:
            tips = single(&context, origin: origin, reach: reach, color: stem)
        case 5:
            tips = vine(&context, origin: origin, reach: reach, count: spec.count, color: stem, size: size)
        case 6:
            tips = tree(&context, origin: origin, reach: reach, count: spec.count, flower: spec.flower, color: stem, size: size)
        case 7:
            tips = moss(&context, origin: origin, count: spec.count, color: stem, size: size)
        case 8:
            tips = spike(&context, origin: origin, reach: reach, count: spec.count, color: stem)
        case 9:
            tips = broad(&context, origin: origin, reach: reach, count: spec.count, color: stem, size: size)
        default:
            tips = grass(&context, origin: origin, reach: reach, count: spec.count, lean: spec.lean, color: stem, size: size)
        }
        if stage == 3 {
            for tip in tips.prefix(4) {
                bud(&context, at: tip, color: petal(spec.flower))
            }
        } else if stage >= 4 {
            bloom(&context, spec: spec, tips: tips, reach: reach)
        }
    }

    private static func grass(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        lean: Double,
        color: Color,
        size: CGSize
    ) -> [CGPoint] {
        var tips: [CGPoint] = []
        let n = max(3, count)
        for index in 0..<n {
            let spread = (CGFloat(index) - CGFloat(n - 1) / 2) * size.width * 0.075
            let tip = CGPoint(x: origin.x + spread + CGFloat(lean) * 10, y: origin.y - reach * (0.78 + CGFloat(index % 3) * 0.08))
            var path = Path()
            path.move(to: CGPoint(x: origin.x + spread * 0.15, y: origin.y))
            path.addQuadCurve(to: tip, control: CGPoint(x: origin.x + spread, y: origin.y - reach * 0.4))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            tips.append(tip)
        }
        return tips
    }

    private static func rosette(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        color: Color
    ) -> [CGPoint] {
        let n = max(4, count)
        var tips: [CGPoint] = []
        let length = reach * 0.55
        for index in 0..<n {
            let angle = CGFloat(index) / CGFloat(n) * .pi + .pi
            let tip = CGPoint(x: origin.x + cos(angle) * length, y: origin.y - sin(angle) * length * 0.55)
            context.drawLayer { layer in
                layer.translateBy(x: origin.x, y: origin.y)
                layer.rotate(by: .radians(Double(angle) - .pi / 2))
                layer.fill(Path(ellipseIn: CGRect(x: -6, y: -length, width: 12, height: length)), with: .color(color))
            }
            tips.append(tip)
        }
        return tips
    }

    private static func upright(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        color: Color
    ) -> [CGPoint] {
        let tip = CGPoint(x: origin.x, y: origin.y - reach)
        var stem = Path()
        stem.move(to: origin)
        stem.addLine(to: tip)
        context.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        let leaves = max(2, count / 2)
        for index in 0..<leaves {
            let y = origin.y - reach * (0.28 + CGFloat(index) * 0.16)
            let leading = index % 2 == 0
            let x = leading ? origin.x - 18 : origin.x + 2
            context.fill(Path(ellipseIn: CGRect(x: x, y: y - 4, width: 16, height: 8)), with: .color(color))
        }
        return [tip]
    }

    private static func spray(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        color: Color,
        size: CGSize
    ) -> [CGPoint] {
        var tips: [CGPoint] = []
        let n = max(3, min(count, 6))
        for index in 0..<n {
            let spread = (CGFloat(index) - CGFloat(n - 1) / 2) * size.width * 0.11
            let tip = CGPoint(x: origin.x + spread, y: origin.y - reach * (0.7 + CGFloat(index % 2) * 0.18))
            var path = Path()
            path.move(to: origin)
            path.addQuadCurve(to: tip, control: CGPoint(x: origin.x + spread * 0.4, y: origin.y - reach * 0.45))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.35, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: tip.x - 7, y: tip.y, width: 14, height: 8)), with: .color(color.opacity(0.9)))
            tips.append(tip)
        }
        return tips
    }

    private static func single(_ context: inout GraphicsContext, origin: CGPoint, reach: CGFloat, color: Color) -> [CGPoint] {
        let tip = CGPoint(x: origin.x, y: origin.y - reach)
        var path = Path()
        path.move(to: origin)
        path.addQuadCurve(to: tip, control: CGPoint(x: origin.x + reach * 0.08, y: origin.y - reach * 0.5))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: origin.x - 16, y: origin.y - reach * 0.45, width: 14, height: 8)), with: .color(color))
        context.fill(Path(ellipseIn: CGRect(x: origin.x + 2, y: origin.y - reach * 0.62, width: 14, height: 8)), with: .color(color))
        return [tip]
    }

    private static func vine(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        color: Color,
        size: CGSize
    ) -> [CGPoint] {
        let end = CGPoint(x: origin.x + size.width * 0.28, y: origin.y - reach * 0.35)
        var path = Path()
        path.move(to: origin)
        path.addQuadCurve(to: end, control: CGPoint(x: origin.x + size.width * 0.05, y: origin.y - reach))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        var tips: [CGPoint] = []
        let n = max(3, min(count, 8))
        for index in 0..<n {
            let t = 0.25 + CGFloat(index) / CGFloat(n) * 0.7
            let tip = CGPoint(
                x: origin.x + (end.x - origin.x) * t,
                y: origin.y - reach * (0.55 - t * 0.35)
            )
            tips.append(tip)
        }
        return tips
    }

    private static func tree(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        flower: Int,
        color: Color,
        size: CGSize
    ) -> [CGPoint] {
        let top = CGPoint(x: origin.x, y: origin.y - reach)
        var trunk = Path()
        trunk.move(to: origin)
        trunk.addLine(to: CGPoint(x: origin.x, y: origin.y - reach * 0.42))
        context.stroke(trunk, with: .color(Color(red: 0.40, green: 0.34, blue: 0.28)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        if flower == 0 {
            for index in 0..<3 {
                let width = size.width * (0.26 + CGFloat(min(count, 6)) * 0.015 - CGFloat(index) * 0.07)
                let y = origin.y - reach * (0.38 + CGFloat(index) * 0.2)
                var triangle = Path()
                triangle.move(to: CGPoint(x: origin.x, y: y - reach * 0.22))
                triangle.addLine(to: CGPoint(x: origin.x - width / 2, y: y))
                triangle.addLine(to: CGPoint(x: origin.x + width / 2, y: y))
                triangle.closeSubpath()
                context.fill(triangle, with: .color(color))
            }
        } else {
            let canopyWidth = size.width * (0.34 + CGFloat(min(count, 8)) * 0.012)
            let canopy = CGRect(x: origin.x - canopyWidth / 2, y: top.y, width: canopyWidth, height: reach * 0.62)
            context.fill(Path(ellipseIn: canopy), with: .color(color))
        }
        return [top]
    }

    private static func moss(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        count: Int,
        color: Color,
        size: CGSize
    ) -> [CGPoint] {
        var tips: [CGPoint] = []
        let n = max(4, count)
        for index in 0..<n {
            let x = origin.x + (CGFloat(index) - CGFloat(n) / 2) * size.width * 0.06
            let rect = CGRect(x: x, y: origin.y - 8, width: 12, height: 8)
            context.fill(Path(ellipseIn: rect), with: .color(color))
            tips.append(CGPoint(x: x + 6, y: origin.y - 8))
        }
        return tips
    }

    private static func spike(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        color: Color
    ) -> [CGPoint] {
        var tips: [CGPoint] = []
        let n = max(1, min(count, 4))
        for index in 0..<n {
            let x = origin.x + (CGFloat(index) - CGFloat(n - 1) / 2) * 14
            let tip = CGPoint(x: x, y: origin.y - reach)
            var path = Path()
            path.move(to: CGPoint(x: x, y: origin.y))
            path.addLine(to: tip)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
            tips.append(tip)
        }
        return tips
    }

    private static func broad(
        _ context: inout GraphicsContext,
        origin: CGPoint,
        reach: CGFloat,
        count: Int,
        color: Color,
        size: CGSize
    ) -> [CGPoint] {
        var tips: [CGPoint] = []
        let n = max(3, min(count, 6))
        for index in 0..<n {
            let side: CGFloat = index % 2 == 0 ? -1 : 1
            let y = origin.y - reach * (0.15 + CGFloat(index) * 0.12)
            context.drawLayer { layer in
                layer.translateBy(x: origin.x, y: y)
                layer.rotate(by: .degrees(Double(side) * 28))
                layer.fill(Path(ellipseIn: CGRect(x: 0, y: -7, width: size.width * 0.18, height: 12)), with: .color(color))
            }
            tips.append(CGPoint(x: origin.x + side * size.width * 0.12, y: y))
        }
        return tips
    }

    private static func bud(_ context: inout GraphicsContext, at point: CGPoint, color: Color) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 6, width: 8, height: 8)), with: .color(color))
    }

    private static func bloom(_ context: inout GraphicsContext, spec: PlantSpec, tips: [CGPoint], reach: CGFloat) {
        if spec.habit == 6, spec.flower == 0 { return }
        let color = petal(spec.flower)
        if spec.flower == 0 {
            for tip in tips.prefix(5) {
                context.fill(Path(ellipseIn: CGRect(x: tip.x - 2, y: tip.y - 3, width: 3.5, height: 3.5)), with: .color(color))
            }
            return
        }
        if spec.flower == 4 {
            for tip in tips.prefix(6) {
                context.fill(Path(ellipseIn: CGRect(x: tip.x - 4, y: tip.y - 4, width: 8, height: 8)), with: .color(color))
            }
            return
        }
        let center = tips.first ?? .zero
        if spec.habit == 5 {
            for tip in tips {
                context.fill(Path(ellipseIn: CGRect(x: tip.x - 4, y: tip.y, width: 8, height: 11)), with: .color(color))
            }
            return
        }
        if spec.count >= 10, spec.flower == 1 {
            petals(&context, center: center, count: spec.count, length: min(18, reach * 0.16), width: 3.2, color: color)
            return
        }
        if spec.habit == 2, spec.flower == 1, spec.scale > 1.15 {
            petals(&context, center: center, count: 6, length: min(28, reach * 0.22), width: 6, color: color)
            return
        }
        petals(&context, center: center, count: 5, length: min(14, reach * 0.14), width: 5, color: color)
    }

    private static func petals(
        _ context: inout GraphicsContext,
        center: CGPoint,
        count: Int,
        length: CGFloat,
        width: CGFloat,
        color: Color
    ) {
        let n = max(3, count)
        for index in 0..<n {
            let angle = (Double(index) / Double(n)) * .pi * 2
            context.drawLayer { layer in
                layer.translateBy(x: center.x, y: center.y)
                layer.rotate(by: .radians(angle))
                layer.fill(
                    Path(ellipseIn: CGRect(x: -width / 2, y: -length, width: width, height: length)),
                    with: .color(color)
                )
            }
        }
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
            with: .color(Color(red: 0.72, green: 0.66, blue: 0.52))
        )
    }

    private static func dusk(_ context: inout GraphicsContext, stage: Int, size: CGSize) {
        let origin = CGPoint(x: size.width * 0.5, y: size.height * 0.96)
        let color = Color(red: 0.45, green: 0.33, blue: 0.30)
        if stage >= 4 {
            let radius = min(size.width, size.height) * 0.30
            let rect = CGRect(x: origin.x - radius, y: origin.y - radius * 1.7, width: radius * 2, height: radius * 1.5)
            context.fill(Path(ellipseIn: rect), with: .color(color))
            let inner = rect.insetBy(dx: radius * 0.32, dy: radius * 0.28)
            context.fill(Path(ellipseIn: inner), with: .color(Color(red: 0.36, green: 0.27, blue: 0.25)))
            return
        }
        let height = size.height * 0.16 * CGFloat(stage)
        var path = Path()
        path.move(to: origin)
        path.addLine(to: CGPoint(x: origin.x, y: origin.y - height))
        context.stroke(path, with: .color(leaf(0.4)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        if stage == 3 {
            bud(&context, at: CGPoint(x: origin.x, y: origin.y - height), color: color)
        }
    }

    private static func leaf(_ green: Double) -> Color {
        let deep = min(1, max(0, green))
        return Color(
            red: 0.36 + deep * 0.08,
            green: 0.40 + (1 - deep) * 0.16,
            blue: 0.31 + (1 - deep) * 0.04
        )
    }

    private static func petal(_ flower: Int) -> Color {
        switch flower {
        case 1: Color(red: 0.93, green: 0.91, blue: 0.86)
        case 2: Color(red: 0.86, green: 0.80, blue: 0.66)
        case 3: Color(red: 0.76, green: 0.62, blue: 0.58)
        case 4: Color(red: 0.63, green: 0.35, blue: 0.31)
        case 5: Color(red: 0.55, green: 0.50, blue: 0.58)
        case 6: Color(red: 0.45, green: 0.32, blue: 0.30)
        default: Color(red: 0.62, green: 0.58, blue: 0.48)
        }
    }
}
