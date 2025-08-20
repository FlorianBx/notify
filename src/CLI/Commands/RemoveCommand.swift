import ArgumentParser
import Foundation
@preconcurrency import UserNotifications

struct RemoveCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove notifications from Notification Center"
    )
    
    @Option(name: .shortAndLong, help: "Remove notifications with this group identifier")
    var group: String?
    
    @Flag(name: [.customLong("all")], help: "Remove all notifications")
    var removeAll = false
    
    func run() async throws {
        let center = UNUserNotificationCenter.current()
        
        if removeAll {
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
            print("All notifications removed")
            return
        }
        
        guard let group = group else {
            throw ValidationError("Must specify --group or --all")
        }
        
        let deliveredNotifications = await center.deliveredNotifications()
        let notificationsToRemove = deliveredNotifications
            .filter { $0.request.content.threadIdentifier == group }
            .map { $0.request.identifier }
        
        if !notificationsToRemove.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: notificationsToRemove)
        }
        
        let pendingRequests = await center.pendingNotificationRequests()
        let pendingToRemove = pendingRequests
            .filter { $0.content.threadIdentifier == group }
            .map { $0.identifier }
        
        if !pendingToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingToRemove)
        }
        
        let totalRemoved = notificationsToRemove.count + pendingToRemove.count
        print("Removed \(totalRemoved) notification(s) from group '\(group)'")
    }
}