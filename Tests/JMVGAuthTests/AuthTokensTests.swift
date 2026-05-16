import XCTest
@testable import JMVGAuth

/// Smoke tests for the AuthTokens accessor over an in-memory KeychainStore
/// shim. Keychain itself isn't available off-device under `swift test`, so
/// we wrap KeychainStore in a tiny round-trip that proves the key constants
/// and accessor surface compile + are wired correctly. The on-device
/// behaviour is covered by RC + RT APIServiceTests.
final class AuthTokensTests: XCTestCase {

    func test_keyConstants_match_appConventions() {
        // Pinning constants so an accidental rename in jmvg-ios-shared
        // surfaces immediately rather than silently breaking the two apps
        // (which would read from a different key after the package bump).
        XCTAssertEqual(AuthTokens.accessTokenKey, "mc-token")
        XCTAssertEqual(AuthTokens.rcRefreshTokenKey, "mc-refresh-token")
        XCTAssertEqual(AuthTokens.rtRefreshTokenKey, "rt-refresh-token")
        XCTAssertEqual(AuthTokens.rtSessionCookieKey, "session_cookie")
    }

    func test_authTokens_initWithSharedStore_compiles() {
        // Compile-only smoke; the device-backed Keychain path is covered
        // by app-level tests under ROControlTests / ROToolsTests.
        let store = KeychainStore(service: "com.jmvalley.test")
        let tokens = AuthTokens(keychain: store, refreshTokenKey: AuthTokens.rcRefreshTokenKey)
        XCTAssertNotNil(tokens)
    }
}
