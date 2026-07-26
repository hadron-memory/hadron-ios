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

/// Lightweight markdown renderer: block structure (headings vs paragraphs)
/// is split line-wise here, inline markdown (bold/italic/code/links) is
/// handled by `AttributedString`, with a plain-text fallback for lines that
/// fail to parse.
struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    private enum Block {
        case heading(level: Int, text: String)
        case paragraph(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let heading):
                    Text(attributed(heading))
                        .font(headingFont(level))
                        .padding(.top, 4)
                case .paragraph(let paragraph):
                    Text(attributed(paragraph))
                }
            }
        }
    }

    /// Headings become their own blocks; consecutive non-heading lines merge
    /// into a paragraph until a blank line (single newlines survive inside a
    /// paragraph — list items stay one-per-line).
    private var blocks: [Block] {
        var result: [Block] = []
        var current: [String] = []
        func flush() {
            let paragraph = current.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !paragraph.isEmpty { result.append(.paragraph(paragraph)) }
            current = []
        }
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flush()
            } else if let heading = parseHeading(trimmed) {
                flush()
                result.append(.heading(level: heading.level, text: heading.text))
            } else {
                current.append(line)
            }
        }
        flush()
        return result
    }

    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        let hashes = line.prefix(while: { $0 == "#" })
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = line.dropFirst(hashes.count)
        guard rest.first == " " else { return nil }
        return (hashes.count, rest.trimmingCharacters(in: .whitespaces))
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2.bold()
        case 2: return .title3.bold()
        default: return .headline
        }
    }

    private func attributed(_ paragraph: String) -> AttributedString {
        (try? AttributedString(
            markdown: paragraph,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(paragraph)
    }
}
