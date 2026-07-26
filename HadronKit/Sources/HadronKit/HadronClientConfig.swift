import Foundation

/// Per-app configuration for talking to the Hadron platform. Each client app
/// (iOS, macOS) constructs one with its own redirect scheme, client name, and
/// Keychain service; the endpoints and OAuth contract are shared.
///
/// Endpoints and the OAuth contract are documented in the platform specs
/// (`cor:api:010:01` for GraphQL, `cor:aut:030:01` for the OAuth 2.1 flow).
public struct HadronClientConfig: Sendable {
    /// The Hadron server that hosts the GraphQL + MCP transports and OAuth AS.
    public let baseURL: URL

    /// Custom-scheme redirect. `ASWebAuthenticationSession` intercepts this
    /// internally, so no Info.plist URL-scheme registration is needed. The
    /// server's DCR validator requires scheme + non-empty authority with no
    /// fragment — use the double-slash form (`scheme://host`), never the
    /// Apple-style single-slash form.
    public let callbackScheme: String
    public let redirectURI: String

    /// Human-readable client name recorded at dynamic registration.
    public let clientName: String

    /// Keychain service string the app's `KeychainStore` is keyed on.
    public let keychainService: String

    /// The web portal — used for "Open in portal" deep links.
    public let portalBaseURL: URL

    public init(
        baseURL: URL = URL(string: "https://srv.hadronmemory.com")!,
        callbackScheme: String,
        redirectURI: String,
        clientName: String,
        keychainService: String,
        portalBaseURL: URL = URL(string: "https://hadronmemory.com")!
    ) {
        self.baseURL = baseURL
        self.callbackScheme = callbackScheme
        self.redirectURI = redirectURI
        self.clientName = clientName
        self.keychainService = keychainService
        self.portalBaseURL = portalBaseURL
    }

    /// GraphQL endpoint — the complete API surface.
    public var graphQLURL: URL { baseURL.appendingPathComponent("graphql") }

    /// RFC 8707 resource indicator. Required on `/oauth/authorize` and
    /// `/oauth/token`; it is the MCP resource the issued key is scoped to.
    public var resource: String { baseURL.appendingPathComponent("mcp").absoluteString }

    /// Only scope the AS advertises / accepts.
    public var scope: String { "mcp" }

    /// Build the shareable portal URL for a fully-qualified entity URN.
    /// e.g. `https://hadronmemory.com/app/u/hrn:node:org:memory:loc`
    public func portalURL(forURN urn: String) -> URL? {
        // Encode the URN as a single path segment — exclude "/" so a URN that
        // ever contains one doesn't split into extra segments.
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let encoded = urn.addingPercentEncoding(withAllowedCharacters: allowed) ?? urn
        return URL(string: "\(portalBaseURL.absoluteString)/app/u/\(encoded)")
    }
}
