import UIKit

/// Centralized haptic feedback wrappers (IOSF-007).
///
/// Previously duplicated verbatim in `ro-control-ios/ROControl/Utilities/ViewStyles.swift`
/// and `ro-tools-ios/ROTools/Extensions/ViewStyles.swift`. Consolidated here so call
/// sites in both apps share identical UIKit haptic semantics.
public enum JMVGHaptics {
    public static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    public static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
