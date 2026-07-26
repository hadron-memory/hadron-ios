import SwiftUI
import HadronKit

/// One node search hit: name, optional description, memory · loc caption.
struct NodeRow: View {
    let node: HadronNode

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(node.name)
                .font(.body)
                .lineLimit(1)
            if let description = node.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(caption)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var caption: String {
        if let memoryName = node.memory?.name {
            return "\(memoryName) · \(node.loc)"
        }
        return node.loc
    }
}
