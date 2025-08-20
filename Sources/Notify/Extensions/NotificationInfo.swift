import Foundation
@preconcurrency import UserNotifications

@available(macOS 13.0, *)
public struct NotificationInfo: Codable, Hashable, Sendable {
    public let identifier: String
    public let title: String?
    public let subtitle: String?
    public let body: String?
    public let categoryIdentifier: String?
    public let threadIdentifier: String?
    public let targetContentIdentifier: String?
    public let userInfo: [String: String]
    public let badge: Int?
    public let sound: String?
    public let deliveryDate: Date?
    public let isDelivered: Bool
    public let isPending: Bool
    
    public init(from notification: UNNotification, isPending: Bool = false) {
        self.identifier = notification.request.identifier
        
        let content = notification.request.content
        self.title = content.title.isEmpty ? nil : content.title
        self.subtitle = content.subtitle.isEmpty ? nil : content.subtitle
        self.body = content.body.isEmpty ? nil : content.body
        self.categoryIdentifier = content.categoryIdentifier.isEmpty ? nil : content.categoryIdentifier
        self.threadIdentifier = content.threadIdentifier.isEmpty ? nil : content.threadIdentifier
        self.targetContentIdentifier = content.targetContentIdentifier?.isEmpty == false ? content.targetContentIdentifier : nil
        
        var convertedUserInfo: [String: String] = [:]
        for (key, value) in content.userInfo {
            if let stringKey = key as? String {
                if let string = value as? String {
                    convertedUserInfo[stringKey] = string
                } else if let number = value as? NSNumber {
                    convertedUserInfo[stringKey] = number.stringValue
                } else {
                    convertedUserInfo[stringKey] = String(describing: value)
                }
            }
        }
        self.userInfo = convertedUserInfo
        
        self.badge = content.badge?.intValue
        
        if let sound = content.sound {
            if sound == .default {
                self.sound = "default"
            } else if let soundName = content.sound?.description.components(separatedBy: " ").first {
                self.sound = soundName
            } else {
                self.sound = nil
            }
        } else {
            self.sound = nil
        }
        
        self.deliveryDate = notification.date
        self.isDelivered = !isPending
        self.isPending = isPending
    }
    
    public init(from request: UNNotificationRequest) {
        self.identifier = request.identifier
        
        let content = request.content
        self.title = content.title.isEmpty ? nil : content.title
        self.subtitle = content.subtitle.isEmpty ? nil : content.subtitle
        self.body = content.body.isEmpty ? nil : content.body
        self.categoryIdentifier = content.categoryIdentifier.isEmpty ? nil : content.categoryIdentifier
        self.threadIdentifier = content.threadIdentifier.isEmpty ? nil : content.threadIdentifier
        self.targetContentIdentifier = content.targetContentIdentifier?.isEmpty == false ? content.targetContentIdentifier : nil
        
        var convertedUserInfo: [String: String] = [:]
        for (key, value) in content.userInfo {
            if let stringKey = key as? String {
                if let string = value as? String {
                    convertedUserInfo[stringKey] = string
                } else if let number = value as? NSNumber {
                    convertedUserInfo[stringKey] = number.stringValue
                } else {
                    convertedUserInfo[stringKey] = String(describing: value)
                }
            }
        }
        self.userInfo = convertedUserInfo
        
        self.badge = content.badge?.intValue
        
        if let sound = content.sound {
            if sound == .default {
                self.sound = "default"
            } else if let soundName = content.sound?.description.components(separatedBy: " ").first {
                self.sound = soundName
            } else {
                self.sound = nil
            }
        } else {
            self.sound = nil
        }
        
        self.deliveryDate = nil
        self.isDelivered = false
        self.isPending = true
    }
}

@available(macOS 13.0, *)
public extension NotificationInfo {
    var groupIdentifier: String? {
        return threadIdentifier
    }
    
    var hasAttachments: Bool {
        return userInfo.keys.contains { $0.hasPrefix("attachment") }
    }
    
    var activationType: String? {
        return userInfo["activationType"]
    }
    
    var bundleIdentifier: String? {
        return userInfo["bundleID"]
    }
    
    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}