import UserNotifications

/// Enable only after Apple grants the filtering entitlement and it is restored in target.yml.
nonisolated enum NotificationFilteringPolicy {
    static let canFilterNotifications = false

    static func passiveContent(from original: UNNotificationContent) -> UNNotificationContent {
        let content = (original.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
        if content.title.isEmpty && content.body.isEmpty {
            content.title = "2ecure"
        }
        content.interruptionLevel = .passive
        content.sound = nil
        return content
    }

    static func suppressedContent(from original: UNNotificationContent) -> UNNotificationContent {
        canFilterNotifications ? UNNotificationContent() : passiveContent(from: original)
    }
}
