import Testing
@testable import Notify
import ArgumentParser

@Suite("SendCommand Tests")
struct SendCommandTests {
    
    // MARK: - Command Configuration Tests
    
    @Test("SendCommand configuration")
    func sendCommandConfiguration() throws {
        #expect(SendCommand.configuration.commandName == "send")
        #expect(SendCommand.configuration.abstract == "Send a notification")
        #expect(SendCommand.configuration.shouldDisplay == false)
    }
    
    // MARK: - Message Resolution Tests
    
    @Test("Resolve message from SendCommand")
    func resolveMessageFromSendCommand() throws {
        let command = createMockSendCommand(message: "Direct message")
        let resolvedMessage = command.resolveMessage()
        
        #expect(resolvedMessage == "Direct message")
    }
    
    @Test("Resolve message when nil")
    func resolveMessageWhenNil() throws {
        let command = createMockSendCommand(message: nil)
        let resolvedMessage = command.resolveMessage()
        
        // Quand message est nil et qu'il n'y a pas d'input depuis stdin,
        // la fonction devrait retourner nil
        #expect(resolvedMessage == nil)
    }
    
    // MARK: - Backward Compatibility Options Tests
    
    @Test("Backward compatibility flags")
    func backwardCompatibilityFlags() throws {
        let command = createMockSendCommand()
        
        // Tester les flags de compatibilité
        #expect(command.remove == "test-group")
        #expect(command.list == true)
    }
    
    // MARK: - Default Values Tests
    
    @Test("Default values from parsed command")
    func defaultValuesFromParsedCommand() throws {
        // Créer une commande avec le minimum d'arguments pour tester les valeurs par défaut
        let args = ["--message", "test"]
        let command = try SendCommand.parse(args)
        
        // Vérifier les valeurs par défaut pour les options non spécifiées
        #expect(command.message == "test")
        #expect(command.title == nil)
        #expect(command.subtitle == nil)
        #expect(command.sound == nil)
        #expect(command.group == nil)
        #expect(command.activate == nil)
        #expect(command.sender == nil)
        #expect(command.appIcon == nil)
        #expect(command.contentImage == nil)
        #expect(command.open == nil)
        #expect(command.execute == nil)
        #expect(command.ignoreDnD == false)
        #expect(command.remove == nil)
        #expect(command.list == false)
    }
    
    // MARK: - Argument Parsing Tests
    
    @Test("Parse basic message")
    func parseBasicMessage() throws {
        let args = ["--message", "Hello World"]
        
        let command = try SendCommand.parse(args)
        #expect(command.message == "Hello World")
        #expect(command.title == nil)
        #expect(command.subtitle == nil)
    }
    
    @Test("Parse full notification")
    func parseFullNotification() throws {
        let args = [
            "--message", "Test message",
            "--title", "Test title", 
            "--subtitle", "Test subtitle",
            "--sound", "Glass",
            "--group", "test-group",
            "--activate", "com.apple.Safari",
            "--open", "https://example.com",
            "--ignoreDnD"
        ]
        
        let command = try SendCommand.parse(args)
        #expect(command.message == "Test message")
        #expect(command.title == "Test title")
        #expect(command.subtitle == "Test subtitle")
        #expect(command.sound == "Glass")
        #expect(command.group == "test-group")
        #expect(command.activate == "com.apple.Safari")
        #expect(command.open == "https://example.com")
        #expect(command.ignoreDnD == true)
    }
    
    @Test("Parse short flags")
    func parseShortFlags() throws {
        let args = ["-m", "Message", "-t", "Title", "-g", "group", "-o", "https://test.com", "-e", "echo test"]
        
        let command = try SendCommand.parse(args)
        #expect(command.message == "Message")
        #expect(command.title == "Title")
        #expect(command.group == "group")
        #expect(command.open == "https://test.com")
        #expect(command.execute == "echo test")
    }
    
    @Test("Parse backward compatibility flags")
    func parseBackwardCompatibilityFlags() throws {
        let args = ["--list", "--remove", "test-group"]
        
        let command = try SendCommand.parse(args)
        #expect(command.list == true)
        #expect(command.remove == "test-group")
    }
    
    @Test("Parse image paths")
    func parseImagePaths() throws {
        let args = [
            "--message", "Test",
            "--appIcon", "/path/to/icon.png",
            "--contentImage", "https://example.com/image.jpg"
        ]
        
        let command = try SendCommand.parse(args)
        #expect(command.appIcon == "/path/to/icon.png")
        #expect(command.contentImage == "https://example.com/image.jpg")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Parse with missing value")
    func parseWithMissingValue() throws {
        let args = ["--message"] // Missing value
        
        #expect(throws: Error.self) {
            try SendCommand.parse(args)
        }
    }
    
    @Test("Parse with unknown option")
    func parseWithUnknownOption() throws {
        let args = ["--unknown-option", "value"]
        
        #expect(throws: Error.self) {
            try SendCommand.parse(args)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockSendCommand(
        message: String? = "Test message",
        title: String? = "Test title",
        subtitle: String? = "Test subtitle",
        sound: String? = "Glass",
        group: String? = "test-group",
        activate: String? = "com.apple.Safari",
        sender: String? = "com.app.test",
        appIcon: String? = "/path/to/icon.png",
        contentImage: String? = "/path/to/image.png",
        open: String? = "https://example.com",
        execute: String? = "echo hello",
        ignoreDnD: Bool = true,
        remove: String? = "test-group",
        list: Bool = true
    ) -> SendCommand {
        var command = SendCommand()
        command.message = message
        command.title = title
        command.subtitle = subtitle
        command.sound = sound
        command.group = group
        command.activate = activate
        command.sender = sender
        command.appIcon = appIcon
        command.contentImage = contentImage
        command.open = open
        command.execute = execute
        command.ignoreDnD = ignoreDnD
        command.remove = remove
        command.list = list
        return command
    }
}