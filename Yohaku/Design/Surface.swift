import SwiftUI

enum Palette {
    static let surface = Color(red: 230.0 / 255.0, green: 225.0 / 255.0, blue: 216.0 / 255.0)
    static let ink = Color(red: 60.0 / 255.0, green: 56.0 / 255.0, blue: 50.0 / 255.0)
    static let soft = Color(red: 92.0 / 255.0, green: 86.0 / 255.0, blue: 78.0 / 255.0)
    static let faint = Color(red: 111.0 / 255.0, green: 103.0 / 255.0, blue: 94.0 / 255.0)
    static let shadowDark = Color(red: 168.0 / 255.0, green: 158.0 / 255.0, blue: 144.0 / 255.0).opacity(0.45)
    static let shadowLight = Color(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 248.0 / 255.0).opacity(0.85)
    static let insetFill = Color(red: 222.0 / 255.0, green: 216.0 / 255.0, blue: 207.0 / 255.0)
}

struct DepthCircle: View {
    var inset: Bool

    var body: some View {
        Group {
            if inset {
                Circle()
                    .fill(Palette.insetFill)
                    .overlay { InsetShade(shape: Circle()) }
            } else {
                ZStack {
                    Circle()
                        .fill(Palette.surface)
                        .shadow(color: Palette.shadowDark, radius: 8, x: 7, y: 7)
                    Circle()
                        .fill(Palette.surface)
                        .shadow(color: Palette.shadowLight, radius: 7, x: -5, y: -5)
                    Circle()
                        .fill(Palette.surface)
                }
            }
        }
    }
}

struct DepthRounded: View {
    var cornerRadius: CGFloat
    var inset: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Group {
            if inset {
                shape
                    .fill(Palette.insetFill)
                    .overlay { InsetShade(shape: shape) }
            } else {
                ZStack {
                    shape
                        .fill(Palette.surface)
                        .shadow(color: Palette.shadowDark, radius: 8, x: 7, y: 7)
                    shape
                        .fill(Palette.surface)
                        .shadow(color: Palette.shadowLight, radius: 7, x: -5, y: -5)
                    shape
                        .fill(Palette.surface)
                }
            }
        }
    }
}

private struct InsetShade<S: Shape>: View {
    var shape: S

    var body: some View {
        shape
            .stroke(Color(red: 150.0 / 255.0, green: 140.0 / 255.0, blue: 126.0 / 255.0).opacity(0.45), lineWidth: 6)
            .blur(radius: 3)
            .offset(x: 2, y: 2)
            .mask(shape)
            .overlay {
                shape
                    .stroke(Color(red: 255.0 / 255.0, green: 252.0 / 255.0, blue: 248.0 / 255.0).opacity(0.7), lineWidth: 6)
                    .blur(radius: 3)
                    .offset(x: -2, y: -2)
                    .mask(shape)
            }
    }
}

struct CircleDepthStyle: ButtonStyle {
    var diameter: CGFloat
    var selected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: diameter, height: diameter)
            .background {
                DepthCircle(inset: selected || configuration.isPressed)
            }
            .contentShape(Circle())
    }
}

struct WideDepthStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                DepthRounded(cornerRadius: 28, inset: configuration.isPressed)
            }
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct LockMark: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                Path { path in
                    path.addArc(
                        center: CGPoint(x: width * 0.5, y: width * 0.46),
                        radius: width * 0.24,
                        startAngle: .degrees(200),
                        endAngle: .degrees(-20),
                        clockwise: false
                    )
                }
                .stroke(Palette.faint, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

                RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                    .fill(Palette.faint)
                    .frame(width: width * 0.72, height: width * 0.52)
                    .offset(y: width * 0.22)
            }
        }
        .frame(width: 14, height: 16)
        .accessibilityHidden(true)
    }
}
