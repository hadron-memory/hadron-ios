import SwiftUI
import HadronKit

/// The signed-in root: a searchable list. Empty query shows the user's
/// memories; an active query (≥ 2 chars, debounced in AppState) shows node
/// search results.
struct HomeView: View {
    @EnvironmentObject private var state: AppState
    @State private var showSignOutConfirmation = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            Group {
                if state.isSearchActive {
                    searchResults
                } else {
                    memoriesList
                }
            }
            .navigationTitle("Hadron")
            .searchable(
                text: Binding(
                    get: { state.searchQuery },
                    set: { state.search($0) }
                ),
                prompt: "Search your memories"
            )
            .navigationDestination(for: Memory.self) { memory in
                MemoryDetailView(memory: memory)
            }
            .navigationDestination(for: HadronNode.self) { node in
                NodeDetailView(node: node)
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            .toolbar { accountMenu }
            .refreshable { await state.loadAll() }
            .overlay(alignment: .bottom) { errorBanner }
        }
    }

    // MARK: - Memories

    @ViewBuilder
    private var memoriesList: some View {
        if state.isLoading && state.memories.isEmpty {
            ProgressView("Loading…")
        } else if state.memories.isEmpty {
            // A fresh account lands here (sign-in auto-creates one) — make
            // the empty state a starting point, not a dead end.
            ContentUnavailableView {
                Label("No Memories Yet", systemImage: "brain")
            } description: {
                Text("Create your first memory on the Hadron portal — it will appear here, ready to search.")
            } actions: {
                Link(destination: AppState.config.portalBaseURL.appendingPathComponent("app")) {
                    Text("Open the Portal")
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                Section("Memories (\(state.memories.count))") {
                    ForEach(state.memories) { memory in
                        NavigationLink(value: memory) {
                            MemoryRow(
                                memory: memory,
                                isShared: state.sharedMemoryIds.contains(memory.id)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search results

    @ViewBuilder
    private var searchResults: some View {
        if state.isSearching {
            ProgressView("Searching…")
        } else if state.searchResults.isEmpty {
            ContentUnavailableView.search(text: state.searchQuery)
        } else {
            List(state.searchResults) { node in
                NavigationLink(value: node) {
                    NodeRow(node: node)
                }
            }
        }
    }

    // MARK: - Toolbar

    private var accountMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let me = state.me {
                    Section(me.displayName) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            state.refresh()
                        }
                        Link(destination: AppState.config.portalBaseURL.appendingPathComponent("app")) {
                            Label("Open Portal", systemImage: "safari")
                        }
                        // Account management (incl. the App Store-required
                        // deletion affordance) lives in the portal.
                        Link(destination: AppState.config.portalBaseURL.appendingPathComponent("app/account")) {
                            Label("Manage Account", systemImage: "person.text.rectangle")
                        }
                    }
                }
                Button("About", systemImage: "info.circle") {
                    showAbout = true
                }
                Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    showSignOutConfirmation = true
                }
            } label: {
                avatarLabel
            }
            .confirmationDialog(
                "Sign out of Hadron?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) { state.signOut() }
            }
        }
    }

    /// Provider avatar when the account has one, SF Symbol placeholder
    /// otherwise (and while the image loads).
    @ViewBuilder
    private var avatarLabel: some View {
        if let avatarUrl = state.me?.avatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.circle")
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle")
        }
    }

    // MARK: - Errors

    @ViewBuilder
    private var errorBanner: some View {
        if let message = state.errorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.red, in: Capsule())
                .padding(.bottom, 12)
                .onTapGesture { state.errorMessage = nil }
        }
    }
}
