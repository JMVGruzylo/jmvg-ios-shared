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
        let task = Task<Bool, Never> { [weak self] in
            let result = await refresh()
            await self?.clearInFlightIfCurrent()
            return result
        }
        inFlight = task
        return await task.value
    }

    /// Called from inside the refresh task body, on the coordinator's
    /// actor, before the body returns. Clearing here (rather than after
    /// `await task.value` returns to the calling site) closes the race
    /// window where a concurrent caller could observe the just-completed
    /// task and reuse its cached result.
    private func clearInFlightIfCurrent() {
        inFlight = nil
    }
}
