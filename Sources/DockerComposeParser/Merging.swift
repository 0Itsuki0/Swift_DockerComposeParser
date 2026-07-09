//
//  Merging.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//

import Foundation
import Yams

extension Encodable where Self: Decodable {
    public func deepMerge(with update: Self)
        throws -> Self
    {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // This structural map is now ONLY used as a structural topology template,
        // because we intercept the data processing steps using the type system below.
        guard
            let baseDict = try self.toDictionary(),
            let updateDict = try update.toDictionary()
        else {
            throw ComposeError.mergeError("Fail to convert compose to dict.")
        }
        print("updateDict", updateDict)

        let resultDict = baseDict.deepMerge(with: updateDict)

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
    func deepMerge(with update: [String: Any], upperLevelKey: String? = nil)
        -> [String: Any]
    {
        var result = self

        // NOTE: direct casting to [String: ComposeTag?] will fail
        let tags = ((update["tags"] as? [String: String?]) ?? [:]).mapValues({
            string in
            if let string {
                return ComposeTag(rawValue: string)
            }
            return nil
        }).filter({ $0.value != nil })
        print("Tags: \(tags) for update \(update.keys)")

        // Process tags first because JSON.serialization will drop null (new value) automatically, and loop through the update won't resolve the tags for those keys as they are not present.
        for (key, tag) in tags {
            guard let tag else { continue }
            let newValue = update[key]
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
                    case is [Any]:
                        result[key] = []
                    default:
                        result[key] = nil
                    }
                } else {
                    // Per docker compose documentation:
                    // A valid value for attribute must be provided,
                    // but will be ignored and target attribute will be set with type's default value or null.
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
                    case is [Any]:
                        result[key] = []
                    default:
                        result[key] = nil
                    }
                }
            }
        }

        for (key, newValue) in update {
            if key == "tags" { continue }
            if tags.keys.contains(key) { continue }

            // new value undefined, keep the current
            if newValue is NSNull {
                continue
            }

            // current value undefined: basic assignment
            if result[key] is NSNull {
                result[key] = newValue
                continue
            }

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
                result[key] = oldDict.deepMerge(
                    with: newDict,
                    upperLevelKey: key
                )
                continue
            }

            // Priority 3: Default Docker Compose YAML Sequence Merge (Appends arrays)
            if let oldArray = result[key] as? [Any],
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

                continue
            }

            // Priority 4: Standard primitive overwrite
            result[key] = newValue
        }

        return result
    }
}
