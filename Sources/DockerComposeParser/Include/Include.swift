//
//  IncludeEntry.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Playgrounds
import Yams

/// A single entry in the top-level `include` element, referencing another
/// Compose file (or files) to be loaded and merged into this Compose
/// application's model.
///
/// Accepts both forms defined by the Compose spec:
///
/// Short syntax — a bare path to a single Compose file:
/// ```yaml
/// include:
///   - ../commons/compose.yaml
/// ```
///
/// Long syntax — an object with `path` (required; a single path or a list of
/// paths to merge), and optional `project_directory` / `env_file`:
/// ```yaml
/// include:
///   - path: ../commons/compose.yaml
///     project_directory: ..
///     env_file: ../another/.env
/// ```
public struct Include: Codable, Hashable {
    /// Path(s) to the Compose file(s) to be parsed and included into the local
    /// Compose model. Normalized to a list even when written as a single string.
    /// When more than one path is given, those files are merged together to
    /// define the included Compose model.
    public var path: [String]

    /// Base path used to resolve relative paths set in the included Compose
    /// file. Defaults to the directory of the included Compose file when omitted.
    public var project_directory: String?

    /// Environment file(s) providing default values when interpolating
    /// variables in the included Compose file. Normalized to a list even when
    /// written as a single string. Defaults to `.env` in `project_directory`
    /// when omitted. The local project's environment takes precedence over
    /// these values.
    public var env_file: [String]?

    // key : tag
    public var tags: [String: ComposeTag?] = [:]

    public init(
        path: [String],
        project_directory: String? = nil,
        env_file: [String]? = nil
    ) {
        self.path = path
        self.project_directory = project_directory
        self.env_file = env_file
    }
}

extension Include: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        // Short syntax: the entry is just a bare path string.
        if let string = try node.string(envs: envs) {
            self.path = [string]
            self.tags[CodingKeys.path.stringValue] = node.composeTag
            project_directory = nil
            env_file = nil
            return
        }

        // `path` as a list of strings.
        // include:
        // - ../commons/compose.yaml
        // - ../another_domain/compose.yaml
        if !node.array(of: String.self).isEmpty {
            self.path = try node.array(of: String.self, envs: envs)
            self.tags[CodingKeys.path.stringValue] = node.composeTag
            project_directory = nil
            env_file = nil
            return
        }

        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        guard let pathValue = try? mapping.value(for: CodingKeys.path) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.path],
                    debugDescription:
                        "Include entry must have a 'path' specified."
                )
            )
        }

        // two syntax supported:
        // include:
        // - path:
        //     - ../commons/compose.yaml
        //     - ./commons-override.yaml
        // or
        // include:
        // - path: ../another/compose.yaml
        self.path = try pathValue.array(envs: envs)
        self.tags[CodingKeys.path.stringValue] = pathValue.composeTag

        // `try?` act as decodeIfPresent
        self.project_directory = try? mapping.value(
            for: CodingKeys.project_directory
        ).string(envs: envs)
        self.tags[CodingKeys.project_directory.stringValue] =
            mapping.composeTag(for: CodingKeys.project_directory)

        let envValue = try? mapping.value(for: CodingKeys.env_file)
        // two syntax supported:
        // include:
        // - path: ../another/compose.yaml
        //   env_file:
        //     - ../another/.env
        //     - ../another/dev.env
        // or
        // include:
        // - path: ../commons/compose.yaml
        //   project_directory: ..
        //   env_file: ../another/.env
        self.env_file = try envValue?.array(envs: envs)
        self.tags[CodingKeys.env_file.stringValue] = envValue?.composeTag

    }
}

extension Include {
    // Project directory is to be used for resolving any relative path contained within the included compose file.
    // ie: the env_file property should NOT be resolved based on this
    private func resolveProjectDirectoryURL(overrideComposeDirectory: URL)
        -> URL?
    {
        if let projectDirectory = self.project_directory {
            return URL(
                filePath: projectDirectory,
                relativeTo: overrideComposeDirectory
            )
        }

        guard let first = self.path.first else {
            return nil
        }

        return URL(filePath: first, relativeTo: overrideComposeDirectory)
            .deletingLastPathComponent()
    }

