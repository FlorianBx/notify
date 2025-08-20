import Testing
@testable import Notify
import Foundation

@Suite("ImageHelper Tests")
struct ImageHelperTests {
    
    // MARK: - URL Validation Tests
    
    @Test("Validate HTTPS URL")
    func validateHTTPSURL() throws {
        let validURL = "https://example.com/image.png"
        let result = ImageHelper.validateImagePath(validURL)
        
        switch result {
        case .success(let url):
            #expect(url.scheme == "https")
            #expect(url.host == "example.com")
        case .failure:
            Issue.record("Devrait valider une URL HTTPS valide")
        }
    }
    
    @Test("Validate HTTP URL")
    func validateHTTPURL() throws {
        let validURL = "http://example.com/image.jpg"
        let result = ImageHelper.validateImagePath(validURL)
        
        switch result {
        case .success(let url):
            #expect(url.scheme == "http")
        case .failure:
            Issue.record("Devrait valider une URL HTTP valide")
        }
    }
    
    @Test("Invalid HTTPS URL")
    func invalidHTTPSURL() throws {
        let invalidURL = "https://invalid url with spaces.png"
        let result = ImageHelper.validateImagePath(invalidURL)
        
        switch result {
        case .success:
            Issue.record("Ne devrait pas valider une URL invalide")
        case .failure(let error):
            if case .invalidURL(let url) = error {
                #expect(url == invalidURL)
            } else {
                Issue.record("Devrait être une erreur invalidURL")
            }
        }
    }
    
    @Test("Validate file URL")
    func validateFileURL() throws {
        let tempFile = createTemporaryImageFile(withExtension: "png")
        let fileURL = "file://\(tempFile.path)"
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = ImageHelper.validateImagePath(fileURL)
        
        switch result {
        case .success(let url):
            #expect(url.scheme == "file")
        case .failure(let error):
            Issue.record("Devrait valider un file:// URL valide: \(error)")
        }
    }
    
    @Test("Validate local path")
    func validateLocalPath() throws {
        let tempFile = createTemporaryImageFile(withExtension: "jpg")
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = ImageHelper.validateImagePath(tempFile.path)
        
        switch result {
        case .success(let url):
            #expect(url.isFileURL)
            #expect(url.path == tempFile.path)
        case .failure(let error):
            Issue.record("Devrait valider un chemin local valide: \(error)")
        }
    }
    
    @Test("File not found")
    func fileNotFound() throws {
        let nonExistentPath = "/path/that/does/not/exist.png"
        let result = ImageHelper.validateImagePath(nonExistentPath)
        
        switch result {
        case .success:
            Issue.record("Ne devrait pas valider un fichier inexistant")
        case .failure(let error):
            if case .fileNotFound(let path) = error {
                #expect(path == nonExistentPath)
            } else {
                Issue.record("Devrait être une erreur fileNotFound")
            }
        }
    }
    
    @Test("Directory path")
    func directoryPath() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let result = ImageHelper.validateImagePath(tempDir.path)
        
        switch result {
        case .success:
            Issue.record("Ne devrait pas valider un répertoire")
        case .failure(let error):
            if case .isDirectory(let path) = error {
                #expect(path == tempDir.path)
            } else {
                Issue.record("Devrait être une erreur isDirectory")
            }
        }
    }
    
    @Test("Unsupported format")
    func unsupportedFormat() throws {
        let tempFile = createTemporaryFile(withExtension: "txt", content: "Not an image")
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = ImageHelper.validateImagePath(tempFile.path)
        
        switch result {
        case .success:
            Issue.record("Ne devrait pas valider un format non supporté")
        case .failure(let error):
            if case .unsupportedFormat(let path) = error {
                #expect(path == tempFile.path)
            } else {
                Issue.record("Devrait être une erreur unsupportedFormat")
            }
        }
    }
    
    @Test("Trim whitespace")
    func trimWhitespace() throws {
        let tempFile = createTemporaryImageFile(withExtension: "png")
        let pathWithSpaces = "   \(tempFile.path)   "
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = ImageHelper.validateImagePath(pathWithSpaces)
        
        switch result {
        case .success(let url):
            #expect(url.path == tempFile.path)
        case .failure:
            Issue.record("Devrait valider même avec des espaces")
        }
    }
    
    // MARK: - Image Format Support Tests
    
    @Test("Supported image extensions", arguments: [
        "png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "ico", "icns"
    ])
    func supportedImageExtensions(ext: String) throws {
        let tempFile = createTemporaryImageFile(withExtension: ext)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = ImageHelper.validateImagePath(tempFile.path)
        switch result {
        case .success:
            break // C'est ce qu'on attend
        case .failure(let error):
            Issue.record("L'extension '\(ext)' devrait être supportée: \(error)")
        }
    }
    
    // MARK: - Preload Image Tests
    
    @Test("Preload local image success")
    func preloadLocalImageSuccess() async throws {
        let tempFile = createTemporaryImageFile(withExtension: "png")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = await ImageHelper.preloadImage(from: tempFile.path)
        
        switch result {
        case .success(let data):
            #expect(!data.isEmpty, "Les données de l'image ne devraient pas être vides")
        case .failure(let error):
            Issue.record("Devrait charger l'image locale avec succès: \(error)")
        }
    }
    
    @Test("Preload image file not found")
    func preloadImageFileNotFound() async throws {
        let nonExistentPath = "/path/that/does/not/exist.png"
        let result = await ImageHelper.preloadImage(from: nonExistentPath)
        
        switch result {
        case .success:
            Issue.record("Ne devrait pas charger un fichier inexistant")
        case .failure(let error):
            if case .fileNotFound = error {
                break // C'est ce qu'on attend
            } else {
                Issue.record("Devrait être une erreur fileNotFound, mais: \(error)")
            }
        }
    }
    
    // MARK: - Error Description Tests
    
    @Test("Image error descriptions")
    func imageErrorDescriptions() throws {
        let errors: [ImageError] = [
            .invalidURL("test-url"),
            .fileNotFound("/test/path"),
            .isDirectory("/test/dir"),
            .unsupportedFormat("/test/file.xyz"),
            .attachmentCreationFailed("test reason"),
            .downloadFailed("test reason"),
            .loadingFailed("test reason")
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil, "ErrorDescription manquante pour: \(error)")
            #expect(error.recoverySuggestion != nil, "RecoverySuggestion manquante pour: \(error)")
            #expect(!error.errorDescription!.isEmpty)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTemporaryImageFile(withExtension ext: String) -> URL {
        // Créer un fichier temporaire avec un contenu minimal d'image PNG
        let pngData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // RGB+Alpha
            0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, // compressed data
            0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, // checksum
            0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
            0x42, 0x60, 0x82
        ])
        
        return createTemporaryFile(withExtension: ext, content: pngData)
    }
    
    private func createTemporaryFile(withExtension ext: String, content: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_image_\(UUID().uuidString).\(ext)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try! content.write(to: fileURL)
        return fileURL
    }
    
    private func createTemporaryFile(withExtension ext: String, content: String) -> URL {
        return createTemporaryFile(withExtension: ext, content: content.data(using: .utf8)!)
    }
}