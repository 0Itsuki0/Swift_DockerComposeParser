//
//  DockerCompose.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/05.
//

import Foundation
import Yams

public struct DockerCompose: Codable {
    /// The Compose file format version (e.g., '3.8')
    public var version: String?
    /// Optional project name
    public var name: String?

    /// Other Compose files (or groups of files) to load and merge into this
    /// Compose application's model. Accepts both the short syntax (a bare
    /// path per entry) and the long syntax (`path`/`project_directory`/`env_file`)
    /// per the Compose spec.
    /// https://docs.docker.com/reference/compose-file/include/
    public var include: [Include]?

    /// AI models that are used by the Compose application
    /// https://docs.docker.com/reference/compose-file/models/
    public var models: [String: DockerComposeParser.Model?]?

    /// Dictionary of service definitions, keyed by service name
    public var services: [String: Service?]

    /// Optional top-level volume definitions
    public var volumes: [String: DockerComposeParser.Volume?]?
    /// Optional top-level network definitions
    public var networks: [String: DockerComposeParser.Network?]?
    /// Optional top-level config definitions (primarily for Swarm)
    public var configs: [String: DockerComposeParser.Config?]?
    /// Optional top-level secret definitions (primarily for Swarm)
    public var secrets: [String: DockerComposeParser.Secret?]?

    // envs: environment variables read from .env file (or any --env-file specified by the user)
    // projectDirectory: used for resolving relative paths within the compose file
    // if not specified, default to the folder containing the compose file
    public init(url: URL, envs: [String: String], projectDirectory: URL?) throws
    {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ComposeError.fileNotFound
        }
        let yamlData = try Data(contentsOf: url)
        try self.init(
            data: yamlData,
            envs: envs,
            projectDirectory: projectDirectory
        )
    }

    public init(data: Data, envs: [String: String], projectDirectory: URL?)
        throws
    {
        guard let dockerComposeString = String(data: data, encoding: .utf8)
        else {
            throw ComposeError.invalidFileData
        }
        try self.init(
            string: dockerComposeString,
            envs: envs,
            projectDirectory: projectDirectory
        )

    }

    public init(string: String, envs: [String: String], projectDirectory: URL?)
        throws
    {
        guard let node = try Yams.compose(yaml: string) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Data is not valid YAML."
                )
            )
        }
        self = try DockerCompose(node, envs: envs)
    }

    init(
        version: String? = nil,
        name: String? = nil,
        include: [Include]? = nil,
        models: [String: DockerComposeParser.Model?]? = nil,
        services: [String: Service?],
        volumes: [String: DockerComposeParser.Volume?]? = nil,
        networks: [String: DockerComposeParser.Network?]? = nil,
        configs: [String: DockerComposeParser.Config?]? = nil,
        secrets: [String: DockerComposeParser.Secret?]? = nil
    ) {
        self.version = version
        self.name = name
        self.include = include
        self.models = models
        self.services = services
        self.volumes = volumes
        self.networks = networks
        self.configs = configs
        self.secrets = secrets
    }

    public func merged(with update: DockerCompose) throws -> DockerCompose {
        return try self.deepMerge(with: update)
    }

    // returning: included compose to be built, after applying any override applied by the base (main)
    public func resolveIncludes(composeDirectory: URL, envs: [String: String])
        throws
        -> [ResolvedCompose]
    {
        var resolvedComposes: [ResolvedCompose] = try (self.include ?? [])
            .flatMap({
                try $0.resolve(
                    overrideComposeDirectory: composeDirectory,
                    overrideCompose: self,
                    overrideEnvs: envs
                )
            })

        // loop through resolvedComposes for nested includes
        for compose in resolvedComposes {
            let nestedResult = try compose.compose.resolveIncludes(
                composeDirectory: compose.projectDirectoryURL,
                envs: envs
            )
            resolvedComposes.append(contentsOf: nestedResult)
        }

        // check unique
        try Utility.checkIncludeUniqueness(resolvedComposes.map(\.compose))
        return resolvedComposes
    }

    public func resolveExtends(composeDirectory: URL) {
        //        self.services.ser
    }

    // NOTE: not resolving for include here as it will be handled individually to resolve for a full Compose
    mutating func resolvePathToAbsolute(projectDirectory: URL) {
        self.services = self.services.mapValues({
            $0?.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })
        self.configs = self.configs?.mapValues({
            $0?.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })

        self.secrets = self.secrets?.mapValues({
            $0?.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })
    }
}

