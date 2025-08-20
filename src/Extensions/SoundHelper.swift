import Foundation
import UserNotifications

@available(macOS 13.0, *)
public struct SoundHelper: Sendable {
    public static let systemSoundsDirectory = "/System/Library/Sounds"
    public static let defaultSound = "default"
    
    private static let commonSystemSounds: Set<String> = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    ]
    
    public static func isValidSound(_ soundName: String) -> Bool {
        if soundName == defaultSound {
            return true
        }
        
        if commonSystemSounds.contains(soundName) {
            return true
        }
        
        let soundPath = URL(fileURLWithPath: systemSoundsDirectory).appendingPathComponent("\(soundName).aiff")
        return FileManager.default.fileExists(atPath: soundPath.path)
    }
    
    public static func availableSystemSounds() -> [String] {
        var sounds = [defaultSound]
        
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: systemSoundsDirectory),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return sounds + Array(commonSystemSounds).sorted()
        }
        
        let systemSounds = enumerator.compactMap { url -> String? in
            guard let fileURL = url as? URL,
                  let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  fileURL.pathExtension.lowercased() == "aiff" else {
                return nil
            }
            return fileURL.deletingPathExtension().lastPathComponent
        }.sorted()
        
        sounds.append(contentsOf: systemSounds)
        return Array(Set(sounds)).sorted { lhs, rhs in
            if lhs == defaultSound { return true }
            if rhs == defaultSound { return false }
            return lhs < rhs
        }
    }
    
    public static func createUNNotificationSound(from soundName: String) -> UNNotificationSound? {
        if soundName == defaultSound {
            return .default
        }
        
        if isValidSound(soundName) {
            return UNNotificationSound(named: UNNotificationSoundName("\(soundName).aiff"))
        }
        
        return nil
    }
    
    public static func validateAndNormalizeSoundName(_ input: String?) -> Result<String?, SoundError> {
        guard let input = input?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty else {
            return .success(nil)
        }
        
        let soundName = input.hasSuffix(".aiff") ? String(input.dropLast(5)) : input
        
        if isValidSound(soundName) {
            return .success(soundName)
        }
        
        return .failure(.invalidSound(soundName))
    }
}

@available(macOS 13.0, *)
public enum SoundError: LocalizedError, Sendable {
    case invalidSound(String)
    case systemSoundsUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidSound(let sound):
            return "Invalid sound: '\(sound)'. Use 'default' or a valid system sound name."
        case .systemSoundsUnavailable:
            return "System sounds directory is not accessible."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidSound:
            let availableSounds = SoundHelper.availableSystemSounds().prefix(5).joined(separator: ", ")
            return "Available sounds include: \(availableSounds)..."
        case .systemSoundsUnavailable:
            return "Check system permissions or use 'default' sound."
        }
    }
}