import Foundation
import Files
import Yams

public struct SecurefileLock: Codable {
    public private(set) var secrets: [Path]
    
    public init(secrets: [Path] = []) {
        self.secrets = secrets
    }
    
    public mutating func append(path: Path) {
        secrets.append(path)
    }
    
    public static func from(file: File) throws -> Self {
        let decoder = YAMLDecoder()
        return try decoder.decode(from: try file.readAsString())
    }
    
    public func save(toFile file: File) throws {
        let encoder = YAMLEncoder()
        try file.write(try encoder.encode(self))
    }
}
