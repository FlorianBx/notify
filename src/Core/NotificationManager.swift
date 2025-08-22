import Foundation
@preconcurrency import UserNotifications
import AppKit


public struct NotificationOptions {
    public let sound: String?
    public let appIcon: String?
    public let contentImage: String?
    public let openURL: String?
    public let executeCommand: String?
    public let activateApp: String?
    public let ignoreDnD: Bool
    
    public init(
        sound: String? = nil,
        appIcon: String? = nil,
        contentImage: String? = nil,
        openURL: String? = nil,
        executeCommand: String? = nil,
        activateApp: String? = nil,
        ignoreDnD: Bool = false
    ) {
        self.sound = sound
        self.appIcon = appIcon
        self.contentImage = contentImage
        self.openURL = openURL
        self.executeCommand = executeCommand
        self.activateApp = activateApp
        self.ignoreDnD = ignoreDnD
    }
}

public enum NotificationError: Error {
    case authorizationDenied
    case invalidSound
    case invalidImage
    case invalidURL
    case systemError(Error)
}

@MainActor
public final class NotificationManager: NSObject {
    public static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private var actionHandlers: [String: () -> Void] = [:]
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    public func requestAuthorization() async -> Result<Bool, NotificationError> {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return .success(granted)
        } catch {
            return .failure(.systemError(error))
        }
    }
    
    public func sendNotification(
        title: String,
        subtitle: String? = nil,
        message: String? = nil,
        sound: String? = nil,
        groupID: String? = nil,
        options: NotificationOptions? = nil
    ) async -> Result<String, NotificationError> {
        let authResult = await checkAuthorization()
        switch authResult {
        case .success(false):
            return .failure(.authorizationDenied)
        case .failure(let error):
            return .failure(error)
        case .success(true):
            break
        }
        
        let identifier = UUID().uuidString
        let content = UNMutableNotificationContent()
        
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        if let message = message {
            content.body = message
        }
        
        if let groupID = groupID {
            content.threadIdentifier = groupID
        }
        
        if let options = options {
            if let soundName = options.sound ?? sound {
                content.sound = createSound(soundName)
            }
            
            if let appIconPath = options.appIcon {
                if let iconAttachment = await createImageAttachment(path: appIconPath, identifier: "app-icon") {
                    content.attachments.append(iconAttachment)
                }
            }
            
            if let contentImagePath = options.contentImage {
                if let imageAttachment = await createImageAttachment(path: contentImagePath, identifier: "content-image") {
                    content.attachments.append(imageAttachment)
                }
            }
            
            var actions: [UNNotificationAction] = []
            
            if let url = options.openURL {
                let action = UNNotificationAction(
                    identifier: "open-url-\(identifier)",
                    title: "Open",
                    options: [.foreground]
                )
                actions.append(action)
                actionHandlers["open-url-\(identifier)"] = { [weak self] in
                    self?.openURL(url)
                }
            }
            
            if let command = options.executeCommand {
                let action = UNNotificationAction(
                    identifier: "execute-\(identifier)",
                    title: "Execute",
                    options: []
                )
                actions.append(action)
                actionHandlers["execute-\(identifier)"] = { [weak self] in
                    self?.executeCommand(command)
                }
            }
            
            if let appID = options.activateApp {
                let action = UNNotificationAction(
                    identifier: "activate-\(identifier)",
                    title: "Activate",
                    options: [.foreground]
                )
                actions.append(action)
                actionHandlers["activate-\(identifier)"] = { [weak self] in
                    self?.activateApp(appID)
                }
            }
            
            if !actions.isEmpty {
                let category = UNNotificationCategory(
                    identifier: "terminal-notifier-\(identifier)",
                    actions: actions,
                    intentIdentifiers: [],
                    options: []
                )
                center.setNotificationCategories([category])
                content.categoryIdentifier = category.identifier
            }
            
            if options.ignoreDnD {
                content.interruptionLevel = .critical
            }
        }
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
            return .success(identifier)
        } catch {
            return .failure(.systemError(error))
        }
    }
    
    public func removeNotifications(groupID: String?) async {
        if let groupID = groupID {
            let delivered = await center.deliveredNotifications()
            let identifiers = delivered
                .filter { $0.request.content.threadIdentifier == groupID }
                .map { $0.request.identifier }
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        } else {
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
        }
    }
    
    public func listNotifications() async -> [NotificationInfo] {
        let delivered = await center.deliveredNotifications()
        return delivered.map { notification in
            NotificationInfo(from: notification, isPending: false)
        }
    }
    
    private func checkAuthorization() async -> Result<Bool, NotificationError> {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            return .success(true)
        case .denied:
            return .failure(.authorizationDenied)
        case .notDetermined:
            return await requestAuthorization()
        @unknown default:
            return .failure(.authorizationDenied)
        }
    }
    
    private func createSound(_ soundName: String) -> UNNotificationSound {
        switch soundName.lowercased() {
        case "default":
            return .default
        case "none", "silent":
            return .defaultCritical
        default:
            return UNNotificationSound(named: UNNotificationSoundName(soundName))
        }
    }
    
    private func createImageAttachment(path: String, identifier: String) async -> UNNotificationAttachment? {
        let url: URL
        
        if path.hasPrefix("http") {
            guard let remoteURL = URL(string: path) else { return nil }
            do {
                let (data, _) = try await URLSession.shared.data(from: remoteURL)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(identifier)-\(UUID().uuidString)")
                    .appendingPathExtension(remoteURL.pathExtension)
                try data.write(to: tempURL)
                url = tempURL
            } catch {
                return nil
            }
        } else {
            url = URL(fileURLWithPath: path)
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        do {
            return try UNNotificationAttachment(identifier: identifier, url: url)
        } catch {
            return nil
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func executeCommand(_ command: String) {
        Task.detached {
            let process = Process()
            process.launchPath = "/bin/sh"
            process.arguments = ["-c", command]
            process.launch()
        }
    }
    
    private func activateApp(_ bundleID: String) {
        if #available(macOS 11.0, *) {
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
            if let appURL = url {
                let configuration = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                    if let error = error {
                        print("Failed to launch app: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            var launchIdentifier: NSNumber? = nil
            _ = NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, 
                                                  options: [], 
                                                  additionalEventParamDescriptor: nil as NSAppleEventDescriptor?,
                                                  launchIdentifier: &launchIdentifier)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            actionHandlers[response.actionIdentifier]?()
            actionHandlers.removeValue(forKey: response.actionIdentifier)
        }
        completionHandler()
    }
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}