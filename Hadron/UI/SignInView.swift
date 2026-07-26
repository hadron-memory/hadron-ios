import SwiftUI
import HadronKit

/// The signed-out screen: app mark, one-line pitch, and the sign-in button.
/// The explanatory line matters for App Review optics (guideline 5.1.1 —
/// the auth wall shouldn't look arbitrary).
struct SignInView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image("HadronMark")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Hadron")
                .font(.largeTitle.bold())

            Text("Your knowledge memory, wherever you are.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            if state.authState == .signingIn {
                ProgressView("Signing in…")
                    .padding(.bottom, 8)
            } else {
                // One button per identity provider — the server's authorize
                // page routes its unauthenticated leg by login_provider, so
                // the choice must happen here, before the web sheet opens.
                VStack(spacing: 10) {
                    providerButton("Continue with GitHub", provider: .github)
                    providerButton("Continue with Google", provider: .google)
                }
            }

            Text("Sign in with your Hadron account to search your memories.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let message = state.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 32)
    }

    private func providerButton(_ title: String, provider: OAuthService.LoginProvider) -> some View {
        Button {
            state.signIn(with: provider)
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
    }
}
