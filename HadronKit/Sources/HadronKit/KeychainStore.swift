import Foundation
import Security

/// Minimal generic-password Keychain wrapper, keyed on the app's service
/// string (from `HadronClientConfig.keychainService`).
///
/// Stores two items: the long-lived OAuth access token and the dynamically
/// registered OAuth client id (cached so we don't re-register — and burn the
/// DCR rate limit — on every launch).
public struct KeychainStore: Sendable {
    private let service: String

    public init(service: String) {
        self.service = service
    }

    public enum Key: String, Sendable {
        case accessToken = "access-token"
        case clientId = "oauth-client-id"
    }

    public func set(_ value: String?, for key: Key) {
        guard let value, !value.isEmpty else {
            delete(key)
            return
        }
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        // The token must be readable on background refreshes but never leave
        // this device (it is a permanent bearer credential — no iCloud sync).
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert.merge(attributes) { _, new in new }
            status = SecItemAdd(insert as CFDictionary, nil)
        }
        if status != errSecSuccess {
            // Surface the failure — a silently-dropped token loops sign-in.
            NSLog("KeychainStore: failed to store \(key.rawValue) (OSStatus \(status))")
        }
    }

    public func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
