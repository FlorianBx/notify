import Foundation
import AppKit

@available(macOS 13.0, *)
public struct LaunchContextDetector {
    
    /// Enum representing different launch contexts
    public enum LaunchContext {
        case commandLine
        case notificationClick(url: String)
    }
    
    private static let contextDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("notify-contexts", isDirectory: true)
    
    /// Detects how the app was launched
    public static func detectLaunchContext() -> LaunchContext {
        // First check if we have any pending notification contexts
        if let pendingURL = checkForPendingNotificationContext() {
            return .notificationClick(url: pendingURL)
        }
        
        // If no context file, assume command line launch
        return .commandLine
    }
    
    /// Stores a notification context for later retrieval when app is relaunched by notification click
    public static func storeNotificationContext(identifier: String, url: String) {
        ensureContextDirectoryExists()
        
        let contextFile = contextDirectory.appendingPathComponent("\(identifier).json")
        let context = NotificationContext(url: url, timestamp: Date())
        
        do {
            let data = try JSONEncoder().encode(context)
            try data.write(to: contextFile)
        } catch {
            print("Failed to store notification context: \(error)")
        }
    }
    
    /// Checks for and consumes a pending notification context
    private static func checkForPendingNotificationContext() -> String? {
        guard FileManager.default.fileExists(atPath: contextDirectory.path) else {
            return nil
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: contextDirectory, 
                                                                   includingPropertiesForKeys: [.creationDateKey], 
                                                                   options: .skipsHiddenFiles)
            
            // Find the most recent context file (within reasonable time window)
            let recentFiles = files.filter { file in
                guard file.pathExtension == "json" else { return false }
                
                if let resourceValues = try? file.resourceValues(forKeys: [.creationDateKey]),
                   let creationDate = resourceValues.creationDate {
                    // Only consider contexts created within the last 30 seconds
                    return Date().timeIntervalSince(creationDate) < 30.0
                }
                return false
            }.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            guard let mostRecentFile = recentFiles.first else {
                return nil
            }
            
            // Read and consume the context
            let data = try Data(contentsOf: mostRecentFile)
            let context = try JSONDecoder().decode(NotificationContext.self, from: data)
            
            // Clean up the context file
            try FileManager.default.removeItem(at: mostRecentFile)
            
            return context.url
            
        } catch {
            print("Failed to check notification contexts: \(error)")
            return nil
        }
    }
    
    /// Cleans up old context files
    public static func cleanupOldContexts() {
        guard FileManager.default.fileExists(atPath: contextDirectory.path) else {
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: contextDirectory, 
                                                                   includingPropertiesForKeys: [.creationDateKey], 
                                                                   options: .skipsHiddenFiles)
            
            for file in files {
                if let resourceValues = try? file.resourceValues(forKeys: [.creationDateKey]),
                   let creationDate = resourceValues.creationDate,
                   Date().timeIntervalSince(creationDate) > 300.0 { // Older than 5 minutes
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup old contexts: \(error)")
        }
    }
    
    private static func ensureContextDirectoryExists() {
        if !FileManager.default.fileExists(atPath: contextDirectory.path) {
            try? FileManager.default.createDirectory(at: contextDirectory, 
                                                    withIntermediateDirectories: true, 
                                                    attributes: nil)
        }
    }
}

/// Internal structure for storing notification context
private struct NotificationContext: Codable {
    let url: String
    let timestamp: Date
}