    func resolve(
        overrideComposeDirectory: URL,
        overrideCompose: DockerCompose,
        overrideEnvs: [String: String]
    ) throws
        -> [ResolvedCompose]
    {
        guard
            let baseURL = self.resolveProjectDirectoryURL(
                overrideComposeDirectory: overrideComposeDirectory
            )
        else {
            throw ComposeError.failToResolveProjectURL
        }

        var envFiles = (self.env_file ?? []).map {
            // the override compose (main compose) directory instead of the project directory defined by base URL
            URL(filePath: $0, relativeTo: overrideComposeDirectory)
        }

        if envFiles.isEmpty {
            // It defaults to .env file in the project_directory for the Compose file being parsed.
            envFiles.append(URL(filePath: ".env", relativeTo: baseURL))
        }

        envFiles = envFiles.filter({
            FileManager.default.fileExists(atPath: $0.path())
        })

        var envs: [[String: String]] = try envFiles.map({
            try Utility.loadEnvFile($0)
        })
        // overrideEnvs comes last for the highest priority
        envs.append(overrideEnvs)
        var resolvedEnvs: [String: String] = envs.first ?? [:]
        for env in envs.dropFirst() {
            // NOTE: not using deepMerging as we already knew the value is a String
            resolvedEnvs = resolvedEnvs.merging(env) { (current, new) in new }
        }

        let includePaths = self.path.map {
            URL(
                filePath: $0,
                relativeTo: baseURL
            )
        }

        let composes = try includePaths.map({
            return try DockerCompose(
                url: $0,
                envs: resolvedEnvs,
//                projectDirectory: baseURL
            ).merged(
                with: overrideCompose
            )
        })

        return composes.map({
            ResolvedCompose(
                compose: $0,
                envs: resolvedEnvs,
                projectDirectoryURL: baseURL
            )
        })
    }

}

// no need to deepMerge the full thing here because we only want to apply updates on individual services, volume, and etc only if they are present in the overrideCompose.
//            var compose = try DockerCompose(url: $0, envs: resolvedEnvs)
//            let composeServices = compose.services
//            for (name, overrideService) in overrideCompose.services {
//                guard composeServices.contains(where: { $0.key == name }) else {
//                    continue
//                }
//                if let currentService = composeServices[name] {
//                    let merged = try currentService.deepMerge(with: overrideService)
//                    compose.services[name] = merged
//                } else {
//                    compose.services[name] = overrideService
//                }
//            }
//
//            let composeVolume = compose.volumes
//            for (name, overrideVolume) in overrideCompose.volumes ?? [:]  {
//                guard composeVolume.contains(where: { $0.key == name }) else {
//                    continue
//                }
//                if let currentService = composeServices[name] {
//                    let merged = try currentService.deepMerge(with: overrideService)
//                    compose.services[name] = merged
//                } else {
//                    compose.services[name] = overrideService
//                }
//            }
//
//            let composeModels = compose.models
//            for (name, service) in overrideCompose.models ?? [:] {
//                guard composeServices.contains(where: { $0.key == name }) else {
//                    continue
//                }
//                if let currentService = composeServices[name] {
//                    let merged = try currentService.deepMerge(with: overrideService)
//                    compose.services[name] = merged
//                } else {
//                    compose.services[name] = overrideService
//                }
//
//            }
//
//            for (name, service) in overrideCompose.networks ?? [:] {
//
//            }
//
//            for (name, service) in overrideCompose.configs ?? [:] {
//
//            }
//
//            for (name, service) in overrideCompose.secrets ?? [:] {
//
//            }

//
//extension Dictionary where Key == String, Value == Service {
//    func deepMerge(with update: [String: Service]) -> [String: Service] {
//        for (name, overrideService) in overrideCompose.services {
//            guard composeServices.contains(where: { $0.key == name }) else {
//                continue
//            }
//            if let currentService = composeServices[name] {
//                let merged = try currentService.deepMerge(with: overrideService)
//                compose.services[name] = merged
//            } else {
//                compose.services[name] = overrideService
//            }
//        }
//
//
//    }
//}
