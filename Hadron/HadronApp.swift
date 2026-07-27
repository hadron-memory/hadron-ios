import SwiftUI
import HadronKit

@main
struct HadronApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .onOpenURL { url in
                    state.handleOAuthCallback(url)
                }
        }
    }
}
