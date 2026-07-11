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

    public init(
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

    /// Load a `DockerCompose` at a given **file** URL
    /// - remote URL **not** supported
    /// - variables used within the compose will be resolved based on the `envs`
    /// - relative paths, includes, extends will **not** be resolved
    ///     - for fully resolved compose, please use `ComposeParser.loadCompose` instead.
    public init(url: URL, envs: [String: String]) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ComposeError.fileNotFound
        }
        let yamlData = try Data(contentsOf: url)
        try self.init(
            data: yamlData,
            envs: envs,
        )
    }

    /// Load a `DockerCompose` for a given data
    /// - remote URL **not** supported
    /// - variables used within the compose will be resolved based on the `envs`
    /// - relative paths, includes, extends will **not** be resolved
    ///     - for fully resolved compose, please use `ComposeParser.loadCompose` instead.
    public init(data: Data, envs: [String: String])
        throws
    {
        guard let dockerComposeString = String(data: data, encoding: .utf8)
        else {
            throw ComposeError.invalidFileData
        }
        try self.init(
            string: dockerComposeString,
            envs: envs,
        )
    }

    /// Load a `DockerCompose` for a given yaml string
    /// - remote URL **not** supported
    /// - variables used within the compose will be resolved based on the `envs`
    /// - relative paths, includes, extends will **not** be resolved
    ///     - for fully resolved compose, please use `ComposeParser.loadCompose` instead.
    public init(string: String, envs: [String: String])
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

}

extension DockerCompose: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)

        // update envs to include project name
        // Whenever a project name is defined by top-level name or by some custom mechanism,
        // it is exposed for interpolation and environment variable resolution as COMPOSE_PROJECT_NAME
        // https://docs.docker.com/reference/compose-file/version-and-name/#name-top-level-element
        var envs = envs

        if !envs.contains(where: { $0.key == Utility.projectNameVar }),
            let name = self.name
        {
            envs[Utility.projectNameVar] = name
        }

        self.version = try? mapping.value(for: CodingKeys.version).string(
            envs: envs
        )

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

extension DockerCompose {

    func resolvePathToAbsolute(projectDirectory: URL) -> DockerCompose {
        var resolved = self
        resolved.services = self.services.mapValues({
            $0?.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })
        resolved.configs = self.configs?.mapValues({
            $0?.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })

        resolved.secrets = self.secrets?.mapValues({
            $0?.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })
        resolved.include = self.include?.map({
            $0.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })
        return resolved
    }

    func loadIncludes(mainEnvs: [String: String]) throws -> [DockerCompose] {
        guard let include = self.include?.filter({ !$0.path.isEmpty }),
            !include.isEmpty
        else {
            return []
        }
        let loaded = try include.map({ try $0.load(mainEnvs: mainEnvs) })
        return loaded.flatMap({ $0 })
    }

    // helper function for removing resource from the base that are already contained in the `containedIn` compose
    func removeResources(
        containedIn compose: DockerCompose
    ) -> DockerCompose {
        var resolved = self
        resolved.models = resolved.models?.removeDuplicateKeys(
            in: compose.models ?? [:]
        )

        resolved.services = resolved.services.removeDuplicateKeys(
            in: compose.services
        )

        resolved.volumes = resolved.volumes?.removeDuplicateKeys(
            in: compose.volumes ?? [:]
        )

        resolved.networks = resolved.networks?.removeDuplicateKeys(
            in: compose.networks ?? [:]
        )

        resolved.configs = resolved.configs?.removeDuplicateKeys(
            in: compose.configs ?? [:]
        )

        resolved.secrets = resolved.secrets?.removeDuplicateKeys(
            in: compose.secrets ?? [:]
        )

        return resolved
    }

    // merge by resource key only. As oppose to deep merge looping through the nested property as well
    func simpleMerge(with compose: DockerCompose) -> DockerCompose {
        var finalCompose = self
        finalCompose.services.merge(
            compose.services,
            uniquingKeysWith: { _, new in new }
        )
        finalCompose.models?.merge(
            compose.models ?? [:],
            uniquingKeysWith: { _, new in new }
        )
        finalCompose.networks?.merge(
            compose.networks ?? [:],
            uniquingKeysWith: { _, new in new }
        )
        finalCompose.volumes?.merge(
            compose.volumes ?? [:],
            uniquingKeysWith: { _, new in new }
        )
        finalCompose.secrets?.merge(
            compose.secrets ?? [:],
            uniquingKeysWith: { _, new in new }
        )
        finalCompose.configs?.merge(
            compose.configs ?? [:],
            uniquingKeysWith: { _, new in new }
        )

        return finalCompose
    }

    func resolveServiceExtends(
        resolveInFile: (String, URL) throws -> Service,
    ) throws -> DockerCompose {
        var finalCompose = self

        for (name, service) in finalCompose.services {
            let resolvedService = try service?.resolveExtends(
                resolveInLoaded: { serviceName in
                    // assuming self.services already merged
                    guard let optional = finalCompose.services[serviceName],
                        let service = optional
                    else {
                        throw ComposeError.invalidExtends(
                            "Service: \(serviceName) not found."
                        )
                    }
                    return service
                },
                resolveInFile: { serviceName, url in
                    try resolveInFile(serviceName, url)
                }
            )

            finalCompose.services[name] = resolvedService
        }
        return finalCompose
    }

    // assume being called after merging with all includes
    func validateDependency() throws {
        let serviceWithRequiredDependOn: [String: Service?] = self.services
            .filter({ (key, value) in
                guard let depends_on = value?.depends_on, !depends_on.isEmpty
                else {
                    return false
                }
                return true
            })

        let dependedOnServices: [[(String, Bool)]] = serviceWithRequiredDependOn
            .values.map({ service in
                guard let service else {
                    return []
                }
                return service.depends_on?.map({
                    ($0.key, $0.value?.required ?? true)
                }) ?? []
            })

        var errorServices: [String] = []
        var warningServices: [String] = []
        for (service, required) in dependedOnServices.flatMap({ $0 }) {
            if self.services.keys.contains(service) {
                continue
            }
            if required {
                errorServices.append(service)
                continue
            }

            warningServices.append(service)
        }

        if !errorServices.isEmpty || !warningServices.isEmpty {
            throw ComposeError.dependencyNotFound(
                required: errorServices,
                warning: warningServices
            )
        }
    }
}
