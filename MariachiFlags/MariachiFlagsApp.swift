import SwiftUI

@main
struct MariachiFlagsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            GameView(viewModel: viewModel)
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        viewModel.handleForeground()
                    case .inactive, .background:
                        viewModel.handleBackground()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
