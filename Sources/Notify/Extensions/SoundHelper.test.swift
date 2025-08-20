import Testing
@testable import Notify

@Suite("SoundHelper Tests")
struct SoundHelperTests {
    
    @Test("Default sound validation")
    func defaultSoundIsValid() throws {
        #expect(SoundHelper.isValidSound("default"))
        #expect(SoundHelper.isValidSound(SoundHelper.defaultSound))
    }
    
    @Test("Common system sounds validation", arguments: [
        "Basso", "Glass", "Hero", "Ping", "Pop", "Sosumi"
    ])
    func commonSystemSoundsAreValid(sound: String) throws {
        #expect(
            SoundHelper.isValidSound(sound), 
            "Le son système '\(sound)' devrait être valide"
        )
    }
    
    @Test("Invalid sound names", arguments: [
        "", "NonExistentSound", "invalid-sound-name", "🔊"
    ])
    func invalidSoundNames(sound: String) throws {
        #expect(
            !SoundHelper.isValidSound(sound),
            "Le son '\(sound)' ne devrait pas être valide"
        )
    }
    
    @Test("Available system sounds contains default")
    func availableSystemSoundsContainsDefault() throws {
        let availableSounds = SoundHelper.availableSystemSounds()
        
        #expect(!availableSounds.isEmpty, "La liste des sons ne devrait pas être vide")
        #expect(
            availableSounds.contains("default"),
            "La liste devrait toujours contenir 'default'"
        )
        #expect(
            availableSounds.first == "default",
            "'default' devrait être en première position"
        )
    }
    
    @Test("Available system sounds are sorted")
    func availableSystemSoundsAreSorted() throws {
        let availableSounds = SoundHelper.availableSystemSounds()
        let soundsExceptDefault = availableSounds.dropFirst() // Skip "default" 
        let sortedSounds = soundsExceptDefault.sorted()
        
        #expect(
            Array(soundsExceptDefault) == sortedSounds,
            "Les sons (sauf 'default') devraient être triés alphabétiquement"
        )
    }
    
    @Test("Create UNNotificationSound for default")
    func createUNNotificationSoundForDefault() throws {
        let sound = SoundHelper.createUNNotificationSound(from: "default")
        #expect(sound != nil, "Devrait créer un son pour 'default'")
    }
    
    @Test("Create UNNotificationSound for valid sound")
    func createUNNotificationSoundForValidSound() throws {
        let sound = SoundHelper.createUNNotificationSound(from: "Glass")
        #expect(sound != nil, "Devrait créer un son pour 'Glass'")
    }
    
    @Test("Create UNNotificationSound for invalid sound")
    func createUNNotificationSoundForInvalidSound() throws {
        let sound = SoundHelper.createUNNotificationSound(from: "InvalidSound")
        #expect(sound == nil, "Ne devrait pas créer de son pour un nom invalide")
    }
    
    @Test("Validate and normalize sound name")
    func validateAndNormalizeSoundName() throws {
        // Test avec nil et chaîne vide
        #expect(
            try SoundHelper.validateAndNormalizeSoundName(nil).get() == nil
        )
        #expect(
            try SoundHelper.validateAndNormalizeSoundName("").get() == nil
        )
        #expect(
            try SoundHelper.validateAndNormalizeSoundName("   ").get() == nil
        )
        
        // Test avec son valide
        #expect(
            try SoundHelper.validateAndNormalizeSoundName("default").get() == "default"
        )
        #expect(
            try SoundHelper.validateAndNormalizeSoundName("Glass").get() == "Glass"
        )
        
        // Test avec extension .aiff
        #expect(
            try SoundHelper.validateAndNormalizeSoundName("Glass.aiff").get() == "Glass"
        )
        
        // Test avec espaces
        #expect(
            try SoundHelper.validateAndNormalizeSoundName("  Glass  ").get() == "Glass"
        )
    }
    
    @Test("Validate and normalize sound name with invalid sound")
    func validateAndNormalizeSoundNameWithInvalidSound() throws {
        let result = SoundHelper.validateAndNormalizeSoundName("InvalidSound")
        
        switch result {
        case .success:
            Issue.record("Devrait échouer avec un son invalide")
        case .failure(let error):
            #expect(error is SoundError)
            if case .invalidSound(let soundName) = error {
                #expect(soundName == "InvalidSound")
            } else {
                Issue.record("Devrait être une erreur de type invalidSound")
            }
        }
    }
    
    @Test("Sound error descriptions")
    func soundErrorDescriptions() throws {
        let invalidSoundError = SoundError.invalidSound("TestSound")
        let systemUnavailableError = SoundError.systemSoundsUnavailable
        
        #expect(invalidSoundError.errorDescription != nil)
        #expect(invalidSoundError.recoverySuggestion != nil)
        #expect(invalidSoundError.errorDescription!.contains("TestSound"))
        
        #expect(systemUnavailableError.errorDescription != nil)
        #expect(systemUnavailableError.recoverySuggestion != nil)
    }
}