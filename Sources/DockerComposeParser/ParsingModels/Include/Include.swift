//
//  IncludeEntry.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Yams

// TODO: - Handle Remote Compose file
// https://docs.docker.com/compose/how-tos/multiple-compose-files/include/
// ex:
// include:
//   - oci://docker.io/username/my-compose-app:latest # use a Compose file stored as an OCI artifact


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
    ///
    /// paths defined here are relative to the **main** compose
    public var path: [String]

    /// Base path used to resolve relative paths set in the included Compose
    /// file.
    /// Does not effect the path above or the env_file below
    /// Defaults to the directory of the included Compose file when omitted.
    ///
    /// when defined, path Relative to the **main** compose
    /// when not defined, defaults to the directory of the included Compose files above.
    /// if multiple paths are defined, directory of the first path.
    public var project_directory: String?

    /// Environment file(s) providing default values when interpolating
    /// variables in the included Compose file. Normalized to a list even when
    /// written as a single string. Defaults to `.env` in `project_directory`
    /// when omitted. The local project's environment takes precedence over
    /// these values.
    ///
    /// paths defined here are relative to the **main** compose
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

    init(_ node: Node, envs: [String: String]) throws {
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
    func resolvePathToAbsolute(projectDirectory: URL) -> Include {
        var resolved = self
        resolved.path = resolved.path.map({
            if Utility.isLocalPath($0) {
                return $0.absolutePath(relativeTo: projectDirectory)
            }
            return $0
        })
        resolved.project_directory = resolved.project_directory?.absolutePath(
            relativeTo: projectDirectory
        )
        resolved.env_file = resolved.env_file?.map({
            $0.absolutePath(relativeTo: projectDirectory)
        })
        return resolved
    }
    
    // Project directory is to be used for resolving any relative path contained within the included compose file.
    // ie: the env_file property should NOT be resolved based on this
    // NOTE: Assume the resolvePathToAbsolute already called
    private func resolveProjectDirectoryURL()
        -> URL?
    {
        if let projectDirectory = self.project_directory {
            return URL(
                filePath: projectDirectory
            )
        }

        guard let first = self.path.first else {
            return nil
        }
        // fall back to the first path
        return URL(filePath: first).deletingLastPathComponent()
    }

    // Load included compose
    // NOTE:
    // 1. this function does NOT apply any overrides that the main compose that might have
    // 2. called after resolving all the relative URLs, ie: after calling resolvePathToAbsolute
    // 3. Not merging the included compose to a single one as they will need to go through uniqueness check as well as merge any overrides that the main compose main have
    func load(
        mainEnvs: [String: String]
    ) throws
        -> [DockerCompose]
    {
        guard
            let baseURL = self.resolveProjectDirectoryURL()
        else {
            throw ComposeError.failToResolveProjectURL
        }

        let envFiles = (self.env_file ?? []).map {
            URL(filePath: $0)
        }

        let includePaths = self.path.map {
            URL(filePath: $0)
        }

        let composes = try includePaths.map({
            // NOTE: not using  try DockerCompose(...) so that any includes/service extend within the included compose can be resolved automatically
            return try ComposeParser.loadCompose(
                $0,
                envFiles: envFiles,
                projectDirectory: baseURL,
            )
        })

        return composes
    }
}
