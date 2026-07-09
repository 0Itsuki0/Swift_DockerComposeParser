//
//  Node+Extensions.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

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

    /// handle properties such as `service.dns` that can be specified as either a single value or a list
    /// dns: 8.8.8.8
    /// or
    /// dns:
    /// - 8.8.8.8
    /// - 9.9.9.9
    public func array(
        of type: String.Type = String.self,
        envs: [String: String]
    )
        throws -> [String]
    {
        if self.sequence != nil {
            return try self.array(of: String.self).map({
                try Utility.resolveVariable($0, with: envs)
            })
        }

        if let single = self.string {
            return [try Utility.resolveVariable(single, with: envs)]
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: [],
                debugDescription: "Invalid yaml data. Expected an array."
            )
        )
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
    /// handling properties such as `service.labels` that can accept a list of key=value, or a map of key: value.
    /// labels:
    /// com.example.description: "Accounting webapp"
    /// com.example.department: "Finance"
    /// com.example.label-with-empty-value: ""
    /// or
    /// labels:
    /// - "com.example.description=Accounting webapp"
    /// - "com.example.department=Finance"
    /// - "com.example.label-with-empty-value"
    public func dictionary(envs: [String: String], isEnv: Bool = false) throws
        -> [String: String]
    {
        if let mapping = self.mapping {
            var result: [String: String] = [:]
            for (key, value) in mapping {
                guard let keyString = key.string else { continue }
                // last write win
                result[keyString] = try value.string(envs: envs)
            }
            return result
        }

        if let asList = try? self.array(of: String.self, envs: envs),
            !asList.isEmpty
        {
            return Utility.parseKeyValueList(asList, isEnv: isEnv)
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: [],
                debugDescription: "Invalid yaml data. Expected a mapping."
            )
        )
    }

    // handling properties such as `service.models` that can accept a list of model names, or a map of model name -> Model options (possibly null).
    // Example:
    // services:
    // short_syntax:
    //   image: app
    //   models:
    //     - my_model
    // long_syntax:
    //   image: app
    //   models:
    //     my_model:
    //       endpoint_var: MODEL_URL
    //       model_var: MODEL
    public func dictionary<T>(
        type: T.Type = T.self,
        envs: [String: String],
        transformMap: @escaping (_ key: String, _ value: Node) throws -> T,
        transformArray: @escaping ([String]) throws -> [String: T]
    ) throws -> [String: T] {
        if let asMap = self.mapping {
            var normalized: [String: T] = [:]
            for (key, valueNode) in asMap {
                guard let keyString = key.string else { continue }
                normalized[keyString] = try transformMap(keyString, valueNode)
            }
            return normalized
        }
        
        if let asList = try? self.array(of: String.self, envs: envs),
            !asList.isEmpty
        {
            return try transformArray(asList)
        }
        
        throw DecodingError.dataCorrupted(
            .init(
                codingPath: [],
                debugDescription: "Invalid yaml data. Expected a mapping."
            )
        )
    }
}
