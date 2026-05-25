import UIKit

/// Centralized haptic feedback wrappers (IOSF-007).
///
/// Previously duplicated verbatim in `ro-control-ios/ROControl/Utilities/ViewStyles.swift`
/// and `ro-tools-ios/ROTools/Extensions/ViewStyles.swift`. Consolidated here so call
/// sites in both apps share identical UIKit haptic semantics.
///
/// 2026-05-21 — pre-warm optimization (jmvg-ops/todo.md L3423 bug-finder
/// 2026-05-21): generators are held as module-level singletons and `.prepare()`
/// is called before every fire, so the Taptic Engine stays warm between
/// successive haptic calls. Apple's docs further recommend calling `.prepare()`
/// ~0.5-1s before the expected trigger (e.g. on `onTapGesture` begin) so the
/// engine is fully spun up by the time of the fire — callers can do this via
/// the new `prepareXxx()` family below.
@MainActor
public enum JMVGHaptics {
    // MARK: - Module-level generator singletons
    //
    // Holding these as static lets the Taptic Engine cache its warm state
    // between successive fires. Creating-and-throwing-away each call (the
    // pre-2026-05-21 pattern) defeated Apple's pre-warm path entirely and
    // produced a 10-30 ms latency on first fire under processor load on
    // A14/A15 devices.

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Fire (with implicit pre-warm)

    public static func light() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred()
    }

    public static func medium() {
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
    }

    public static func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }

    public static func error() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Explicit pre-warm (call ~0.5-1s before fire for best latency)
    //
    // Use these on `onTapGesture { }` open or `DragGesture.onChanged` to
    // spin up the Taptic Engine ahead of the actual fire, which removes
    // the perceptible first-fire delay on older iPhones.

    public static func prepareLight() {
        lightGenerator.prepare()
    }

    public static func prepareMedium() {
        mediumGenerator.prepare()
    }

    public static func prepareNotification() {
        notificationGenerator.prepare()
    }
}
