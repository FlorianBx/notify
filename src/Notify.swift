import ArgumentParser
import Foundation
import AppKit
@preconcurrency import UserNotifications

@available(macOS 13.0, *)
@main
struct Notify: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notify",
        abstract: "Send User Notifications on macOS from the command line",
        version: "0.2",
        subcommands: [SendCommand.self, RemoveCommand.self, ListCommand.self],
        defaultSubcommand: SendCommand.self,
        helpNames: [.short, .long, .customLong("help")]
    )
    
    static func main() async {
        BundleHelper.setupBundle()
        
        // Clean up old context files
        LaunchContextDetector.cleanupOldContexts()
        
        // Detect launch context
        let launchContext = LaunchContextDetector.detectLaunchContext()
        
        switch launchContext {
        case .commandLine:
            // Normal CLI mode - process arguments
            _ = NSApplication.shared
            await Notify.main(nil)
            
        case .notificationClick(let url):
            // App was launched by notification click - handle URL and exit
            await handleNotificationClick(url: url)
        }
    }
    
    private static func handleNotificationClick(url: String) async {
        print("🔔 Opening URL from notification: \(url)")
        
        guard let urlObj = URL(string: url) else {
            print("❌ Invalid URL: \(url)")
            return
        }
        
        _ = await MainActor.run {
            NSWorkspace.shared.open(urlObj)
        }
        
        // Give a brief moment for the URL to open, then exit
        try? await Task.sleep(for: .milliseconds(500))
        print("✅ URL opened, exiting...")
        _stdlib.exit(0)
    }
}