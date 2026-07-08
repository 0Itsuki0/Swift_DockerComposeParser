//
//  Merging.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//

import Foundation
import Playgrounds
import Yams

// TODO: -
// Memo: either resolve the context URL in init or right before merging,
// because file URLs are relative to the compose file they are declared in
//
//public protocol Mergable {
//    func merge(with update: Self) throws -> Self
//}

extension Encodable where Self: Decodable {
    public func deepMerge(with update: Self) throws -> Self {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let baseData = try encoder.encode(self)
        let updateData = try encoder.encode(update)

        // This structural map is now ONLY used as a structural topology template,
        // because we intercept the data processing steps using the type system below.
        guard
            let baseDict = try JSONSerialization.jsonObject(with: baseData)
                as? [String: Any],
            let updateDict = try JSONSerialization.jsonObject(with: updateData)
                as? [String: Any]
        else {
            throw ComposeError.mergeError("Fail to convert compose to dict.")
        }

        let resultDict = baseDict.deepMerging(with: updateDict)

        let mergedData = try JSONSerialization.data(withJSONObject: resultDict)
        return try decoder.decode(Self.self, from: mergedData)
    }

    static func fromDictionary(_ dictionary: [String: Any]) throws -> Self {
        let data = try JSONSerialization.data(
            withJSONObject: dictionary,
            options: []
        )
        return try JSONDecoder().decode(Self.self, from: data)
    }

    static func fromArray(_ array: [Any]) throws -> [Self] {
        let data = try JSONSerialization.data(
            withJSONObject: array,
            options: []
        )
        return try JSONDecoder().decode([Self].self, from: data)
    }

    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: [])
            as? [String: Any]
    }

    func toDictionaryArray() throws -> [[String: Any]]? {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: [])
            as? [[String: Any]]
    }

}

extension Dictionary where Key == String, Value == Any {
    func deepMerging(with update: [String: Any], upperLevelKey: String? = nil)
        -> [String: Any]
    {
        var result = self
        let tags = update["tags"] as? [String: ComposeTag?] ?? [:]
        print("tags: ", tags)

        for (key, newValue) in update {
            if key == "tags" {
                continue
            }

            let tag: ComposeTag? = tags[key] ?? nil
            if let tag {
                switch tag {
                case .override:
                    result[key] = newValue
                    
                case .reset:
                    if newValue is NSNull {
                        let currentValue = result[key]
                        switch currentValue {
                        case is Bool:
                            result[key] = false
                        case is Int:
                            result[key] = 0
                        case is Double:
                            result[key] = 0.0
                        case is String:
                            result[key] = ""
                        case is Dictionary:
                            result[key] = [:]
                        case is Array<Any>:
                            result[key] = []
                        default:
                            result[key] = nil
                        }
                    } else {
                        // A valid value for attribute must be provided,
                        // but will be ignored and target attribute will be set with type's default value or null.
                        result[key] = newValue
                        switch newValue {
                        case is Bool:
                            result[key] = false
                        case is Int:
                            result[key] = 0
                        case is Double:
                            result[key] = 0.0
                        case is String:
                            result[key] = ""
                        case is Dictionary:
                            result[key] = [:]
                        case is Array<Any>:
                            result[key] = []
                        default:
                            result[key] = nil
                        }
                    }
                    
                }
                continue
            }

            if newValue is NSNull { continue }

            // When merging Compose files that use the services attributes command, entrypoint and healthcheck: test, the value is overridden by the latest Compose file, and not appended.
            if ["command", "entrypoint"].contains(key) {
                result[key] = newValue
                continue
            }
            if key == "test", upperLevelKey == "healthcheck" {
                result[key] = newValue
                continue
            }

            // Priority 2: Recursive dictionary deep merge
            if let oldDict = result[key] as? [String: Any],
                let newDict = newValue as? [String: Any]
            {
                result[key] = oldDict.deepMerging(
                    with: newDict,
                    upperLevelKey: key
                )
            }

            // Priority 3: Default Docker Compose YAML Sequence Merge (Appends arrays)
            else if let oldArray = result[key] as? [Any],
                let newArray = newValue as? [Any]
            {
                // Unique resources
                // Applies to the ports, volumes, secrets and configs services attributes. While these types are modeled in a Compose file as a sequence, they have special uniqueness requirements:
                // Attribute    Unique key
                // volumes    target
                // secrets    target
                // configs    target
                // ports    {ip, target, published, protocol}

                // upperLevelKey != nil -> volumes under services instead of top level volume
                if key == "volumes", upperLevelKey != nil {
                    if let oldVolume = try? Service.Volume.fromArray(
                        oldArray
                    ),
                        let newVolume = try? Service.Volume.fromArray(
                            newArray
                        ),
                        let merged = try? oldVolume.merge(with: newVolume)
                            .toDictionaryArray()
                    {
                        result[key] = merged
                        continue
                    }
                }

                if key == "secrets", upperLevelKey != nil {
                    if let old = try? Service.Secret.fromArray(
                        oldArray
                    ),
                        let new = try? Service.Secret.fromArray(
                            newArray
                        ),
                        let merged = try? old.merge(with: new)
                            .toDictionaryArray()
                    {
                        result[key] = merged
                        continue
                    }
                }

                if key == "configs", upperLevelKey != nil {
                    if let old = try? Service.Config.fromArray(
                        oldArray
                    ),
                        let new = try? Service.Config.fromArray(
                            newArray
                        ),
                        let merged = try? old.merge(with: new)
                            .toDictionaryArray()
                    {
                        result[key] = merged
                        continue
                    }
                }

                if key == "ports", upperLevelKey != nil {
                    if let old = try? Service.Port.fromArray(
                        oldArray
                    ),
                        let new = try? Service.Port.fromArray(
                            newArray
                        ),
                        let merged = try? old.merge(with: new)
                            .toDictionaryArray()
                    {
                        result[key] = merged
                        continue
                    }
                }

                result[key] = oldArray + newArray
            }
            // Priority 4: Standard primitive overwrite
            else {
                result[key] = newValue
            }
        }
        return result
    }
}
