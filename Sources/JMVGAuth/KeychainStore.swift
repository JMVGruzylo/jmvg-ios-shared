import Foundation
import Security

/// Parameterized Keychain wrapper — single implementation shared by
/// ro-control-ios and ro-tools-ios. Each app instantiates one
/// `KeychainStore` with its own `service` (a.k.a. kSecAttrService)
/// so the two apps' secrets never collide:
///
///   - RC: `KeychainStore(service: "com.jmvalley.rocontrol")`
///   - RT: `KeychainStore(service: "com.jmvalley.rotools")`
///
/// This consolidates the two near-identical 100-line `KeychainService`
/// files (IOSB-012) into one source of truth so audit hardening lands
/// in both apps simultaneously.
///
/// Hardening invariants enforced here:
///   - UTF-8 encode failure logs via the injected `logger`; never
///     force-unwraps.
///   - `SecItemAdd` OSStatus is checked + reported through `logger`;
///     silent failures used to mean "user gets signed out next launch,
///     no breadcrumb".
///   - Session cookies / access tokens use
///     `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so background
///     fetch can refresh them after a reboot.
///   - Other secrets (refresh tokens etc.) use the stricter
///     `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — never read from
///     background tasks.
///   - `kSecAttrSynchronizable = false` is explicit on every save so
///     a refactor cannot silently start syncing auth state through
///     iCloud Keychain.
public final class KeychainStore {
    /// Logger hook so the package can stay test-friendly + free of any
    /// app-specific logging dependency. Each app passes its own logger
    /// (RCLog / AppLog) shimmed through this closure.
    public typealias Logger = @Sendable (_ event: String, _ detail: String) -> Void

    public enum Accessibility {
        /// Background-fetch friendly: readable after the first unlock
        /// since the last reboot. Use for session cookies / access
        /// tokens needed by background sync loops.
        case afterFirstUnlock
        /// Strictest: readable only while the device is unlocked. Use
        /// for refresh tokens, OAuth refresh tokens, and any secret
        /// the app should not read from a background task.
        case whenUnlocked

        fileprivate var cfValue: CFString {
            switch self {
            case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenUnlocked: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        }
    }

    private let service: String
    private let logger: Logger

    public init(service: String, logger: @escaping Logger = { _, _ in }) {
        self.service = service
        self.logger = logger
    }

    // MARK: - Generic key/value

    /// Save a string value under `key`. Default accessibility is the
    /// stricter `whenUnlocked` — opt up to `afterFirstUnlock` only
    /// when background-fetch needs the value.
    public func save(_ key: String, value: String, accessibility: Accessibility = .whenUnlocked) {
        guard let data = value.data(using: .utf8) else {
            logger("keychain_value_utf8_encode_failed", "key=\(key) len=\(value.count)")
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = accessibility.cfValue
        addQuery[kSecAttrSynchronizable as String] = false
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            logger("keychain_save_failed", "key=\(key) OSStatus=\(status)")
        }
    }

    public func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
