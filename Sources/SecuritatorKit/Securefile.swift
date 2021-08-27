import Foundation
import Files
import Yams

public typealias Key = String
public typealias Secret = String
public typealias Regex = String
public typealias SecretsDictionary = [Secret: [Key]]

public class Config: Encodable {
    public private(set) var keys: [Key]
    public let secret: Secret
    
    public init(secret: Secret, keys: [Key]) {
        precondition(!keys.isEmpty, "\(\Config.keys) property in Config must not be empty.")
        self.secret = secret
        self.keys = keys
    }
    
    public var mainKey: Key { keys.first! }
    public var otherKeys: [Key] { [Key](keys.dropFirst()    ) }

    internal func append(_ key: Key) {
        keys.append(key)
    }
    
    internal func append(contentsOf array: [Key]) {
        keys.append(contentsOf: array)
    }
}

public struct Exclude: Codable {
    public fileprivate(set) var prefix: [Path]
    public fileprivate(set) var suffix: [String]
    public fileprivate(set) var contains: [String]
    
    public init(prefix: [String] = [], suffix: [String] = [], contains: [String] = []) {
        self.prefix = prefix
        self.suffix = suffix
        self.contains = contains
    }
}

public class Securefile: Codable {
    public fileprivate(set) var configs: [Config]
    public fileprivate(set) var exclude: Exclude?
    
    public lazy var allSecrets: [Secret] = {
        Set<Secret>(configs.map { $0.secret }).map { $0 }
    }()
    
    private enum CodingKeys: String, CodingKey { case secrets, exclude }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.exclude = try container.decode(Exclude.self, forKey: .exclude)
        let secrets = try container.decode(SecretsDictionary.self, forKey: .secrets)
        self.configs = secrets.toConfigs()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configs.toDictionary(), forKey: .secrets)
        try container.encode(exclude, forKey: .exclude)
    }
    
    @available(*, deprecated, message: "Please use init(configs: [Config], exclude: Exclude?) instead.")
    public init(secrets: SecretsDictionary = [:], exclude: Exclude? = nil) {
        self.configs = secrets.toConfigs()
        self.exclude = exclude
    }
    
    public init(configs: [Config] = [], exclude: Exclude? = nil) {
        self.configs = configs
        self.exclude = exclude
    }
    
    public static func from(file: File) throws -> Self {
        let decoder = YAMLDecoder()
        return try decoder.decode(from: try file.readAsString())
    }
    
    public func save(toFile file: File) throws {
        let encoder = YAMLEncoder()
        let yamlString = try encoder.encode(self)
        try file.write(yamlString)
    }
}

private extension Array where Element == Config {
    func toDictionary() -> [Secret: [Key]] {
        reduce(into: [Secret: [Key]]()) { result, object in
            result[object.secret] = object.keys
        }
    }
}

private extension SecretsDictionary {
    func toConfigs() -> [Config] {
        reduce(into: [Config]()) { result, object in
            let secret = object.key
            guard let existingConfig = result.first(where: { $0.secret == secret }) else {
                result.append(Config(secret: secret, keys: object.value))
                return
            }
            existingConfig.append(contentsOf: object.value)
        }
    }
}

private extension LegacySecretsDictionary {
    func toConfigs() -> [Config] {
        keys.sorted().reduce(into: [Config]()) { result, key in
            let secret = self[key]!
            guard let existingConfig = result.first(where: { $0.secret == secret }) else {
                result.append(Config(secret: secret, keys: [key]))
                return
            }
            existingConfig.append(key)
        }
    }
}

public typealias LegacySecretsDictionary = [Key: Secret]

public class LegacySecurefile: Securefile {
    private enum CodingKeys: String, CodingKey { case secrets, exclude }
    
    required public init(from decoder: Decoder) throws {
        super.init(configs: [], exclude: nil)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.exclude = try container.decode(Exclude.self, forKey: .exclude)
        let secrets = try container.decode(LegacySecretsDictionary.self, forKey: .secrets)
        self.configs = secrets.toConfigs()
    }
}

