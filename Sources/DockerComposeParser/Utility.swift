//
//  Utility.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//

import Foundation
import Yams

public enum Utility {

    /// Resolve variables contained in a YAML string
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

    /// Load env files for a compose project
    public static func loadProjectEnvFiles(
        _ envFiles: [URL],
        projectDirectory: URL
    ) throws
        -> [String: String]
    {
        var allEnvFiles = envFiles
        guard
            allEnvFiles.allSatisfy({
                FileManager.default.fileExists(atPath: $0.path())
            })
        else {
            throw ComposeError.envFailToResolve(
                "Env files specified not found."
            )
        }

        if allEnvFiles.isEmpty {
            allEnvFiles.append(
                URL(filePath: ".env", relativeTo: projectDirectory)
            )
        }
        let envs: [[String: String]] = try allEnvFiles.filter({
            FileManager.default.fileExists(atPath: $0.path())
        }).map({
            try loadEnvFile($0)
        })

        var resolvedEnvs: [String: String] = envs.first ?? [:]
        for env in envs.dropFirst() {
            // NOTE: not using deepMerging as we already knew the value is a String
            resolvedEnvs = resolvedEnvs.merging(env) { (current, new) in new }
        }

        return resolvedEnvs
    }

    /// Load a single env file
    public static func loadEnvFile(_ fileURL: URL) throws -> [String: String] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.split(separator: "\n").map(String.init)
        return parseKeyValueList(Array(lines), isEnv: true)
    }

    /// Translates a plain `KEY=value` list (as used by `annotations`, `labels`, and `sysctls`) into a `[String: String]` map.
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

    static func isLocalPath(_ string: String) -> Bool {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Git SSH shorthand
        if string.hasPrefix("git@") {
            return false
        }

        // URL schemes
        if let url = URL(string: string),
            let scheme = url.scheme?.lowercased()
        {
            switch scheme {
            case "http", "https", "git", "ssh", "type", "docker-image", "oci":
                return false
            default:
                break
            }
        }

        if string.starts(with: "service:")
            || string.starts(with: "docker-image://")
        {
            return false
        }

        return true
    }

    // Helper function for filtering the overrideCompose to only include those resources declared within the base for applying deep merging
    static func createOverrideCompose(
        base: DockerCompose,
        overrideCompose: DockerCompose
    )
        -> DockerCompose
    {
        var finalOverride = overrideCompose
        finalOverride.include = nil

        finalOverride.services = finalOverride.services.keepDuplicateKeys(
            in: base.services
        )

        finalOverride.models = finalOverride.models?.keepDuplicateKeys(
            in: base.models ?? [:]
        )

        finalOverride.volumes = finalOverride.volumes?.keepDuplicateKeys(
            in: base.volumes ?? [:]
        )

        finalOverride.networks = finalOverride.networks?.keepDuplicateKeys(
            in: base.networks ?? [:]
        )

        finalOverride.configs = finalOverride.configs?.keepDuplicateKeys(
            in: base.configs ?? [:]
        )

        finalOverride.secrets = finalOverride.secrets?.keepDuplicateKeys(
            in: base.secrets ?? [:]
        )

        return finalOverride
    }

    static func checkIncludeUniqueness(_ compose: [DockerCompose]) throws {
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

}
