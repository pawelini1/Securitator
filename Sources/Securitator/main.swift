import Foundation
import ArgumentParser
import SecuritatorKit
import Files

struct BasicOptions: ParsableArguments {
    @Argument(help: "A path to folder or file to secure/reveal")
    var path: Path
    @Option(help: "A path to `Securefile`")
    var securefile: Path = "./Securefile"
}

struct CacheOptions: ParsableArguments {
    @Option(help: "A path to a file containing the list of all files with secrets")
    var cachePath: Path?
}

struct SecuritatorApp: ParsableCommand {
    struct Secure: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Secures the files by replacing all `secrets` with it's path in Securefile")
        
        @OptionGroup
        var basicOptions: BasicOptions
        @OptionGroup
        var cacheOptions: CacheOptions
        
        mutating func run() {
            do {
                try Securitator(file: try File(path: basicOptions.securefile)).secureContent(atPath: basicOptions.path,
                                                                                             withCachePath: cacheOptions.cachePath)
                print("Securitator finished successfully...".green)
            } catch {
                print("Securitator finished with an error...".red)
                Self.exit(withError: error)
            }   
        }
    }
    
    struct Reveal: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Reveals the file by replacing all `securePaths` with `secrets` from Securefile")
        
        @OptionGroup
        var basicOptions: BasicOptions
        @OptionGroup
        var cacheOptions: CacheOptions
        @Option(help: "A path to a folder where revealed files should be saved. If not provided, source file will be overriden")
        var outputDirectory: Path?
        
        mutating func run() {
            do {
                try Securitator(file: try File(path: basicOptions.securefile)).revealContent(atPath: basicOptions.path,
                                                                                             intoFolder: outputDirectory.flatMap { try Folder.createIfNeeded(path: $0) },
                                                                                             withCachePath: cacheOptions.cachePath)
                print("Securitator finished successfully...".green)
            } catch {
                print("Securitator finished with an error...".red)
                Self.exit(withError: error)
            }
        }
    }
    
    struct Verify: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Verifies that all secrets are property secured.")
        
        @OptionGroup
        var basicOptions: BasicOptions
        
        mutating func run() {
            do {
                try Securitator(file: try File(path: basicOptions.securefile)).verifyContent(atPath: basicOptions.path)
                print("Securitator finished successfully...".green)
            } catch {
                print("Securitator finished with an error...".red)
                Self.exit(withError: error)
            }
        }
    }
    
    static var configuration = CommandConfiguration(
        commandName: "securitator",
        abstract: "A utility for managing `secrets` in software projects.",
        version: "1.3.0",
        subcommands: [Secure.self, Reveal.self, Verify.self])
}

SecuritatorApp.main()
