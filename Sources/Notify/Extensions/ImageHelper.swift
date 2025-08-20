import Foundation
import UserNotifications
import UniformTypeIdentifiers

@available(macOS 13.0, *)
public struct ImageHelper: Sendable {
    public static func validateImagePath(_ path: String) -> Result<URL, ImageError> {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedPath.hasPrefix("http://") || trimmedPath.hasPrefix("https://") {
            guard let url = URL(string: trimmedPath) else {
                return .failure(.invalidURL(trimmedPath))
            }
            return .success(url)
        }
        
        if trimmedPath.hasPrefix("file://") {
            guard let url = URL(string: trimmedPath) else {
                return .failure(.invalidURL(trimmedPath))
            }
            return validateLocalImageURL(url)
        }
        
        let fileURL = URL(fileURLWithPath: trimmedPath)
        return validateLocalImageURL(fileURL)
    }
    
    private static func validateLocalImageURL(_ url: URL) -> Result<URL, ImageError> {
        let path = url.path
        
        guard FileManager.default.fileExists(atPath: path) else {
            return .failure(.fileNotFound(path))
        }
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return .failure(.isDirectory(path))
        }
        
        guard isImageFile(at: url) else {
            return .failure(.unsupportedFormat(path))
        }
        
        return .success(url)
    }
    
    private static func isImageFile(at url: URL) -> Bool {
        let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "ico", "icns"]
        let pathExtension = url.pathExtension.lowercased()
        
        if supportedExtensions.contains(pathExtension) {
            return true
        }
        
        if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let contentType = resourceValues.contentType {
            return contentType.conforms(to: .image)
        }
        
        return false
    }
    
    public static func createNotificationAttachment(from imagePath: String, identifier: String = "image") async -> Result<UNNotificationAttachment, ImageError> {
        switch validateImagePath(imagePath) {
        case .success(let imageURL):
            if imageURL.scheme == "http" || imageURL.scheme == "https" {
                return await downloadAndCreateAttachment(from: imageURL, identifier: identifier)
            } else {
                return createLocalAttachment(from: imageURL, identifier: identifier)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private static func createLocalAttachment(from url: URL, identifier: String) -> Result<UNNotificationAttachment, ImageError> {
        do {
            let attachment = try UNNotificationAttachment(identifier: identifier, url: url)
            return .success(attachment)
        } catch {
            return .failure(.attachmentCreationFailed(error.localizedDescription))
        }
    }
    
    private static func downloadAndCreateAttachment(from url: URL, identifier: String) async -> Result<UNNotificationAttachment, ImageError> {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                return .failure(.downloadFailed("Invalid HTTP response"))
            }
            
            guard !data.isEmpty else {
                return .failure(.downloadFailed("Empty response data"))
            }
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileExtension = url.pathExtension.isEmpty ? "png" : url.pathExtension
            let tempFileURL = tempDir.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
            
            try data.write(to: tempFileURL)
            
            let attachment = try UNNotificationAttachment(identifier: identifier, url: tempFileURL)
            return .success(attachment)
        } catch {
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
    
    public static func preloadImage(from path: String) async -> Result<Data, ImageError> {
        switch validateImagePath(path) {
        case .success(let url):
            if url.scheme == "http" || url.scheme == "https" {
                return await downloadImageData(from: url)
            } else {
                return loadLocalImageData(from: url)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private static func loadLocalImageData(from url: URL) -> Result<Data, ImageError> {
        do {
            let data = try Data(contentsOf: url)
            return .success(data)
        } catch {
            return .failure(.loadingFailed(error.localizedDescription))
        }
    }
    
    private static func downloadImageData(from url: URL) async -> Result<Data, ImageError> {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                return .failure(.downloadFailed("Invalid HTTP response"))
            }
            
            return .success(data)
        } catch {
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
}

@available(macOS 13.0, *)
public enum ImageError: LocalizedError, Sendable {
    case invalidURL(String)
    case fileNotFound(String)
    case isDirectory(String)
    case unsupportedFormat(String)
    case attachmentCreationFailed(String)
    case downloadFailed(String)
    case loadingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: '\(url)'"
        case .fileNotFound(let path):
            return "Image file not found: '\(path)'"
        case .isDirectory(let path):
            return "Path is a directory, not a file: '\(path)'"
        case .unsupportedFormat(let path):
            return "Unsupported image format: '\(path)'"
        case .attachmentCreationFailed(let reason):
            return "Failed to create notification attachment: \(reason)"
        case .downloadFailed(let reason):
            return "Failed to download image: \(reason)"
        case .loadingFailed(let reason):
            return "Failed to load image: \(reason)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Provide a valid file path or HTTP/HTTPS URL."
        case .fileNotFound:
            return "Check that the file exists and the path is correct."
        case .isDirectory:
            return "Provide a path to an image file, not a directory."
        case .unsupportedFormat:
            return "Use a supported image format: PNG, JPEG, GIF, TIFF, BMP, ICO, or ICNS."
        case .attachmentCreationFailed, .downloadFailed, .loadingFailed:
            return "Check network connectivity and file permissions."
        }
    }
}