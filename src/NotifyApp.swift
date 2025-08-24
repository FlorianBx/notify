import Foundation
import AppKit
import ArgumentParser
@preconcurrency import UserNotifications

@available(macOS 13.0, *)
struct NotifyApp {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        
        if args.contains("--persist") || needsEventLoop(args) {
            await MainActor.run {
                let app = NSApplication.shared
                let delegate = NotificationAppDelegate()
                
                delegate.setCommandLineArgs(args)
                delegate.setShouldPersist(args.contains("--persist"))
                
                app.delegate = delegate
                
                Task {
                    do {
                        var command = Notify.parseOrExit(args)
                        try await command.run()
                    } catch {
                        Notify.exit(withError: error)
                    }
                }
                
                app.run()
            }
        } else {
            await Notify.main(args)
        }
    }
    
    private static func needsEventLoop(_ args: [String]) -> Bool {
        let interactiveFlags = ["--open", "-o", "--execute", "-e", "--activate"]
        return interactiveFlags.contains { flag in
            args.contains { arg in
                arg.hasPrefix(flag)
            }
        }
    }
}

