import Foundation
import Files
import Yams

public typealias Key = String
public typealias Secret = String
public typealias Regex = String

public struct Securefile: Codable {    
    public struct Exclude: Codable {
        public private(set) var prefix: [Path]
        public private(set) var suffix: [String]
        public private(set) var contains: [String]
        
        public init(prefix: [String] = [], suffix: [String] = [], contains: [String] = []) {
            self.prefix = prefix
            self.suffix = suffix
            self.contains = contains
        }
    }
    
    public private(set) var secrets: [Key: Secret]
    public private(set) var exclude: Exclude?

    public var allSecrets: [Secret] {
        secrets.values.map { $0 }
    }
    
    public init(secrets: [String: String] = [:], exclude: Exclude? = nil) {
        self.secrets = secrets
        self.exclude = exclude
    }
    
    public static func from(file: File) throws -> Self {
        let decoder = YAMLDecoder()
        return try decoder.decode(from: try file.readAsString())
    }
}
