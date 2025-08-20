import Foundation
import AppKit

@available(macOS 13.0, *)
public struct AppActivator: Sendable {
    public static func activate(bundleIdentifier: String) async -> Result<Bool, AppActivationError> {
        let trimmedBundleID = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedBundleID.isEmpty else {
            return .failure(.invalidBundleIdentifier("Bundle identifier cannot be empty"))
        }
        
        guard isValidBundleIdentifier(trimmedBundleID) else {
            return .failure(.invalidBundleIdentifier("Invalid bundle identifier format: \(trimmedBundleID)"))
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let workspace = NSWorkspace.shared
                
                guard let appURL = workspace.urlForApplication(withBundleIdentifier: trimmedBundleID) else {
                    continuation.resume(returning: .failure(.applicationNotFound(trimmedBundleID)))
                    return
                }
                
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = true
                configuration.hides = false
                
                workspace.openApplication(at: appURL, configuration: configuration) { runningApp, error in
                    if let error = error {
                        continuation.resume(returning: .failure(.activationFailed(error.localizedDescription)))
                    } else if let runningApp = runningApp {
                        continuation.resume(returning: .success(runningApp.isActive))
                    } else {
                        continuation.resume(returning: .failure(.unknown("Application launched but status unknown")))
                    }
                }
            }
        }
    }
    
    public static func activateByName(_ applicationName: String) async -> Result<Bool, AppActivationError> {
        let trimmedName = applicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .failure(.invalidApplicationName("Application name cannot be empty"))
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let workspace = NSWorkspace.shared
                let runningApps = workspace.runningApplications
                
                if let existingApp = runningApps.first(where: { 
                    $0.localizedName?.lowercased() == trimmedName.lowercased() ||
                    $0.bundleIdentifier?.lowercased().contains(trimmedName.lowercased()) == true
                }) {
                    let success = existingApp.activate()
                    continuation.resume(returning: .success(success))
                    return
                }
                
                let possiblePaths = [
                    "/Applications/\(trimmedName).app",
                    "/Applications/Utilities/\(trimmedName).app",
                    "/System/Applications/\(trimmedName).app",
                    "/System/Applications/Utilities/\(trimmedName).app"
                ]
                
                for path in possiblePaths {
                    let appURL = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: appURL.path) {
                        let configuration = NSWorkspace.OpenConfiguration()
                        configuration.activates = true
                        configuration.hides = false
                        
                        workspace.openApplication(at: appURL, configuration: configuration) { runningApp, error in
                            if let error = error {
                                continuation.resume(returning: .failure(.activationFailed(error.localizedDescription)))
                            } else if let runningApp = runningApp {
                                continuation.resume(returning: .success(runningApp.isActive))
                            } else {
                                continuation.resume(returning: .success(true))
                            }
                        }
                        return
                    }
                }
                
                continuation.resume(returning: .failure(.applicationNotFound(trimmedName)))
            }
        }
    }
    
    public static func isApplicationRunning(_ bundleIdentifier: String) -> Bool {
        let workspace = NSWorkspace.shared
        return workspace.runningApplications.contains { app in
            app.bundleIdentifier == bundleIdentifier
        }
    }
    
    public static func getRunningApplications() -> [RunningAppInfo] {
        return NSWorkspace.shared.runningApplications.compactMap { app in
            guard let bundleIdentifier = app.bundleIdentifier,
                  let localizedName = app.localizedName else {
                return nil
            }
            
            return RunningAppInfo(
                bundleIdentifier: bundleIdentifier,
                localizedName: localizedName,
                isActive: app.isActive,
                processIdentifier: app.processIdentifier
            )
        }
    }
    
    public static func findBundleIdentifier(for applicationName: String) -> String? {
        let trimmedName = applicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let workspace = NSWorkspace.shared
        
        if let runningApp = workspace.runningApplications.first(where: { 
            $0.localizedName?.lowercased() == trimmedName.lowercased()
        }) {
            return runningApp.bundleIdentifier
        }
        
        let possiblePaths = [
            "/Applications/\(trimmedName).app",
            "/Applications/Utilities/\(trimmedName).app",
            "/System/Applications/\(trimmedName).app",
            "/System/Applications/Utilities/\(trimmedName).app"
        ]
        
        for path in possiblePaths {
            let appURL = URL(fileURLWithPath: path)
            if let bundle = Bundle(url: appURL) {
                return bundle.bundleIdentifier
            }
        }
        
        return nil
    }
    
    private static func isValidBundleIdentifier(_ bundleIdentifier: String) -> Bool {
        let pattern = "^[a-zA-Z0-9-]+\\.[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: bundleIdentifier.utf16.count)
        return regex?.firstMatch(in: bundleIdentifier, options: [], range: range) != nil
    }
}

@available(macOS 13.0, *)
public struct RunningAppInfo: Codable, Hashable, Sendable {
    public let bundleIdentifier: String
    public let localizedName: String
    public let isActive: Bool
    public let processIdentifier: pid_t
    
    public init(bundleIdentifier: String, localizedName: String, isActive: Bool, processIdentifier: pid_t) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.isActive = isActive
        self.processIdentifier = processIdentifier
    }
}

@available(macOS 13.0, *)
public enum AppActivationError: LocalizedError, Sendable {
    case invalidBundleIdentifier(String)
    case invalidApplicationName(String)
    case applicationNotFound(String)
    case activationFailed(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidBundleIdentifier(let reason):
            return "Invalid bundle identifier: \(reason)"
        case .invalidApplicationName(let reason):
            return "Invalid application name: \(reason)"
        case .applicationNotFound(let identifier):
            return "Application not found: '\(identifier)'"
        case .activationFailed(let reason):
            return "Failed to activate application: \(reason)"
        case .unknown(let reason):
            return "Unknown error: \(reason)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidBundleIdentifier:
            return "Provide a valid bundle identifier (e.g., 'com.apple.Safari')."
        case .invalidApplicationName:
            return "Provide a valid application name."
        case .applicationNotFound:
            return "Check that the application is installed and accessible."
        case .activationFailed:
            return "Check application permissions and system resources."
        case .unknown:
            return "Try again or restart the application."
        }
    }
}