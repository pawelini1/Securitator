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
    private let securefile: Securefile
    
    public init(file: File) throws {
        self.file = file
        self.securefile = try Securefile.from(file: file)
    }
}

public extension Securitator {
    func secureContent(atPath path: Path) throws {
        if let file = try? File(path: path) {
            try secureContent(ofFiles: [file])
        } else if let folder = try? Folder(path: path) {
            try secureContent(ofFilesIn: folder)
        } else {
            throw Error.wrongPath(path)
        }
    }

    func secureContent(ofFilesIn folder: Folder) throws {
        print("Securing files in folder: ".cyan + "\(folder.absolutePath)")
        try secureContent(ofFiles: folder.files.recursive.map { $0 })
    }
    
    func secureContent(ofFile file: File) throws {
        print("Securing file: ".cyan + "\(file.absolutePath)")
        try secureContent(ofFiles: [file])
    }
    
    func secureContent(ofFiles files: [File]) throws {
        guard let baseFolder = file.parent else { throw Error.missingParent(file) }
        
        let filesToCheck = try securefile.exclude.flatMap { try files.applyExclusions(with: $0, baseFolder: baseFolder) } ?? files
        let _ = try filesToCheck.compactMap { file -> Path? in
            let content = try file.readAsString()
            let securedContent = securefile.secrets.reduce(content) { (content, secret) -> String in
                content.replacingOccurrences(of: secret.value, with: secureKey(for: secret.key))
            }
            guard content != securedContent else { return nil }
            print("File secured: ".green + "\(file.absolutePath)")
            try file.write(securedContent)
            return file.path(relativeTo: baseFolder)
        }
    }
}

public extension Securitator {
    func revealContent(atPath path: Path, intoFolder output: Folder? = nil) throws {
        if let file = try? File(path: path) {
            try revealContent(ofFiles: [file], intoFolder: output)
        } else if let folder = try? Folder(path: path) {
            try revealContent(ofFilesIn: folder, intoFolder: output)
        } else {
            throw Error.wrongPath(path)
        }
    }

    func revealContent(ofFilesIn folder: Folder, intoFolder output: Folder? = nil) throws {
        print("Revealing secrets from files in folder: ".cyan + "\(folder.absolutePath)")
        try revealContent(ofFiles: folder.files.recursive.map { $0 }, intoFolder: output)
    }
    
    func revealContent(ofFile file: File, intoFolder output: Folder? = nil) throws {
        print("Revealing secrets from file: ".cyan + "\(file.absolutePath)")
        try revealContent(ofFiles: [file], intoFolder: output)
    }
    
    func revealContent(ofFiles files: [File], intoFolder output: Folder? = nil) throws {
        guard let baseFolder = file.parent else { throw Error.missingParent(file) }
        
        let filesToCheck = try securefile.exclude.flatMap { try files.applyExclusions(with: $0, baseFolder: baseFolder) } ?? files
        try filesToCheck.forEach { file in
            let content = try file.readAsString()
            let revealedContent = securefile.secrets.reduce(content) { (content, secret) -> String in
                content.replacingOccurrences(of: secureKey(for: secret.key), with: secret.value)
            }
            guard content != revealedContent else { return }
            print("File revealed: ".green + "\(file.absolutePath)")
            guard let output = output else {
                try file.write(revealedContent)
                return
            }
            let newFile = try output.createFileIfNeeded(withName: file.name)
            print("         into: ".green + "\(newFile.absolutePath)")
            try newFile.write(revealedContent)
        }
    }
}

private extension Securitator {
    func secureKey(for key: String) -> String {
        "##[SECRET:\(key)]##"
    }
}
