import SwiftUI
import HadronKit

/// Full-detail view of one node: metadata, description, and the markdown
/// content body, fetched view-locally via `HadronClient.node(ref:)`.
struct NodeDetailView: View {
    @EnvironmentObject private var state: AppState
    let node: HadronNode

    @State private var detail: HadronNodeDetail?
    @State private var loadError: String?

    var body: some View {
        List {
            metadataSection
            if let description = displayDescription {
                Section("Description") {
                    Text(description)
                }
            }
            contentSection
        }
        .navigationTitle(node.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let urn = node.nodeURN,
               let url = AppState.config.portalURL(forURN: urn) {
                ToolbarItem(placement: .topBarTrailing) {
                    Link(destination: url) {
                        Label("Open in Portal", systemImage: "safari")
                    }
                }
            }
        }
        .task { await loadDetail() }
    }

    // MARK: - Sections

    private var metadataSection: some View {
        Section {
            if let memoryName = node.memory?.name {
                LabeledContent("Memory", value: memoryName)
            }
            LabeledContent("Type", value: node.nodeType)
            LabeledContent("Loc", value: node.loc)
            if let urn = node.nodeURN {
                LabeledContent("URN") {
                    Text(urn)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
            if let tags = detail?.tags, !tags.isEmpty {
                LabeledContent("Tags", value: tags.joined(separator: ", "))
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if let loadError {
            Section {
                Label(loadError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        } else if let content = detail?.content, !content.isEmpty {
            Section("Content") {
                MarkdownText(content)
                    .textSelection(.enabled)
            }
        } else if detail == nil {
            Section {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        } else if let abstract = detail?.abstract, !abstract.isEmpty {
            // No body — fall back to the retrieval abstract (spec 032's
            // abstract-fallback semantics, applied client-side).
            Section("Abstract") {
                MarkdownText(abstract)
                    .textSelection(.enabled)
            }
        }
    }

    private var displayDescription: String? {
        let description = detail?.description ?? node.description
        guard let description, !description.isEmpty else { return nil }
        return description
    }

    // MARK: - Loading

    private func loadDetail() async {
        guard detail == nil, let client = state.client else { return }
        do {
            detail = try await client.node(ref: node.id)
            if detail == nil {
                loadError = "This node is no longer available."
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}

/// Renders markdown line-by-line with `AttributedString` (which handles
/// inline markdown only) so paragraph breaks survive; falls back to plain
/// text for lines that fail to parse.
struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(attributed(paragraph))
            }
        }
    }

    private var paragraphs: [String] {
        text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func attributed(_ paragraph: String) -> AttributedString {
        (try? AttributedString(
            markdown: paragraph,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(paragraph)
    }
}
