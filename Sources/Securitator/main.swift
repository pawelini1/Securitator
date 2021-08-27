import Foundation
import ArgumentParser
import SecuritatorKit
import Files

enum SecuritatorError: Error {
    case securefileFormatDeprecated(Path)
    case securefileAlreadyConverted(Path)
}

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

struct ConvertOptions: ParsableArguments {
    @Option(help: "A path to `Securefile` to convert to new format")
    var securefile: Path = "./Securefile"
    @Option(help: "A path to file where new Securefile should be saved")
    var output: Path = "./Securefile~2.0.0"
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
                Self.exitWithSuccess()
            } catch let decodingError as DecodingError {
                Self.exitWithMessage(for: decodingError, afterCheckingSecurefileForDeprecatedFormat: basicOptions.securefile)
            } catch {
                Self.exitWithMessage(for: error)
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
                Self.exitWithSuccess()
            } catch let decodingError as DecodingError {
                Self.exitWithMessage(for: decodingError, afterCheckingSecurefileForDeprecatedFormat: basicOptions.securefile)
            } catch {
                Self.exitWithMessage(for: error)
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
                Self.exitWithSuccess()
            } catch let decodingError as DecodingError {
                Self.exitWithMessage(for: decodingError, afterCheckingSecurefileForDeprecatedFormat: basicOptions.securefile)
            } catch {
                Self.exitWithMessage(for: error)
            }
        }
    }
    
    struct Convert: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Converts the format of Securefile used by 1.x.x into new format used by 2.x.x    ")
        
        @OptionGroup
        var convertOptions: ConvertOptions
        
        mutating func run() {
            do {
                let inputFile = try File(path: convertOptions.securefile)
                let securefile = try LegacySecurefile.from(file: inputFile)
                print("Converting legacy format of Securefile: ".cyan + inputFile.absolutePath)
                securefile.configs.forEach { config in
                    guard config.keys.count > 1 else { return }
                    print("Remember to review the order of keys: \(config.keys) in output file as the first one will be used for securing. For now it's ordered alphabetically.".yellow)
                }
                let outputFile = try File.createIfNeeded(path: convertOptions.output)
                print("Saving new format of Securefile to: ".cyan + outputFile.absolutePath)
                try securefile.save(toFile: outputFile)
                Self.exitWithSuccess()
            } catch let decodingError as DecodingError {
                Self.exitWithMessage(for: decodingError, afterCheckingSecurefileForLatestFormat: convertOptions.securefile)
            } catch {
                Self.exitWithMessage(for: error)
            }
        }
    }
    
    static var configuration = CommandConfiguration(
        commandName: "securitator",
        abstract: "A utility for managing `secrets` in software projects.",
        version: "2.0.0",
        subcommands: [Secure.self, Reveal.self, Verify.self, Convert.self]
    )
}

private extension ParsableCommand {
    static func exitWithMessage(for error: Error? = nil) -> Never {
        print("Securitator finished with an error...".red)
        exit(withError: error)
    }
    
    static func exitWithSuccess() {
        print("Securitator finished successfully...".green)
        exit()
    }
    
    static func exitWithMessage(for error: Error? = nil, afterCheckingSecurefileForDeprecatedFormat path: Path) -> Never {
        let file = try! File(path: path)
        guard let _ = try? LegacySecurefile.from(file: file) else {
            Self.exitWithMessage(for: error)
        }
        print("Your Securefile [\(file.absolutePath)] uses depracated format. Run 'securitator help convert' for more details on how to convert it to latest format.".red)
        Self.exitWithMessage(for: SecuritatorError.securefileFormatDeprecated(file.absolutePath))
    }
    
    static func exitWithMessage(for error: Error? = nil, afterCheckingSecurefileForLatestFormat path: Path) -> Never {
        let file = try! File(path: path)
        guard let _ = try? Securefile.from(file:) else {
            Self.exitWithMessage(for: error)
        }
        print("Input Securefile [\(file.absolutePath)] is already converted to a new format.".red)
        Self.exitWithMessage(for: SecuritatorError.securefileAlreadyConverted(file.absolutePath))
    }
}

SecuritatorApp.main()
