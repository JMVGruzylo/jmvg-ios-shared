import Foundation

/// Canonical Keychain key names + tiny accessors for refresh-token
/// persistence shared by both JMVG iOS apps (IOSB-003).
///
/// Each app instantiates `AuthTokens` with its own Keychain key for
/// the refresh token (`mc-refresh-token` for RC, `rt-refresh-token`
/// for RT) — the key constants live here so a refactor cannot drift
/// the two apps apart on what string they're looking up.
public struct AuthTokens {
    /// Canonical Keychain key for the access / session token.
    public static let accessTokenKey = "mc-token"

    /// Canonical Keychain key for ro-control-ios's refresh token.
    public static let rcRefreshTokenKey = "mc-refresh-token"

    /// Canonical Keychain key for ro-tools-ios's refresh token.
    public static let rtRefreshTokenKey = "rt-refresh-token"

    /// Canonical Keychain key for ro-tools-ios's session cookie.
    public static let rtSessionCookieKey = "session_cookie"

    private let keychain: KeychainStore
    private let refreshTokenKey: String

    /// Build an `AuthTokens` accessor over a shared `KeychainStore`.
    /// - Parameters:
    ///   - keychain: the app's `KeychainStore` (one per app, scoped
    ///     by `kSecAttrService` to that bundle id).
    ///   - refreshTokenKey: which key to use for refresh-token reads/
    ///     writes — pass `rcRefreshTokenKey` from ro-control-ios and
    ///     `rtRefreshTokenKey` from ro-tools-ios.
    public init(keychain: KeychainStore, refreshTokenKey: String) {
        self.keychain = keychain
        self.refreshTokenKey = refreshTokenKey
    }

    /// Persist the refresh token. Refresh tokens use the stricter
    /// `whenUnlocked` accessibility — they should never be read from
    /// a background task.
    public func saveRefreshToken(_ token: String) {
        guard !token.isEmpty else { return }
        keychain.save(refreshTokenKey, value: token, accessibility: .whenUnlocked)
    }

    /// Read the refresh token, if any. Returns nil for empty strings
    /// so callers don't have to double-guard.
    public func refreshToken() -> String? {
        guard let value = keychain.get(refreshTokenKey), !value.isEmpty else { return nil }
        return value
    }

    /// Remove the refresh token from Keychain. Called on sign-out and
    /// whenever the server explicitly invalidates the session.
    public func clearRefreshToken() {
        keychain.delete(refreshTokenKey)
    }
}
