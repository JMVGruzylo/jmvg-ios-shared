import XCTest
@testable import JMVGAuth

final class RefreshCoordinatorTests: XCTestCase {

    func test_performRefresh_returnsClosureResult_onSuccess() async {
        let coordinator = RefreshCoordinator()
        let result = await coordinator.performRefresh { true }
        XCTAssertTrue(result)
    }

    func test_performRefresh_returnsClosureResult_onFailure() async {
        let coordinator = RefreshCoordinator()
        let result = await coordinator.performRefresh { false }
        XCTAssertFalse(result)
    }

    /// Two concurrent callers must share the same in-flight task — the
    /// closure body should run exactly once.
    func test_singleFlight_dedupesConcurrentCallers() async {
        let coordinator = RefreshCoordinator()
        let counter = Counter()
        async let a = coordinator.performRefresh {
            await counter.increment()
            // Hold the first call open long enough that a second caller
            // arrives before the body completes.
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            return true
        }
        // Second caller arrives while the first is still in-flight.
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        async let b = coordinator.performRefresh {
            await counter.increment()
            return true
        }
        let (resultA, resultB) = await (a, b)
        XCTAssertTrue(resultA)
        XCTAssertTrue(resultB)
        // Closure ran exactly once; the second caller waited on the first.
        let count = await counter.value
        XCTAssertEqual(count, 1, "single-flight should dedupe concurrent callers")
    }

    /// After a refresh completes, a fresh caller must trigger a new
    /// attempt — the `inFlight` slot must be cleared before the previous
    /// task's value is observed externally.
    func test_postCompletion_freshCallerStartsNewAttempt() async {
        let coordinator = RefreshCoordinator()
        let counter = Counter()
        // First call completes.
        _ = await coordinator.performRefresh {
            await counter.increment()
            return true
        }
        // Second call, after the first has fully returned, must run the
        // closure again. No cached result should be reused.
        _ = await coordinator.performRefresh {
            await counter.increment()
            return false
        }
        let count = await counter.value
        XCTAssertEqual(count, 2, "post-completion caller must start a fresh attempt")
    }
}

/// Test helper — actor-isolated counter so concurrent closures can
/// safely report invocation counts.
private actor Counter {
    private(set) var value = 0
    func increment() {
        value += 1
    }
}
