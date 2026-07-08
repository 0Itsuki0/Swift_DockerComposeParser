//
//  Utility.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//

import Foundation
import Playgrounds
import Yams

extension Array where Element == String {
    var allUnique: Bool {
        Set(self).count == count
    }
}

extension Array where Element == [String: Any] {
    var allKeyUnique: Bool {
        Set(self.flatMap(\.keys)).count == count
    }
}

public enum Utility {

    public static func checkIncludeUniqueness(_ compose: [DockerCompose]) throws
    {

        if !compose.compactMap(\.services).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate service name found")
        }
        if !compose.compactMap(\.configs).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate configs name found")
        }
        if !compose.compactMap(\.volumes).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate volumes name found")
        }
        if !compose.compactMap(\.secrets).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate secrets name found")
        }
        if !compose.compactMap(\.models).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate models name found")
        }
        if !compose.compactMap(\.services).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate service name found")
        }
        if !compose.compactMap(\.configs).allKeyUnique {
            throw ComposeError.invalidInclude("Duplicate configs name found")
        }
        if !compose.compactMap(\.networks).allKeyUnique {
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
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.split(separator: "\n").map(String.init)
        return parseKeyValueList(Array(lines), isEnv: true)
    }

    // Translates a plain `KEY=value` list (as used by `annotations`, `labels`, and
    // `sysctls`) into a `[String: String]` map.
    public static func parseKeyValueList(_ entries: [String], isEnv: Bool)
        -> [String: String]
    {
        var dict: [String: String] = [:]
        for entry in entries {
            let entry = entry.replacingOccurrences(
                of: #"\s+#.*$"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !entry.isEmpty, !entry.starts(with: "#") else {
                continue
            }
            if let eqIdx = entry.firstIndex(of: "=") {
                let key = String(entry[..<eqIdx])
                let value = String(entry[entry.index(after: eqIdx)...])
                dict[key] = value
            } else {
                if isEnv {
                    dict[entry] =
                        ProcessInfo.processInfo.environment[entry] ?? ""
                } else {
                    // Unlike `parseEnvironmentList`, a
                    // bare `KEY` with no `=` is stored with an empty value rather than falling
                    // back to the host's environment, since these keys have no "inherit from host" meaning.
                    dict[entry] = ""
                }
            }
        }
        return dict

    }

    // handling properties such as `service.labels` that can accept a list of key=value, or a map of key: value.
    // labels:
    // com.example.description: "Accounting webapp"
    // com.example.department: "Finance"
    // com.example.label-with-empty-value: ""
    // or
    // labels:
    // - "com.example.description=Accounting webapp"
    // - "com.example.department=Finance"
    // - "com.example.label-with-empty-value"
//    public static func decodeKeyValuePairs(
//        _ node: Node?,
//        envs: [String: String],
//        isEnv: Bool
//    ) -> [String: String]? {
//        guard let node else {
//            return nil
//        }
//        if let asMap = try? node.dictionary(envs: envs) {
//            return asMap
//        } else if let asList = try? node.array(of: String.self, envs: envs), !asList.isEmpty
//        {
//            return Utility.parseKeyValueList(asList, isEnv: isEnv)
//        } else {
//            return nil
//        }
//    }
//    
//    // handling properties such as `service.models` that can accept a list of model names, or a map of model name -> Model options (possibly null).
//    // Example:
//    // services:
//    // short_syntax:
//    //   image: app
//    //   models:
//    //     - my_model
//    // long_syntax:
//    //   image: app
//    //   models:
//    //     my_model:
//    //       endpoint_var: MODEL_URL
//    //       model_var: MODEL
//    public static func decodeMapOrList<T>(
//        _ node: Node?,
//        type: T.Type = T.self,
//        envs: [String: String],
//        transformMap: @escaping (_ key: String, _ value: Node) -> T,
//        transformArray: @escaping ([String]) ->[String: T]?
//    ) -> [String: T]? {
//        guard let node else {
//            return nil
//        }
//        if let asMap = node.mapping {
//            var normalized: [String: T] = [:]
//            for (key, valueNode) in asMap {
//                guard let keyString = key.string else { continue }
//                normalized[keyString] = transformMap(keyString, valueNode)
//            }
//            return normalized
//        } else if let asList = try? node.array(of: String.self, envs: envs), !asList.isEmpty
//        {
//            return transformArray(asList)
//        } else {
//            return nil
//        }
//    }
//    
//
//    // handle properties such as `service.dns` that can be specified as either a single value or a list
//    // dns: 8.8.8.8
//    // dns:
//    // - 8.8.8.8
//    // - 9.9.9.9
//    public static func decodeStringOrList(
//        _ node: Node?,
//        envs: [String: String]
//    ) -> [String]? {
//        guard let node else {
//            return nil
//        }
//        if let asList = try? node.array(
//            of: String.self,
//            envs: envs
//        ),
//            !asList.isEmpty
//        {
//            return asList
//        } else if let asString = try? node.string(envs: envs)
//        {
//            return [asString]
//        } else {
//            return nil
//        }
//    }
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
        print(
            "Mapping: ",
            mapping.tag,
            mapping.style,
            mapping.mark,
            mapping.anchor
        )
        for pair in mapping {
            print(" Key: ", pair.key)
            //            print(" value", printNode(pair.value))
            print(" value", printNode(pair.value))
        }
    case .scalar(let scaler):
        print("Scaler: ", scaler)
    case .sequence(let sequence):
        print(
            "Sequence: ",
            sequence.tag,
            sequence.style,
            sequence.mark,
            sequence.anchor
        )
        for element in sequence {
            print(" Element: ", printNode(element))
        }
    }
}
