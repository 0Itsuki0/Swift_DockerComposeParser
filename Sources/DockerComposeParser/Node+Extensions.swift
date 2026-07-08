//
//  Node+Extensions.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

import Collections
import Yams

public enum ComposeTag: String, Codable, Hashable {
    case override = "!override"
    case reset = "!reset"
}

extension Node.Mapping {

    func value(for key: CodingKey) throws -> Node {
        guard let value = self[key.stringValue] else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid yaml data. Missing key: \(key.stringValue)."
                )
            )
        }
        return value
    }
    
    func composeTag(for key: CodingKey) -> ComposeTag? {
        (try? self.value(for: key))?.composeTag
    }
}

extension Node {
    var composeTag: ComposeTag? {
        let rawValue = self.tag.rawValue
        return ComposeTag(rawValue: rawValue)
    }

    /// This node as a `String`, if convertible.
    public func string(envs: [String: String]) throws -> String? {
        guard let string = self.string else {
            return nil
        }
        return try Utility.resolveVariable(string, with: envs)
    }

    public func int(envs: [String: String]) throws -> Int? {
        guard let string = try self.string(envs: envs) else {
            return nil
        }
        return Int(string)
    }

    public func array(
        of type: String.Type = String.self,
        envs: [String: String]
    )
        throws -> [String]
    {
        return try self.array(of: String.self).map({
            try Utility.resolveVariable($0, with: envs)
        })
    }

    public func array<Type: NodeConvertible>(
        of type: Type.Type = Type.self,
        envs: [String: String]
    )
        throws -> [Type]
    {
        if let sequence {
            return try sequence.compactMap { try type.init($0, envs: envs) }
        }
        if let single = try? type.init(self, envs: envs) {
            return [single]
        }
        throw DecodingError.dataCorrupted(
            .init(
                codingPath: [],
                debugDescription:
                    "Invalid yaml data. Expected an array."
            )
        )
    }

    /// This node as a `[String: String]`, resolving env vars in each value.
    /// Throws if the node isn't a mapping (mirrors `.array(of:envs:)`'s behavior
    /// for non-sequence nodes).
    public func dictionary(envs: [String: String]) throws -> [String: String] {
        guard let mapping = self.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }
        var result: [String: String] = [:]
        for (key, value) in mapping {
            guard let keyString = key.string else { continue }
            // last write win
            result[keyString] = try value.string(envs: envs)
        }
        return result
    }

    public func orderedDict<V: NodeConvertible>(
        of type: V.Type = V.self,
        envs: [String: String]
    ) throws -> OrderedDictionary<String, V> {
        guard let mapping = self.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }
        var result: OrderedDictionary<String, V> = [:]
        for (key, value) in mapping {
            guard let keyString = key.string else { continue }
            result[keyString] = try type.init(value, envs: envs)
        }
        return result
    }
}
