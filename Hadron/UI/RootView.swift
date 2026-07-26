import SwiftUI

/// Switches between the signed-out and signed-in worlds.
struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        switch state.authState {
        case .signedOut, .signingIn:
            SignInView()
        case .signedIn:
            HomeView()
        }
    }
}
