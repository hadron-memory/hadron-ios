import SwiftUI
import HadronKit

/// One memory in the home list: name, optional description, class badge.
struct MemoryRow: View {
    let memory: Memory
    var isShared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(memory.name)
                    .font(.body)
                    .lineLimit(1)
                if let memoryClass = memory.memoryClass {
                    badge(memoryClass, style: AnyShapeStyle(.tint))
                }
                if isShared {
                    badge("shared", style: AnyShapeStyle(.secondary))
                }
            }
            if let description = memory.shortDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func badge(_ text: String, style: AnyShapeStyle) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(style.opacity(0.15), in: Capsule())
            .foregroundStyle(style)
    }
}
