//
//  Utility.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//

import Foundation
import Playgrounds
import Yams
import Collections

extension Array where Element == String {
    var allUnique: Bool {
        Set(self).count == count
    }
}

public enum Utility {
    public static func checkIncludeUniqueness(_ compose: [DockerCompose]) throws
    {
        
        if !compose.flatMap({$0.services.keys}).allUnique {
            throw ComposeError.invalidInclude("Duplicate service name found")
        }
        
        if !compose.flatMap({$0.configs?.keys ?? []}).allUnique {
            throw ComposeError.invalidInclude("Duplicate configs name found")
        }
        
        if !compose.flatMap({$0.volumes?.keys ?? []}).allUnique {
            throw ComposeError.invalidInclude("Duplicate volumes name found")
        }
        
        if !compose.flatMap({$0.secrets?.keys ?? []}).allUnique {
            throw ComposeError.invalidInclude("Duplicate secrets name found")
        }
        
        if !compose.flatMap({$0.models?.keys ?? []}).allUnique {
            throw ComposeError.invalidInclude("Duplicate models name found")
        }
        
        if !compose.flatMap({$0.configs?.keys ?? []}).allUnique {
            throw ComposeError.invalidInclude("Duplicate configs name found")
        }
        
        if !compose.flatMap({$0.networks?.keys ?? []}).allUnique {
            throw ComposeError.invalidInclude("Duplicate networks name found")
        }
    }

    public static func resolveVariable(
        _ value: String,
        with envVars: [String: String]
    )
        throws -> String
    {
        var resolvedValue = value
        // Regex to find ${VAR}, ${VAR:-default}, ${VAR:?error}
        let regex = try Regex(#"\$\{([A-Za-z0-9_]+)(:?-(.*?))?(:\?(.*?))?\}"#)

        // Combine process environment with loaded .env file variables, prioritizing process environment
        let combinedEnv = ProcessInfo.processInfo.environment.merging(envVars) {
            (current, _) in current
        }

        // Loop to resolve all occurrences of variables in the string
        while let match = try regex.firstMatch(in: resolvedValue) {
            guard let varNameRange = match[1].range else { break }
            let varName = String(resolvedValue[varNameRange])

            if let envValue = combinedEnv[varName] {
                // Variable found in environment, replace with its value
                resolvedValue.replaceSubrange(match.range, with: envValue)
            } else if let defaultValueRange = match[3].range {
                // Variable not found, but default value is provided, replace with default
                let defaultValue = String(resolvedValue[defaultValueRange])
                resolvedValue.replaceSubrange(match.range, with: defaultValue)
            } else if let errorMessageRange = match[5].range {
                // Variable not found, and error-on-missing syntax used, print error and exit
                let errorMessage = String(resolvedValue[errorMessageRange])
                throw ComposeError.failToResolveVar(errorMessage)
            } else {
                // Variable not found and no default/error specified, leave as is and break loop to avoid infinite loop
                throw ComposeError.failToResolveVar("Variable not found.")
            }
        }

        return resolvedValue
    }

    public static func loadEnvFile(_ fileURL: URL) throws -> [String: String] {
        var envVars: [String: String] = [:]
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.split(separator: "\n")
        for line in lines {
            let trimmedLine = line.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            // Ignore empty lines and comments
            if !trimmedLine.isEmpty && !trimmedLine.starts(with: "#") {
                // Parse key=value pairs
                if let eqIndex = trimmedLine.firstIndex(of: "=") {
                    let key = String(trimmedLine[..<eqIndex])
                    let value = String(
                        trimmedLine[trimmedLine.index(after: eqIndex)...]
                    )
                    envVars[key] = value
                }
            }
        }
        return envVars
    }
}

extension KeyedDecodingContainer {
    public func decodeIfPresent(
        _ type: [String].Type,
        forKey key: KeyedDecodingContainer<K>.Key,
        envs: [String: String]
    ) throws -> [String]? {
        let strings = try self.decodeIfPresent([String].self, forKey: key)
        guard let strings else {
            return nil
        }
        return try strings.map({ try Utility.resolveVariable($0, with: envs) })
    }

    public func decodeIfPresent(
        _ type: String.Type,
        forKey key: KeyedDecodingContainer<K>.Key,
        envs: [String: String]
    ) throws -> String? {
        let string = try self.decodeIfPresent(String.self, forKey: key)
        guard let string else {
            return nil
        }
        return try Utility.resolveVariable(string, with: envs)
    }

    public func decode(
        _ type: String.Type,
        forKey key: KeyedDecodingContainer<K>.Key,
        envs: [String: String]
    ) throws -> String {
        let string = try self.decode(String.self, forKey: key)
        return try Utility.resolveVariable(string, with: envs)
    }

