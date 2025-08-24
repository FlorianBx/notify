import Foundation
import AppKit
@preconcurrency import UserNotifications

@available(macOS 13.0, *)
@MainActor
public final class NotificationAppDelegate: NSObject, NSApplicationDelegate {
    private let notificationDelegate = NotificationDelegate()
    private var shouldPersist: Bool = false
    private var commandLineArgs: [String] = []
    
    public func setShouldPersist(_ persist: Bool) {
        self.shouldPersist = persist
    }
    
    public func setCommandLineArgs(_ args: [String]) {
        self.commandLineArgs = args
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        setupSignalHandlers()
        
        if !shouldPersist {
            Task {
                try? await Task.sleep(for: .seconds(2))
                
                if !notificationDelegate.hasReceivedInteraction {
                    NSApp.terminate(nil)
                }
            }
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return !shouldPersist
    }
    
    private func setupSignalHandlers() {
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
        
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSource.setEventHandler { [weak self] in
            self?.gracefulShutdown()
        }
        sigintSource.resume()
        
        let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigtermSource.setEventHandler { [weak self] in
            self?.gracefulShutdown()
        }
        sigtermSource.resume()
    }
    
    private func gracefulShutdown() {
        print("Shutting down gracefully...")
        NSApp.terminate(nil)
    }
}

@available(macOS 13.0, *)
@MainActor
public final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private(set) var hasReceivedInteraction = false
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        Task { @MainActor in
            hasReceivedInteraction = true
            
            switch actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                await handleDefaultAction(userInfo: userInfo)
            case UNNotificationDismissActionIdentifier:
                break
            default:
                await handleCustomAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
            }
            
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                NSApp.terminate(nil)
            }
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
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) async {
        if let urlString = userInfo["open"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else if let command = userInfo["execute"] as? String {
            await executeCommand(command)
        } else if let bundleID = userInfo["activate"] as? String {
            await activateApp(bundleID)
        }
    }
    
    private func handleCustomAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        if actionIdentifier.hasPrefix("open-url-"),
           let urlString = userInfo["open"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else if actionIdentifier.hasPrefix("execute-"),
                  let command = userInfo["execute"] as? String {
            await executeCommand(command)
        } else if actionIdentifier.hasPrefix("activate-"),
                  let bundleID = userInfo["activate"] as? String {
            await activateApp(bundleID)
        }
    }
    
    private func executeCommand(_ command: String) async {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to execute command: \(error)")
        }
    }
    
    private func activateApp(_ bundleID: String) async {
        let result = await AppActivator.activate(bundleIdentifier: bundleID)
        
        switch result {
        case .success:
            break
        case .failure(let error):
            print("Failed to activate app: \(error.localizedDescription)")
        }
    }
}