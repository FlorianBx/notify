import ArgumentParser
import Foundation
@preconcurrency import UserNotifications

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List notifications currently in Notification Center"
    )
    
    @Option(name: .shortAndLong, help: "List notifications from this group identifier only")
    var group: String?
    
    @Flag(name: [.customLong("verbose"), .customShort("v")], help: "Show detailed notification information")
    var verbose = false
    
    func run() async throws {
        let center = UNUserNotificationCenter.current()
        
        let deliveredNotifications = await center.deliveredNotifications()
        let pendingRequests = await center.pendingNotificationRequests()
        
        let filteredDelivered = group != nil 
            ? deliveredNotifications.filter { $0.request.content.threadIdentifier == group }
            : deliveredNotifications
            
        let filteredPending = group != nil
            ? pendingRequests.filter { $0.content.threadIdentifier == group }
            : pendingRequests
        
        if filteredDelivered.isEmpty && filteredPending.isEmpty {
            if let group = group {
                print("No notifications found for group '\(group)'")
            } else {
                print("No notifications found")
            }
            return
        }
        
        if !filteredDelivered.isEmpty {
            print("Delivered notifications (\(filteredDelivered.count)):")
            for notification in filteredDelivered {
                printNotification(
                    identifier: notification.request.identifier,
                    content: notification.request.content,
                    date: notification.date,
                    isPending: false
                )
            }
        }
        
        if !filteredPending.isEmpty {
            if !filteredDelivered.isEmpty {
                print()
            }
            print("Pending notifications (\(filteredPending.count)):")
            for request in filteredPending {
                printNotification(
                    identifier: request.identifier,
                    content: request.content,
                    date: nil,
                    isPending: true
                )
            }
        }
    }
    
    private func printNotification(
        identifier: String,
        content: UNNotificationContent,
        date: Date?,
        isPending: Bool
    ) {
        if verbose {
            print("  ID: \(identifier)")
            print("    Title: \(content.title.isEmpty ? "(none)" : content.title)")
            print("    Body: \(content.body)")
            if !content.subtitle.isEmpty {
                print("    Subtitle: \(content.subtitle)")
            }
            if !content.threadIdentifier.isEmpty {
                print("    Group: \(content.threadIdentifier)")
            }
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                print("    Date: \(formatter.string(from: date))")
            }
            if isPending {
                print("    Status: Pending")
            }
            if !content.userInfo.isEmpty {
                print("    User Info: \(content.userInfo)")
            }
            print()
        } else {
            let status = isPending ? "[PENDING] " : ""
            let group = content.threadIdentifier.isEmpty ? "" : "[\(content.threadIdentifier)] "
            let title = content.title.isEmpty ? "" : "\(content.title): "
            print("  \(status)\(group)\(title)\(content.body)")
        }
    }
}