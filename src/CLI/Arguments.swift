import ArgumentParser
import Foundation

extension String {
    static let defaultHelp = "Pass '-help' for usage."
}

protocol NotificationArguments {
    var message: String? { get }
    var title: String? { get }
    var subtitle: String? { get }
    var sound: String? { get }
    var group: String? { get }
    var activate: String? { get }
    var sender: String? { get }
    var appIcon: String? { get }
    var contentImage: String? { get }
    var open: String? { get }
    var execute: String? { get }
    var ignoreDnD: Bool { get }
}

extension NotificationArguments {
    func resolveMessage() -> String? {
        if let message = message {
            return message
        }
        
        if !FileHandle.standardInput.isatty {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            if !data.isEmpty {
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
}

extension FileHandle {
    var isatty: Bool {
        return unistd.isatty(fileDescriptor) != 0
    }
}