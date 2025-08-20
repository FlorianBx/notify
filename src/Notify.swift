import ArgumentParser
import Foundation

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
@main
struct Notify: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notify",
        abstract: "Send User Notifications on macOS from the command line",
        version: "0.2",
        subcommands: [SendCommand.self, RemoveCommand.self, ListCommand.self],
        defaultSubcommand: SendCommand.self,
        helpNames: [.short, .long, .customLong("help")]
    )
}