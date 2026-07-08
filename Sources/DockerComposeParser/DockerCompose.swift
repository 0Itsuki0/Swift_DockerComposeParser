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
    public var models: Dictionary<String, Model?>?
    //    [String: Model?]?

    /// Dictionary of service definitions, keyed by service name
    public var services: Dictionary<String, Service?>
    //    [String: Service?]

    /// Optional top-level volume definitions
    public var volumes: Dictionary<String, DockerComposeParser.Volume?>?
    /// Optional top-level network definitions
    public var networks:
        Dictionary<String, DockerComposeParser.Network?>?
    /// Optional top-level config definitions (primarily for Swarm)
    public var configs: Dictionary<String, DockerComposeParser.Config?>?
    /// Optional top-level secret definitions (primarily for Swarm)
    public var secrets: Dictionary<String, DockerComposeParser.Secret?>?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        services = try container.decode(
            Dictionary<String, Service?>.self,
            forKey: .services
        )

        // `include` accepts either a single entry or a list of entries, each of
        // which may itself be the short (bare path) or long (object) syntax.
        if let includeList = try? container.decodeIfPresent(
            [Include].self,
            forKey: .include
        ) {
            include = includeList
        } else if let singleInclude = try? container.decodeIfPresent(
            Include.self,
            forKey: .include
        ) {
            include = [singleInclude]
        } else {
            include = nil
        }

        models = try container.decodeIfPresent(
            Dictionary<String, Model?>.self,
            forKey: .models
        )

        volumes = try container.decodeIfPresent(
            Dictionary<String, Volume?>.self,
            forKey: .volumes
        )

        networks = try container.decodeIfPresent(
            Dictionary<String, Network?>.self,
            forKey: .networks
        )
        configs = try container.decodeIfPresent(
            Dictionary<String, Config?>.self,
            forKey: .configs
        )
        secrets = try container.decodeIfPresent(
            Dictionary<String, Secret?>.self,
            forKey: .secrets
        )
    }

    // envs: environment variables read from .env file (or any --env-file specified by the user)
    public init(url: URL, envs: [String: String]) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ComposeError.fileNotFound
        }

        let yamlData = try Data(contentsOf: url)

        try self.init(data: yamlData, envs: envs)
    }

    public init(data: Data, envs: [String: String]) throws {
        guard let dockerComposeString = String(data: data, encoding: .utf8)
        else {
            throw ComposeError.invalidFileData
        }
        try self.init(string: dockerComposeString, envs: envs)

    }

    public init(string: String, envs: [String: String]) throws {
        guard let envKey = CodingUserInfoKey.env else {
            throw ComposeError.envFailToResolve(
                "CodingUserInfoKey.env is undefined."
            )
        }
        self = try YAMLDecoder().decode(
            DockerCompose.self,
            from: string,
            userInfo: [envKey: envs]
        )
    }

    public func merged(with update: DockerCompose) throws -> DockerCompose {
        return try self.deepMerge(with: update)
    }

    // returning: included compose to be built, after applying any override applied by the base (main)
    public func resolveIncludes(composeDirectory: URL)
        throws
        -> [ResolvedCompose]
    {
        var resolvedComposes: [ResolvedCompose] = try (self.include ?? [])
            .flatMap({
                try $0.resolve(
                    composeDirectory: composeDirectory,
                    overrideCompose: self
                )
            })

        // loop through resolvedComposes for nested includes
        for compose in resolvedComposes {
            let nestedResult = try compose.compose.resolveIncludes(
                composeDirectory: compose.contextURL,
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
}


//extension Array where Element == Dictionary<String, Any> {
//    func allKeyUnique() -> Bool {
//        let names: Set<String> = Set(self.flatMap(\.keys))
//        return names.count == self.count
//    }
//}

public struct ResolvedCompose: Codable {
    public var compose: DockerCompose
    public var envFiles: [URL]
    public var contextURL: URL
}

enum ComposeError: Error, LocalizedError {
    case envFailToResolve(String?)
    case mergeError(String?)
    case fileNotFound
    case invalidFileData
    case invalidInclude(String?)
    case invalidExtends(String?)
    case failToResolveVar(String?)

    var errorDescription: String? {
        switch self {
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