//extension Array where Element == Dictionary<String, Any> {
//    func allKeyUnique() -> Bool {
//        let names: Set<String> = Set(self.flatMap(\.keys))
//        return names.count == self.count
//    }
//}

extension DockerCompose: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.version = try? mapping.value(for: CodingKeys.version).string(
            envs: envs
        )
        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)

        // `services` is required.
        let serviceNode = try mapping.value(for: CodingKeys.services)
        self.services = try serviceNode.dictionary(
            type: Service?.self,
            envs: envs,
            transformMap: { _, value in
                return try? Service(value, envs: envs)
            },
            transformArray: { _ in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.services],
                        debugDescription:
                            "Invalid compose yaml. Services must be a mapping."
                    )
                )
            }
        )

        // `include` accepts either a single entry or a list of entries, each of
        // which may itself be the short (bare path) or long (object) syntax.
        let includeNode = try? mapping.value(for: CodingKeys.include)
        if let includeList = try? includeNode?.array(
            of: Include.self,
            envs: envs
        ),
            !includeList.isEmpty
        {
            self.include = includeList
        } else if let includeNode,
            let single = try? Include(includeNode, envs: envs)
        {
            self.include = [single]
        } else {
            self.include = nil
        }

        self.models = try? mapping.value(for: CodingKeys.models).dictionary(
            envs: envs,
            transformMap: { _, value in
                return try? Model(value, envs: envs)
            },
            transformArray: { _ in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.services],
                        debugDescription:
                            "Invalid compose yaml. Models must be a mapping."
                    )
                )
            }
        )

        self.volumes = try? mapping.value(for: CodingKeys.volumes).dictionary(
            envs: envs,
            transformMap: { _, value in
                return try? Volume(value, envs: envs)
            },
            transformArray: { _ in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.volumes],
                        debugDescription:
                            "Invalid compose yaml. volumes must be a mapping."
                    )
                )
            }
        )

        self.networks = try? mapping.value(for: CodingKeys.networks).dictionary(
            envs: envs,
            transformMap: { _, value in
                return try? Network(value, envs: envs)
            },
            transformArray: { _ in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.networks],
                        debugDescription:
                            "Invalid compose yaml. Networks must be a mapping."
                    )
                )
            }
        )

        self.configs = try? mapping.value(for: CodingKeys.configs).dictionary(
            envs: envs,
            transformMap: { _, value in
                return try? Config(value, envs: envs)
            },
            transformArray: { _ in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.configs],
                        debugDescription:
                            "Invalid compose yaml. Config must be a mapping."
                    )
                )
            }
        )

        self.secrets = try? mapping.value(for: CodingKeys.secrets).dictionary(
            envs: envs,
            transformMap: { _, value in
                return try? Secret(value, envs: envs)
            },
            transformArray: { _ in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.secrets],
                        debugDescription:
                            "Invalid compose yaml. Secrets must be a mapping."
                    )
                )
            }
        )
    }
}

public struct ResolvedCompose: Codable {
    public var compose: DockerCompose
    public var envs: [String: String]
    public var projectDirectoryURL: URL
}

enum ComposeError: Error, LocalizedError {
    case envFailToResolve(String?)
    case mergeError(String?)
    case fileNotFound
    case invalidFileData
    case invalidInclude(String?)
    case invalidExtends(String?)
    case failToResolveVar(String?)
    case failToResolveProjectURL

    var errorDescription: String? {
        switch self {
        case .failToResolveProjectURL:
            return "Fail to resolve project url for the included compose file."
        case .envFailToResolve(let message):
            return "Environment variables cannot be resolved. \(message ?? "")"
        case .mergeError(let message):
            return "Error merging composes. \(message ?? "")"
        case .fileNotFound:
            return "Compose file not found"
        case .invalidExtends(let message):
            return "Invalid extends attributes in service. \(message ?? "")"
        case .invalidFileData:
            return "Invalid compose file data"
        case .invalidInclude(let message):
            return "Invalid includes attributes. \(message ?? "")"
        case .failToResolveVar(let message):
            return "Fail to resolve variable. \(message ?? "")"
        }
    }
}
