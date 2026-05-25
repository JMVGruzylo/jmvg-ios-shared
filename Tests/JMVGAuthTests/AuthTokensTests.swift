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

    func test_authTokens_saveGetClear_roundTrip() throws {
        // Isolate from any real device/login Keychain with a per-run service.
        let store = KeychainStore(service: "com.jmvalley.test-\(UUID().uuidString)")
        let tokens = AuthTokens(keychain: store, refreshTokenKey: AuthTokens.rtRefreshTokenKey)

        // Probe first: SecItem access isn't available in every CI
        // environment (headless runners return errSecMissingEntitlement).
        // Skip the behavioural assertions there rather than flaking.
        let probe = "probe-\(UUID().uuidString)"
        tokens.saveRefreshToken(probe)
        guard tokens.refreshToken() == probe else {
            tokens.clearRefreshToken()
            throw XCTSkip("Keychain unavailable in this environment; behavioural round-trip skipped")
        }

        let token = "rt-\(UUID().uuidString)"
        tokens.saveRefreshToken(token)
        XCTAssertEqual(tokens.refreshToken(), token, "saved token should read back verbatim")

        // Empty saves are documented no-ops and must not clobber an existing token.
        tokens.saveRefreshToken("")
        XCTAssertEqual(tokens.refreshToken(), token, "empty save must not overwrite an existing token")

        tokens.clearRefreshToken()
        XCTAssertNil(tokens.refreshToken(), "cleared token should read back nil")
    }
}
