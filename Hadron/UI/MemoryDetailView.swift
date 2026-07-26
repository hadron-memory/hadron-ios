import SwiftUI
import HadronKit

/// One memory: its metadata plus a browse list of its nodes.
struct MemoryDetailView: View {
    @EnvironmentObject private var state: AppState
    let memory: Memory

    @State private var nodes: [HadronNode]?
    @State private var loadError: String?

    var body: some View {
        List {
            Section {
                if let description = memory.shortDescription, !description.isEmpty {
                    Text(description)
                }
                if let memoryClass = memory.memoryClass {
                    LabeledContent("Class", value: memoryClass)
                }
                LabeledContent("URN") {
                    Text(memory.urn)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }

            nodesSection
        }
        .navigationTitle(memory.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let url = AppState.config.portalURL(forURN: memory.urn) {
                ToolbarItem(placement: .topBarTrailing) {
                    Link(destination: url) {
                        Label("Open in Portal", systemImage: "safari")
                    }
                }
            }
        }
        .task { await loadNodes() }
    }

    @ViewBuilder
    private var nodesSection: some View {
        if let loadError {
            Section {
                Label(loadError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        } else if let nodes {
            if nodes.isEmpty {
                Section("Nodes") {
                    Text("No nodes yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Nodes (\(nodes.count))") {
                    ForEach(nodes) { node in
                        NavigationLink(value: node) {
                            NodeRow(node: node)
                        }
                    }
                }
            }
        } else {
            Section {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func loadNodes() async {
        guard nodes == nil, let client = state.client else { return }
        do {
            nodes = try await client.memoryNodes(memoryId: memory.id)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
