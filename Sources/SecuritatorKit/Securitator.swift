import Foundation
import Files
import Yams
import Rainbow

public class Securitator {
    public enum Error: Swift.Error {
        case missingParent(File)
        case wrongPath(Path)
        case noFindPatternsDefined
    }
    
    private let file: File
    private var baseFolder: Folder { file.parent! }

    private let securefile: Securefile
    
    public init(file: File) throws {
        self.file = file
        self.securefile = try Securefile.from(file: file)
    }
}

public extension Securitator {
    func secureContent(atPath path: Path, withCachePath cachePath: Path?) throws {
        guard let cacheFile = cachePath.flatMap({ try? File(path: $0) }) else {
            let securefileLock = try secureContent(atPath: path)
            try cachePath.flatMap({ try File.createIfNeeded(path: $0) }).flatMap({ try securefileLock.save(toFile: $0) })
            return
        }
        try secureContent(fromCache: cacheFile)
    }
    
    func secureContent(atPath path: Path) throws -> SecurefileLock {
        if let file = try? File(path: path) {
            return try secureContent(ofFile: file)
        } else if let folder = try? Folder(path: path) {
            return try secureContent(ofFilesIn: folder)
        } else {
            throw Error.wrongPath(path)
        }
    }

    func secureContent(ofFilesIn folder: Folder) throws -> SecurefileLock {
        print("Securing files in folder: ".cyan + "\(folder.absolutePath)")
        return try secureContent(ofFiles: folder.files.recursive.map { $0 })
    }
    
    func secureContent(ofFile file: File) throws -> SecurefileLock {
        print("Securing file: ".cyan + "\(file.absolutePath)")
        return try secureContent(ofFiles: [file])
    }
    
    func secureContent(fromCache file: File) throws {
        print("Re-securing files based on paths from: ".cyan + "\(file.absolutePath)")
        let securefileLock = try SecurefileLock.from(file: file)
        let _ = try secureContent(ofFiles: securefileLock.secrets.map { try File(baseFolder: baseFolder, path: $0) })
    }
    
    func secureContent(ofFiles files: [File]) throws -> SecurefileLock {
        let filesToCheck = try securefile.exclude.flatMap { try files.applyExclusions(with: $0, baseFolder: baseFolder) } ?? files
        return SecurefileLock(secrets: try filesToCheck.compactMap { file -> Path? in
            let content = try file.readAsString()
            let securedContent = securefile.secrets.reduce(content) { (content, secret) -> String in
                content.replacingOccurrences(of: secret.value, with: secureKey(for: secret.key))
            }
            guard content != securedContent else {
                guard securedContent.contains(securePrefix) else { return nil }
                print("File already secured: ".green + "\(file.absolutePath)")
                return baseFolderRelatedPath(to: file)
            }
            print("File secured: ".green + "\(file.absolutePath)")
            try file.write(securedContent)
            return baseFolderRelatedPath(to: file)
        })
    }
}

public extension Securitator {
    func revealContent(atPath path: Path, intoFolder output: Folder? = nil, withCachePath cachePath: Path?) throws {
        guard let cacheFile = cachePath.flatMap({ try? File(path: $0) }) else {
            let securefileLock = try revealContent(atPath: path)
            try cachePath.flatMap({ try File.createIfNeeded(path: $0) }).flatMap({ try securefileLock.save(toFile: $0) })
            return
        }
        try revealContent(fromCache: cacheFile)
    }
    
    func revealContent(atPath path: Path, intoFolder output: Folder? = nil) throws -> SecurefileLock {
        if let file = try? File(path: path) {
            return try revealContent(ofFiles: [file], intoFolder: output)
        } else if let folder = try? Folder(path: path) {
            return try revealContent(ofFilesIn: folder, intoFolder: output)
        } else {
            throw Error.wrongPath(path)
        }
    }

    func revealContent(ofFilesIn folder: Folder, intoFolder output: Folder? = nil) throws -> SecurefileLock {
        print("Revealing secrets from files in folder: ".cyan + "\(folder.absolutePath)")
        return try revealContent(ofFiles: folder.files.recursive.map { $0 }, intoFolder: output)
    }
    
    func revealContent(ofFile file: File, intoFolder output: Folder? = nil) throws -> SecurefileLock {
        print("Revealing secrets from file: ".cyan + "\(file.absolutePath)")
        return try revealContent(ofFiles: [file], intoFolder: output)
    }
    
    func revealContent(fromCache file: File, intoFolder output: Folder? = nil) throws {
        print("Re-reveal files based on paths from: ".cyan + "\(file.absolutePath)")
        let securefileLock = try SecurefileLock.from(file: file)
        let _ = try revealContent(ofFiles: securefileLock.secrets.map { try File(baseFolder: baseFolder, path: $0) }, intoFolder: output)
    }
    
    func revealContent(ofFiles files: [File], intoFolder output: Folder? = nil) throws -> SecurefileLock {
        let filesToCheck = try securefile.exclude.flatMap { try files.applyExclusions(with: $0, baseFolder: baseFolder) } ?? files
        let allSecrets = securefile.allSecrets
        return SecurefileLock(secrets: try filesToCheck.compactMap { file -> Path? in
            let content = try file.readAsString()
            let revealedContent = securefile.secrets.reduce(content) { (content, secret) -> String in
                content.replacingOccurrences(of: secureKey(for: secret.key), with: secret.value)
            }
            guard content != revealedContent else {
                guard revealedContent.contains(anyOf: allSecrets) else { return nil }
                print("File already revealed: ".green + "\(file.absolutePath)")
                return baseFolderRelatedPath(to: file)
            }
            print("File revealed: ".green + "\(file.absolutePath)")
            guard let output = output else {
                try file.write(revealedContent)
                return baseFolderRelatedPath(to: file)
            }
            let newFile = try output.createFileIfNeeded(withName: file.name)
            print("         into: ".green + "\(newFile.absolutePath)")
            try newFile.write(revealedContent)
            return baseFolderRelatedPath(to: file)
        })
    }
}

private extension Securitator {
    var securePrefix: String { "##[SECRET:" }
    var secureSuffix: String { "]##" }
    
    func secureKey(for key: String) -> String {
        "\(securePrefix)\(key)\(secureSuffix)"
    }
    
    func baseFolderRelatedPath(to file: File) -> Path {
        file.path(excludingPrefix: baseFolder.absolutePath)
    }
}
