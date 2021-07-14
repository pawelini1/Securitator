import Foundation
import Files

public typealias Path = String

public extension Path {
    enum PathError: Swift.Error {
        case noSuchFileOrFolder(Path)
    }
    
    func apply(prefixPath: Path) throws -> AbsolutePath? {
        let fullPath = "\(prefixPath)/\(self)"
        let paths: [AbsolutePath?] = [
            try? File(path: fullPath),
            try? Folder(path: fullPath)
        ]
        guard let anyLocation = paths.compactMap({ $0 }).first else {
            return nil
        }
        return anyLocation
    }
}

public extension String {
    func contains(anyOf strings: [String]) -> Bool {
        strings.first(where: { self.contains($0) }) != nil
    }
    
    func hasAnyPrefix(of strings: [String]) -> Bool {
        strings.first(where: { self.hasPrefix($0) }) != nil
    }
    
    func hasAnySuffix(of strings: [String]) -> Bool {
        strings.first(where: { self.hasSuffix($0) }) != nil
    }
    
    func matches(for regex: NSRegularExpression) -> [String] {
        let range = NSRange(location: 0, length: utf16.count)
        let matches = regex.matches(in: self, options: [], range: range)
        return matches.compactMap {
            guard $0.numberOfRanges > 0 else { return nil }
            let range = $0.range(at: 0)
            guard range.length > 0 else { return nil }
            return (self as NSString).substring(with: range)
        }.compactMap { $0 }
    }
}

public protocol AbsolutePath {
    var absolutePath: String { get }
}

extension File: AbsolutePath {
    public var absolutePath: String { url.path }
    
    public static func createIfNeeded(path: String) throws -> File {
        do {
            return try File(path: path)
        } catch let locationError as LocationError {
            switch locationError.reason {
            case .missing:
                FileManager.default.createFile(atPath: path, contents: Data(), attributes: [:])
                return try File(path: path)
            default:
                throw locationError
            }
        }
    }
}

extension Folder: AbsolutePath {
    public var absolutePath: String { url.path }
    
    public static func createIfNeeded(path: String) throws -> Folder {
        do {
            return try Folder(path: path)
        } catch let locationError as LocationError {
            switch locationError.reason {
            case .missing:
                try FileManager.default.createDirectory(atPath: path,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
                return try Folder(path: path)
            default:
                throw locationError
            }
        }
    }
}

extension Sequence where Element == File {
    public func applyExclusions(with exclude: Securefile.Exclude, baseFolder: Folder) throws -> [File] {
        let prefixes = try exclude.prefix.compactMap { try $0.apply(prefixPath: baseFolder.absolutePath)?.absolutePath }
        return self
            .filter { !$0.absolutePath.hasAnyPrefix(of: prefixes) }
            .filter { !$0.absolutePath.hasAnySuffix(of: exclude.suffix) }
            .filter { !$0.absolutePath.contains(anyOf: exclude.contains) }
    }
}
