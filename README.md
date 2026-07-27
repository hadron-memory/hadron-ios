# Hadron for iOS

Native iOS client for the [Hadron](https://hadronmemory.com) knowledge-memory
platform. v1 scope: sign in with your Hadron account and search across your
memories.

## Layout

- `Hadron/` — the app target (SwiftUI, iOS 17+).
- `HadronKit/` — shared Swift package with the Hadron client stack (OAuth 2.1
  PKCE sign-in, Keychain storage, GraphQL client). Also consumed by
  [hadron-macapp](../hadron-macapp) via a local path dependency.
- `project.yml` — [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec; the
  `.xcodeproj` is generated and gitignored.

## Building

```bash
brew install xcodegen        # once
xcodegen generate
xcodebuild -project HadronIOS.xcodeproj -scheme Hadron \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Or open `HadronIOS.xcodeproj` in Xcode and run.

## Auth

The app signs in via Hadron's OAuth 2.1 authorization server
(`srv.hadronmemory.com`): discovery → dynamic client registration (client id
cached in the Keychain) → PKCE S256 authorization in an
`ASWebAuthenticationSession` (provider choice: Apple, GitHub, or Google) →
token exchange. The issued `hdr_user_*` key is a long-lived bearer stored in
the Keychain; there is no refresh token — a 401 drops the app back to
signed-out.
