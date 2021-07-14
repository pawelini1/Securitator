import Foundation
import ArgumentParser
import SecuritatorKit
import Files

struct SecuritatorApp: ParsableCommand {
    struct Secure: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Secures the files by replacing all `secrets` with it's path in Securefile")
        
        @Argument(help: "A path to folder or file to secure")
        var path: Path
        @Option(help: "A path to `Securefile`")
        var securefile: Path = "./Securefile"
        
        mutating func run() {
            do {
                try Securitator(file: try File(path: securefile)).secureContent(atPath: path)
                print("Securitator finished successfully...".green)
            } catch {
                print("Securitator finished with an error...".red)
                SecuritatorApp.Secure.exit(withError: error)
            }
        }
    }
    
    struct Reveal: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Reveals the file by replacing all `securePaths` with `secrets` from Securefile")
        
        @Argument(help: "A path to folder or file to reveal")
        var path: Path
        @Option(help: "A path to a folder where revealed file should be saved. if not provided, source file paths will be used")
        var outputDirectory: Path?
        @Option(help: "A path to `Securefile`")
        var securefile: Path = "./Securefile"
        
        mutating func run() {
            do {
                try Securitator(file: try File(path: securefile)).revealContent(atPath: path,
                                                                                intoFolder: outputDirectory.flatMap { try Folder.createIfNeeded(path: $0) })
                print("Securitator finished successfully...".green)
            } catch {
                print("Securitator finished with an error...".red)
                SecuritatorApp.Reveal.exit(withError: error)
            }
        }
    }
    
    static var configuration = CommandConfiguration(
        commandName: "securitator",
        abstract: "A utility for managing `secrets` in software projects.",
        version: "1.1.0",
        subcommands: [Secure.self, Reveal.self])
}

SecuritatorApp.main()
