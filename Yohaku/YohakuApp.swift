import SwiftUI

@main
struct YohakuApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            TimerScreen(model: model)
                .preferredColorScheme(.light)
                .tint(Palette.ink)
        }
    }
}
