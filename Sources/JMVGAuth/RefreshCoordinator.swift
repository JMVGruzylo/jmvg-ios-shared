import Foundation

/// Single-flight coordinator for "refresh access token then retry" flows.
///
/// The two JMVG iOS apps (ro-control-ios + ro-tools-ios) both implement
/// transparent JWT/cookie refresh on 401 with these requirements:
///
///   1. **Single-flight.** Concurrent 401s should trigger ONE
///      `POST /api/auth/refresh`, not N.
///   2. **No race window.** A caller arriving moments after a refresh
///      task's body returns should not get the cached (potentially failed)
///      result — it should kick off a fresh attempt.
///
/// `RefreshCoordinator` provides both guarantees as a single actor that
/// each app's APIService instantiates and asks to coordinate.
///
/// Per-app variation (auth model, keychain key, response shape, error
/// type) lives in the closure each app passes to `performRefresh`. This
/// type only owns the dedupe/race state.
public actor RefreshCoordinator {
    /// The currently-in-flight refresh task, if any. Cleared from inside
    /// the task body before the body returns — see `performRefresh` for
    /// the race-window argument.
    private var inFlight: Task<Bool, Never>?

    /// Consecutive refresh failure count. Resets on success.
    /// Pass-5 OPEN-DEFERRED fix: if the server-rotated refresh token fails
    /// to persist to Keychain (concurrent write, device locked), the next
    /// session reads the burned (server-invalidated) old token and will
    /// 401 forever. After `maxConsecutiveFailures` failures the coordinator
    /// surfaces `shouldForceSignOut = true` so the app can force a full
    /// sign-out rather than loop indefinitely.
    private var consecutiveFailures: Int = 0
    private let maxConsecutiveFailures: Int = 3

    /// Set by `performRefresh` after `maxConsecutiveFailures` consecutive
    /// failures. Caller should check and trigger sign-out if true.
    public private(set) var shouldForceSignOut: Bool = false

    public init() {}

    /// Run `refresh` under the single-flight invariant.
    ///
    /// If a refresh is already in flight, all callers wait on its result.
    /// Once the result resolves, `inFlight` is cleared *before* the task
    /// body returns, so a new caller arriving immediately after sees no
    /// in-flight task and starts a fresh attempt.
    ///
    /// - Parameter refresh: an `async`, non-throwing closure that performs
    ///   the actual refresh and returns whether it succeeded. The closure
    ///   is `@Sendable` because it may be invoked from inside the
    ///   coordinator's task context, off the calling actor.
    /// - Returns: the result of the in-flight refresh — `true` for
    ///   success, `false` for any failure (no token, network error,
    ///   server rejection).
    @discardableResult
    public func performRefresh(_ refresh: @Sendable @escaping () async -> Bool) async -> Bool {
        if let existing = inFlight {
            return await existing.value
        }
        // IOSB-RC-007 2026-05-25: use strong [self] not [weak self]. Actors have no
        // RunLoop hold-back so Task<> won't form a retain cycle, and [weak self] risks
        // leaving inFlight set forever if self were nil when recordResult runs.
        let task = Task<Bool, Never> { [self] in
            let result = await refresh()
            await self.recordResult(result)
            return result
        }
        inFlight = task
        return await task.value
    }

    /// Reset the force-sign-out flag after a successful explicit sign-in.
    public func resetFailureState() {
        consecutiveFailures = 0
        shouldForceSignOut = false
    }

    /// Record the outcome of a refresh attempt and update failure tracking.
    /// Clears inFlight before returning so the race-window invariant holds.
    private func recordResult(_ success: Bool) {
        inFlight = nil
        if success {
            consecutiveFailures = 0
            shouldForceSignOut = false
        } else {
            consecutiveFailures += 1
            if consecutiveFailures >= maxConsecutiveFailures {
                // Likely scenario: rotated refresh token failed to persist;
                // server has invalidated the old token family. Signal the app
                // to force sign-out so the user can re-authenticate cleanly
                // rather than looping 401s indefinitely.
                shouldForceSignOut = true
            }
        }
    }
}
