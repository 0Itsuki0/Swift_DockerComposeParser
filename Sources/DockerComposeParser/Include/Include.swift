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

    public init(from decoder: Decoder) throws {
        // Short syntax: the entry is just a bare path string.
        if let singlePath = try? decoder.singleValueContainer().decode(
            String.self
        ) {
            path = [singlePath]
            project_directory = nil
            env_file = nil
            return
        }

        // Long syntax: an object with `path`, `project_directory`, and `env_file`.
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // `path` accepts either a single string or a list of strings.
        if let pathList = try? container.decodeIfPresent(
            [String].self,
            forKey: .path
        ) {
            path = pathList
        } else if let pathString = try? container.decodeIfPresent(
            String.self,
            forKey: .path
        ) {
            path = [pathString]
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .path,
                in: container,
                debugDescription: "Include entry must have a 'path' specified."
            )
        }

        project_directory = try container.decodeIfPresent(
            String.self,
            forKey: .project_directory
        )

        // `env_file` accepts either a single string or a list of strings, same as
        // the service-level `env_file` attribute.
        if let envFileList = try? container.decodeIfPresent(
            [String].self,
            forKey: .env_file
        ) {
            env_file = envFileList
        } else if let envFileString = try? container.decodeIfPresent(
            String.self,
            forKey: .env_file
        ) {
            env_file = [envFileString]
        } else {
            env_file = nil
        }
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

    func resolve(
        composeDirectory: URL,
        overrideCompose: DockerCompose
    ) throws
        -> [ResolvedCompose]
    {
        let baseURL = URL(
            filePath: self.project_directory ?? ".",
            relativeTo: composeDirectory
        )
        let envFiles = (self.env_file ?? []).map {
            URL(filePath: $0, relativeTo: baseURL)
        }
        let envs = try envFiles.map({ try Utility.loadEnvFile($0) })
        var resolvedEnvs: [String: String] = envs.first ?? [:]
        for env in envs.dropFirst() {
            resolvedEnvs = try resolvedEnvs.deepMerge(with: env)
        }
        let includePaths = self.path.map {
            URL(
                filePath: $0,
                relativeTo: baseURL
            )
        }

        let composes = try includePaths.map({
            try DockerCompose(url: $0, envs: resolvedEnvs).merged(
                with: overrideCompose
            )
        })
        return composes.map({
            ResolvedCompose(
                compose: $0,
                envFiles: envFiles,
                contextURL: baseURL
            )
        })
    }

}
