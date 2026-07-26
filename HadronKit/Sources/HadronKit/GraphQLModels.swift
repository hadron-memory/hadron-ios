import Foundation

/// A Hadron memory as returned by `memories` (the uniform #473 read surface).
public struct Memory: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let urn: String
    public let name: String
    public let shortDescription: String?
    /// Memory class: system | app | knowledge | personal | group | private.
    public let memoryClass: String?

    private enum CodingKeys: String, CodingKey {
        case id, urn, name, shortDescription
        case memoryClass = "class"
    }
}

/// A graph node as returned by `findNodes` hits.
public struct HadronNode: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let loc: String
    public let name: String
    public let description: String?
    public let nodeType: String
    /// Fully-qualified node URN, composed server-side from the node's memory
    /// URN + loc (#481) and carried by every Node-returning surface. We consume
    /// it as-is rather than re-deriving it so the app stays agnostic to the URN
    /// grammar (the server owns composition; cf. hadron-server#691).
    public let nodeURN: String?
    public let memory: NodeMemory?

    public struct NodeMemory: Decodable, Hashable, Sendable {
        public let urn: String
        public let name: String
    }

    private enum CodingKeys: String, CodingKey {
        case id, loc, name, description, nodeType, memory
        case nodeURN = "urn"
    }
}

/// Full node detail as returned by `node(ref:)` — everything `HadronNode`
/// carries plus the long-form fields the detail screen renders.
public struct HadronNodeDetail: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let loc: String
    public let name: String
    public let description: String?
    /// Retrieval-surface summary (spec 032); may be stale relative to content.
    public let abstract: String?
    /// Markdown body. Nil/empty for structural nodes.
    public let content: String?
    public let nodeType: String
    public let tags: [String]?
    public let updatedAt: String?
    public let nodeURN: String?
    public let memory: HadronNode.NodeMemory?

    private enum CodingKeys: String, CodingKey {
        case id, loc, name, description, abstract, content, nodeType, tags, updatedAt, memory
        case nodeURN = "urn"
    }
}

/// The authenticated user (`me`).
public struct MeUser: Decodable, Sendable {
    public let id: String
    public let name: String?
    public let email: String?
    public let handle: String?
    /// Provider-sourced profile image (GitHub/Google both populate it).
    public let avatarUrl: String?

    public var displayName: String {
        // Handle last: auto-provisioned accounts get an opaque hex handle,
        // which reads like a bug when it leads the account menu.
        name ?? email ?? handle ?? "Signed in"
    }
}

// MARK: - GraphQL envelope

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
    /// Apollo-style error metadata; `code` carries machine-readable kinds
    /// like BAD_USER_INPUT (used to retry sanitized searches).
    let extensions: Extensions?

    struct Extensions: Decodable {
        let code: String?
    }
}
