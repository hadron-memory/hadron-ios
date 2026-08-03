import Foundation
import SwiftUI
import HadronKit

/// Observable app state backing the iOS UI. Owns auth lifecycle and the
/// loaded data (memories, search results). Ported from hadron-macapp's
/// AppState; deliberately per-app (the state drifts with each UI).
@MainActor
final class AppState: ObservableObject {
    enum AuthState {
        case signedOut
        case signingIn
        case signedIn
    }

    /// This app's identity against the Hadron platform. The redirect scheme
    /// and client name are distinct from the macapp's, so DCR registers (and
    /// the Keychain caches) a separate client id per app.
    static let config = HadronClientConfig(
        callbackScheme: "com.hadronmemory.ios",
        redirectURI: "com.hadronmemory.ios://oauth-callback",
        clientName: "Hadron for iOS",
        keychainService: "com.hadronmemory.ios"
    )

    @Published var authState: AuthState = .signedOut
    @Published var me: MeUser?
    @Published var memories: [Memory] = []
    /// Ids of memories the user reaches via a MemoryShare grant (badged in the list).
    @Published var sharedMemoryIds: Set<String> = []
    @Published var searchResults: [HadronNode] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let keychain = KeychainStore(service: AppState.config.keychainService)
    private lazy var oauth = OAuthService(config: AppState.config, keychain: keychain)
    private var searchTask: Task<Void, Never>?

    init() {
        if keychain.get(.accessToken) != nil {
            authState = .signedIn
            Task { await loadAll() }
        }
    }

    /// Nil when signed out. Detail views fetch through this directly.
    var client: HadronClient? {
        guard let token = keychain.get(.accessToken) else { return nil }
        return HadronClient(config: AppState.config, token: token)
    }

    // MARK: - Auth

    func signIn(with provider: OAuthService.LoginProvider) {
        guard authState != .signingIn else { return }
        authState = .signingIn
        errorMessage = nil
        Task {
            do {
                let token = try await oauth.authenticate(loginProvider: provider)
                keychain.set(token, for: .accessToken)
                authState = .signedIn
                await loadAll()
            } catch OAuthService.OAuthError.userCancelled {
                authState = .signedOut
            } catch {
                errorMessage = error.localizedDescription
                authState = .signedOut
            }
        }
    }

    /// Abort an in-flight sign-in. The OAuthService cancel resumes the
    /// authenticate() continuation with userCancelled, which signIn()'s catch
    /// already maps to a clean signed-out state — this just guarantees the
    /// user always has the escape hatch.
    func cancelSignIn() {
        oauth.cancel()
    }

    /// Forward a custom-scheme URL from `.onOpenURL` — completes the email
    /// magic-link sign-in, whose final redirect arrives from the system
    /// browser rather than the in-app auth sheet.
    func handleOAuthCallback(_ url: URL) {
        _ = oauth.handleCallback(url)
    }

    /// Deletes the access token but never the cached DCR client id — losing
    /// it would re-register on next sign-in and burn the DCR rate limit.
    func signOut() {
        keychain.delete(.accessToken)
        me = nil
        memories = []
        searchResults = []
        searchQuery = ""
        isSearching = false
        errorMessage = nil
        authState = .signedOut
    }

    // MARK: - Data loading

    func loadAll() async {
        guard let client, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let meResult = client.me()
            async let ownResult = client.myMemories()
            async let sharedResult = client.sharedMemories()
            self.me = try await meResult
            // Merge the default surface with shared-with-me grants (the
            // server keeps those behind an explicit filter); dedupe by id.
            let own = try await ownResult
            let shared = try await sharedResult
            let ownIds = Set(own.map(\.id))
            self.sharedMemoryIds = Set(shared.map(\.id)).subtracting(ownIds)
            self.memories = (own + shared.filter { !ownIds.contains($0.id) })
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            handle(error)
        }
    }

    func refresh() {
        Task { await loadAll() }
    }

    // MARK: - Search (debounced)

    func search(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let client else { return }
            do {
                let results = try await client.findNodes(search: trimmed)
                guard !Task.isCancelled else { return }
                self.searchResults = results
                self.isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                self.isSearching = false
                handle(error)
            }
        }
    }

    /// True when the current query is long enough to be an active search.
    var isSearchActive: Bool {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    // MARK: - Error handling

    private func handle(_ error: Error) {
        if case HadronError.unauthorized = error {
            // signOut() clears errorMessage, so set the message afterwards.
            signOut()
            errorMessage = HadronError.unauthorized.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
