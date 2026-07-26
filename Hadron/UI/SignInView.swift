import SwiftUI

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
                Button {
                    state.signIn()
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
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
}
