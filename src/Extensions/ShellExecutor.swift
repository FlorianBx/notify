import Foundation

extension NSMutableData: @retroactive @unchecked Sendable {}

@available(macOS 13.0, *)
public actor ShellExecutor {
    public static let shared = ShellExecutor()
    
    private init() {}
    
    public func execute(_ command: String, timeout: TimeInterval = 30.0) async -> ShellResult {
        return await withTaskGroup(of: ShellResult.self) { group in
            group.addTask {
                await self.runCommand(command)
            }
            
            group.addTask {
                try? await Task.sleep(for: .seconds(timeout))
                return .failure(.timeout)
            }
            
            guard let result = await group.next() else {
                return .failure(.unknown("Task group failed"))
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private func runCommand(_ command: String) async -> ShellResult {
        return await withCheckedContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", command]
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            let outputData = NSMutableData()
            let errorData = NSMutableData()
            let dataLock = NSLock()
            
            outputPipe.fileHandleForReading.readabilityHandler = { [outputData, dataLock] handle in
                let data = handle.availableData
                dataLock.lock()
                outputData.append(data)
                dataLock.unlock()
            }
            
            errorPipe.fileHandleForReading.readabilityHandler = { [errorData, dataLock] handle in
                let data = handle.availableData
                dataLock.lock()
                errorData.append(data)
                dataLock.unlock()
            }
            
            process.terminationHandler = { [outputData, errorData] process in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                let output = String(data: outputData as Data, encoding: .utf8) ?? ""
                let error = String(data: errorData as Data, encoding: .utf8) ?? ""
                
                let result = ShellCommandResult(
                    command: command,
                    exitCode: process.terminationStatus,
                    output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                    error: error.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: .success(result))
                } else {
                    let shellError = ShellError.commandFailed(result.exitCode, result.error.isEmpty ? result.output : result.error)
                    continuation.resume(returning: .failure(shellError))
                }
            }
            
            do {
                try process.run()
            } catch {
                let shellError = ShellError.executionFailed(error.localizedDescription)
                continuation.resume(returning: .failure(shellError))
            }
        }
    }
    
    public func executeDetached(_ command: String) -> Result<Process, ShellError> {
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.standardOutput = nil
        process.standardError = nil
        process.standardInput = nil
        
        do {
            try process.run()
            return .success(process)
        } catch {
            return .failure(.executionFailed(error.localizedDescription))
        }
    }
    
    public func validateCommand(_ command: String) -> Result<Void, ShellError> {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedCommand.isEmpty else {
            return .failure(.invalidCommand("Command cannot be empty"))
        }
        
        let dangerousPatterns = ["rm -rf /", "sudo rm", "format", "mkfs", "> /dev/"]
        for pattern in dangerousPatterns {
            if trimmedCommand.contains(pattern) {
                return .failure(.dangerousCommand(pattern))
            }
        }
        
        return .success(())
    }
}

@available(macOS 13.0, *)
public struct ShellCommandResult: Sendable, Codable {
    public let command: String
    public let exitCode: Int32
    public let output: String
    public let error: String
    
    public var isSuccess: Bool {
        return exitCode == 0
    }
    
    public var combinedOutput: String {
        if !error.isEmpty {
            return output.isEmpty ? error : "\(output)\n\(error)"
        }
        return output
    }
}

@available(macOS 13.0, *)
public enum ShellError: LocalizedError, Sendable {
    case invalidCommand(String)
    case dangerousCommand(String)
    case executionFailed(String)
    case commandFailed(Int32, String)
    case timeout
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCommand(let reason):
            return "Invalid command: \(reason)"
        case .dangerousCommand(let pattern):
            return "Dangerous command detected: \(pattern)"
        case .executionFailed(let reason):
            return "Failed to execute command: \(reason)"
        case .commandFailed(let code, let message):
            return "Command failed with exit code \(code): \(message)"
        case .timeout:
            return "Command execution timed out"
        case .unknown(let reason):
            return "Unknown error: \(reason)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidCommand:
            return "Provide a valid shell command."
        case .dangerousCommand:
            return "This command is potentially dangerous and has been blocked."
        case .executionFailed:
            return "Check that the shell is available and accessible."
        case .commandFailed:
            return "Check the command syntax and arguments."
        case .timeout:
            return "Try with a longer timeout or a simpler command."
        case .unknown:
            return "Try again or check system resources."
        }
    }
}

@available(macOS 13.0, *)
public typealias ShellResult = Result<ShellCommandResult, ShellError>