    /// Decodes an attribute that the Compose spec allows to be either a duration
    /// string (e.g. `"1400us"`) or a bare integer (e.g. microseconds), always
    /// returning it normalized to a string.
    func decodeStringOrNumber(
        forKey key: KeyedDecodingContainer<K>.Key,
        envs: [String: String]
    ) throws -> String? {
        if let asString = try? self.decodeIfPresent(
            String.self,
            forKey: key,
            envs: envs
        ) {
            return asString
        } else if let asInt = try? self.decodeIfPresent(
            Int.self,
            forKey: key
        ) {
            return "\(asInt)"
        } else {
            return nil
        }
    }

    // for decoding map with order
    //    func decodeIfPresent<T: Decodable>(
    //        _ associateType: T.Type,
    //        forKey key: KeyedDecodingContainer<K>.Key,
    //        envs: [String: String]
    //    ) throws -> [(String, T)]? {
    //        guard let string = try self.decodeIfPresent(String.self, forKey: key) else {
    //            return nil
    //        }
    //        let node = try Yams.compose(yaml: string)
    //        if let pairs = node?.mapping {
    //            let orderedPairs: [(String, String)] = pairs.compactMap { keyNode, valueNode in
    //                guard let key = keyNode.string, let value = valueNode.string else { return nil }
    //                return (key, value)
    //            }
    //
    //            // Prints exactly in the order written in the YAML
    //            for (key, value) in orderedPairs {
    //                print("\(key): \(value)")
    //            }
    //        }
    //
    //
    ////        if let asString = try? self.decodeIfPresent(
    ////            String.self,
    ////            forKey: key,
    ////            envs: envs
    ////        ) {
    ////            return asString
    ////        } else if let asInt = try? self.decodeIfPresent(
    ////            Int.self,
    ////            forKey: key
    ////        ) {
    ////            return "\(asInt)"
    ////        } else {
    ////            return nil
    ////        }
    //    }
}

//extension String {
//    func calculateExpressionIfApplicable() -> String {
//        let expression = NSExpression(format: self)
//        if let result = expression.expressionValue(with: nil, context: nil)
//            as? Int
//        {
//            print("The result is: \(result)")  // Output: The result is: 8.0
//            return "\(result)"
//        } else {
//            return self
//        }
//    }
//}

extension SingleValueDecodingContainer {
    func decode(_ type: String.Type, envs: [String: String]) throws -> String {
        let string = try self.decode(String.self)
        return try Utility.resolveVariable(string, with: envs)
    }
}

extension CodingUserInfoKey {
    static let env: CodingUserInfoKey? = CodingUserInfoKey(rawValue: "env")
}

extension Decoder {
    var envs: [String: String] {
        guard let envKey = CodingUserInfoKey.env else {
            return [:]
        }
        return (userInfo[envKey] as? [String: String]) ?? [:]
    }
}

#Playground {
    let yaml = """
        services:
          first:
            image: my-image:latest
            environment: &env
              - CONFIG_KEY
              - EXAMPLE_KEY
              - DEMO_VAR
          second:
            image: another-image:latest
            environment: *env
          proxy:
            ports:
              - 80
            build: ./proxy
            networks:
              - frontend
          app:
            build: ./app
            networks:
              - frontend
              - backend
          db:
            image: postgres:18
            networks:
              - backend
        networks:
          frontend:
            # Specify driver options
            driver: bridge
            driver_opts:
              com.docker.network.bridge.host_binding_ipv4: "127.0.0.1"
          backend:
            # Use a custom driver
            driver: custom-driver
        
        volumes:
          db-data: &default-volume
            driver: default
          metrics: *default-volume
        """

    do {

        //        let yamlDecoder = YAMLDecoder()
        //        let result = try yamlDecoder.decode(String.self, from: yaml)
        //        print(result)
        //        let node = try Yams.compose(yaml: yaml)
        //        if let pairs = node?.mapping {
        ////            let orderedPairs: [(String, String)] = pairs.compactMap { keyNode, valueNode in
        ////                guard let key = keyNode.string, let value = valueNode.any else { return nil }
        ////                return (key, value)
        ////            }
        //
        //            // Prints exactly in the order written in the YAML
        //            for (key, value) in pairs {
        //                print("- \(key)")
        //            }
        //        }
        let nodes = try Yams.compose_all(yaml: yaml)
//        print(nodes.count(where: {_ in true}))
        for node in nodes {
            printNode(node)
        }
    } catch (let error) {
        print(error)
    }
}

func printNode(_ node: Node) {
    switch node {
    case .alias(let alias):
        print("Alias: ", alias)
    case .mapping(let mapping):
        print("Mapping: ", mapping.tag, mapping.style, mapping.mark, mapping.anchor)
        for pair in mapping {
            print(" Key: ", pair.key)
//            print(" value", printNode(pair.value))
            print(" value", printNode(pair.value))
        }
    case .scalar(let scaler):
        print("Scaler: ", scaler)
    case .sequence(let sequence):
        print("Sequence: ", sequence.tag, sequence.style, sequence.mark, sequence.anchor)
        for element in sequence {
            print(" Element: ", printNode(element))
        }
    }
}
