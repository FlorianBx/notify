import Foundation
@preconcurrency import UserNotifications

@available(macOS 13.0, *)
public extension UNNotification {
    var groupIdentifier: String? {
        return request.content.threadIdentifier.isEmpty ? nil : request.content.threadIdentifier
    }
    
    var customUserInfo: [String: Any] {
        var filtered: [String: Any] = [:]
        for (key, value) in request.content.userInfo {
            if let stringKey = key as? String, stringKey != "aps" {
                filtered[stringKey] = value
            }
        }
        return filtered
    }
    
    var activationType: String? {
        return request.content.userInfo["activationType"] as? String
    }
    
    var bundleIdentifier: String? {
        return request.content.userInfo["bundleID"] as? String
    }
    
    var executeCommand: String? {
        return request.content.userInfo["execute"] as? String
    }
    
    var openURL: String? {
        return request.content.userInfo["open"] as? String
    }
    
    var hasCustomActions: Bool {
        return !request.content.categoryIdentifier.isEmpty
    }
    
    var deliveredAt: Date {
        return date
    }
    
    func toNotificationInfo() -> NotificationInfo {
        return NotificationInfo(from: self, isPending: false)
    }
}

@available(macOS 13.0, *)
public extension UNNotificationRequest {
    var groupIdentifier: String? {
        return content.threadIdentifier.isEmpty ? nil : content.threadIdentifier
    }
    
    var customUserInfo: [String: Any] {
        var filtered: [String: Any] = [:]
        for (key, value) in content.userInfo {
            if let stringKey = key as? String, stringKey != "aps" {
                filtered[stringKey] = value
            }
        }
        return filtered
    }
    
    var activationType: String? {
        return content.userInfo["activationType"] as? String
    }
    
    var bundleIdentifier: String? {
        return content.userInfo["bundleID"] as? String
    }
    
    var executeCommand: String? {
        return content.userInfo["execute"] as? String
    }
    
    var openURL: String? {
        return content.userInfo["open"] as? String
    }
    
    var hasCustomActions: Bool {
        return !content.categoryIdentifier.isEmpty
    }
    
    var isScheduled: Bool {
        return trigger != nil
    }
    
    var triggerType: String {
        switch trigger {
        case is UNTimeIntervalNotificationTrigger:
            return "timeInterval"
        case is UNCalendarNotificationTrigger:
            return "calendar"
        case nil:
            return "immediate"
        default:
            return "unknown"
        }
    }
    
    func toNotificationInfo() -> NotificationInfo {
        return NotificationInfo(from: self)
    }
}

@available(macOS 13.0, *)
public extension UNMutableNotificationContent {
    func setGroupIdentifier(_ identifier: String?) {
        threadIdentifier = identifier ?? ""
    }
    
    func setActivationType(_ type: String) {
        if userInfo.isEmpty {
            userInfo = [:]
        }
        userInfo["activationType"] = type
    }
    
    func setBundleIdentifier(_ bundleID: String) {
        if userInfo.isEmpty {
            userInfo = [:]
        }
        userInfo["bundleID"] = bundleID
    }
    
    func setExecuteCommand(_ command: String) {
        if userInfo.isEmpty {
            userInfo = [:]
        }
        userInfo["execute"] = command
    }
    
    func setOpenURL(_ urlString: String) {
        if userInfo.isEmpty {
            userInfo = [:]
        }
        userInfo["open"] = urlString
    }
    
    func setCustomUserInfo(_ info: [String: Any]) {
        var combinedUserInfo = userInfo
        for (key, value) in info {
            combinedUserInfo[key] = value
        }
        userInfo = combinedUserInfo
    }
    
    func addCustomUserInfo(key: String, value: Any) {
        if userInfo.isEmpty {
            userInfo = [:]
        }
        userInfo[key] = value
    }
}

@available(macOS 13.0, *)
public extension UNNotificationCategory {
    static func createNotifyCategory(identifier: String, actions: [UNNotificationAction]) -> UNNotificationCategory {
        return UNNotificationCategory(
            identifier: identifier,
            actions: actions,
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }
}

@available(macOS 13.0, *)
public extension UNNotificationAction {
    static func createNotifyAction(identifier: String, title: String, isDestructive: Bool = false) -> UNNotificationAction {
        let options: UNNotificationActionOptions = isDestructive ? [.destructive] : []
        return UNNotificationAction(identifier: identifier, title: title, options: options)
    }
    
    static func createTextInputAction(identifier: String, title: String, buttonTitle: String = "Send", placeholder: String = "") -> UNTextInputNotificationAction {
        return UNTextInputNotificationAction(
            identifier: identifier,
            title: title,
            options: [],
            textInputButtonTitle: buttonTitle,
            textInputPlaceholder: placeholder
        )
    }
}

@available(macOS 13.0, *)
public extension Array where Element == UNNotification {
    func groupedByIdentifier() -> [String: [UNNotification]] {
        return Dictionary(grouping: self) { notification in
            notification.groupIdentifier ?? "default"
        }
    }
    
    func sortedByDate() -> [UNNotification] {
        return sorted { $0.deliveredAt > $1.deliveredAt }
    }
    
    func filtered(by bundleIdentifier: String) -> [UNNotification] {
        return filter { $0.bundleIdentifier == bundleIdentifier }
    }
}

@available(macOS 13.0, *)
public extension Array where Element == UNNotificationRequest {
    func groupedByIdentifier() -> [String: [UNNotificationRequest]] {
        return Dictionary(grouping: self) { request in
            request.groupIdentifier ?? "default"
        }
    }
    
    func sortedByIdentifier() -> [UNNotificationRequest] {
        return sorted { $0.identifier < $1.identifier }
    }
    
    func filtered(by bundleIdentifier: String) -> [UNNotificationRequest] {
        return filter { $0.bundleIdentifier == bundleIdentifier }
    }
}