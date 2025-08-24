import ArgumentParser
import Foundation
import AppKit
@preconcurrency import UserNotifications

@available(macOS 13.0, *)
struct SendCommand: AsyncParsableCommand, NotificationArguments {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification",
        shouldDisplay: false
    )
    
    @Option(name: .shortAndLong, help: "The notification message")
    var message: String?
    
    @Option(name: .shortAndLong, help: "The notification title")
    var title: String?
    
    @Option(name: [.long], help: "The notification subtitle")
    var subtitle: String?
    
    @Option(name: [.customLong("sound")], help: "The notification sound (use 'default' for system default)")
    var sound: String?
    
    @Option(name: .shortAndLong, help: "The notification group identifier")
    var group: String?
    
    @Option(name: [.customLong("activate")], help: "Bundle identifier of app to activate on click")
    var activate: String?
    
    @Option(name: [.customLong("sender")], help: "Bundle identifier of app to masquerade as")
    var sender: String?
    
    @Option(name: [.customLong("appIcon")], help: "Path or URL to app icon")
    var appIcon: String?
    
    @Option(name: [.customLong("contentImage")], help: "Path or URL to content image")
    var contentImage: String?
    
    @Option(name: .shortAndLong, help: "URL to open on notification click")
    var open: String?
    
    @Option(name: .shortAndLong, help: "Shell command to execute on notification click")
    var execute: String?
    
    @Flag(name: [.customLong("ignoreDnD")], help: "Ignore Do Not Disturb setting")
    var ignoreDnD = false
    
    @Option(name: [.customLong("remove")], help: "Remove notifications with this group identifier (compatibility)")
    var remove: String?
    
    @Flag(name: [.customLong("list")], help: "List notifications (compatibility)")
    var list = false
    
    @Flag(name: [.customLong("persist")], help: "Keep the CLI running to handle notification callbacks")
    var persist = false
    
    func run() async throws {
        if list {
            let listCommand = ListCommand()
            try await listCommand.run()
            return
        }
        
        if let removeGroup = remove {
            var removeCommand = RemoveCommand()
            removeCommand.group = removeGroup
            try await removeCommand.run()
            return
        }
        
        let center = await MainActor.run {
            UNUserNotificationCenter.current()
        }
        
        try await requestAuthorization(center: center)
        
        guard let messageText = resolveMessage() else {
            throw ValidationError("No message provided. Use -m/--message or pipe content via stdin.")
        }
        
        if let sound = sound {
            switch SoundHelper.validateAndNormalizeSoundName(sound) {
            case .success(_):
                break
            case .failure(let error):
                throw ValidationError(error.localizedDescription + " " + (error.recoverySuggestion ?? ""))
            }
        }
        
        let content = UNMutableNotificationContent()
        content.body = messageText
        
        if let title = title {
            content.title = title
        }
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        if let group = group {
            content.threadIdentifier = group
        }
        
        if let appIcon = appIcon {
            await addIcon(to: content, iconPath: appIcon)
        }
        
        if let contentImage = contentImage {
            await addContentImage(to: content, imagePath: contentImage)
        }
        
        var userInfo: [String: Any] = [:]
        
        if let activate = activate {
            userInfo["activate"] = activate
        }
        
        if let sender = sender {
            userInfo["sender"] = sender
        }
        
        if let open = open {
            userInfo["open"] = open
        }
        
        if let execute = execute {
            userInfo["execute"] = execute
        }
        
        if ignoreDnD {
            userInfo["ignoreDnD"] = true
        }
        
        content.userInfo = userInfo
        
        // Configure notification actions if needed
        if open != nil || execute != nil || activate != nil {
            var actions: [UNNotificationAction] = []
            let categoryIdentifier = "notify-\(UUID().uuidString)"
            
            if open != nil {
                let openAction = UNNotificationAction(
                    identifier: "open-url",
                    title: "Open",
                    options: [.foreground]
                )
                actions.append(openAction)
            }
            
            if execute != nil {
                let executeAction = UNNotificationAction(
                    identifier: "execute-command",
                    title: "Execute",
                    options: []
                )
                actions.append(executeAction)
            }
            
            if activate != nil {
                let activateAction = UNNotificationAction(
                    identifier: "activate-app",
                    title: "Activate",
                    options: [.foreground]
                )
                actions.append(activateAction)
            }
            
            if !actions.isEmpty {
                let category = UNNotificationCategory(
                    identifier: categoryIdentifier,
                    actions: actions,
                    intentIdentifiers: [],
                    options: []
                )
                center.setNotificationCategories([category])
                content.categoryIdentifier = categoryIdentifier
            }
        }
        
        let identifier = group ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        
        // Store context for notification click handling if URL is provided
        if let open = open {
            LaunchContextDetector.storeNotificationContext(identifier: identifier, url: open)
        }
        
        if let sound = sound {
            _ = SoundHelper.playSound(sound)
        }
        
        // Configure notification delegate to enable macOS auto-relaunch on click
        if open != nil || execute != nil || activate != nil {
            await MainActor.run {
                let app = NSApplication.shared
                let appDelegate = NotificationAppDelegate()
                let notificationDelegate = NotificationDelegate()
                
                app.delegate = appDelegate
                UNUserNotificationCenter.current().delegate = notificationDelegate
            }
            
            // Give macOS a moment to register our app as the notification handler
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        // Only start persistent event loop if explicitly requested with --persist
        if persist {
            await MainActor.run {
                let app = NSApplication.shared
                let delegate = NotificationAppDelegate()
                delegate.setShouldPersist(persist)
                app.delegate = delegate
                app.run()
            }
        }
        
        // Otherwise, we terminate and let macOS relaunch us if notification is clicked
    }
    
    private func requestAuthorization(center: UNUserNotificationCenter) async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        do {
            let granted = try await center.requestAuthorization(options: options)
            
            if !granted {
                print("⚠️ Notification authorization denied. Please enable notifications in System Settings > Notifications > notify")
                throw ValidationError("Notification authorization denied. Please enable notifications in System Settings.")
            }
        } catch {
            print("⚠️ Failed to request notification authorization: \(error.localizedDescription)")
            print("Please ensure notify has permission to send notifications in System Settings > Notifications")
            throw error
        }
    }
    
    private func addIcon(to content: UNMutableNotificationContent, iconPath: String) async {
        guard let url = createURL(from: iconPath),
              let attachment = try? UNNotificationAttachment(
                identifier: "appIcon",
                url: url,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.image"]
              ) else { return }
        
        content.attachments.append(attachment)
    }
    
    private func addContentImage(to content: UNMutableNotificationContent, imagePath: String) async {
        guard let url = createURL(from: imagePath),
              let attachment = try? UNNotificationAttachment(
                identifier: "contentImage",
                url: url,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.image"]
              ) else { return }
        
        content.attachments.append(attachment)
    }
    
    private func createURL(from path: String) -> URL? {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        } else {
            let expandedPath = NSString(string: path).expandingTildeInPath
            return URL(fileURLWithPath: expandedPath)
        }
    }
    
}