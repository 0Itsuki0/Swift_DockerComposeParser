//
//  Build.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Yams

/// Represents the `build` configuration for a service.
extension Service {
    public struct Build: Codable, Hashable {
        /// Path to the build context
        public var context: String
        /// Optional path to the Dockerfile within the context
        public var dockerfile: String?
        /// Inline Dockerfile content (alternative to a Dockerfile on disk)
        public var dockerfile_inline: String?
        /// Build arguments
        /// optional value to handle reset
        public var args: [String: String?]?
        /// Additional named build contexts
        public var additional_contexts: [String: String?]?
        /// Images to consider as cache sources
        public var cache_from: [CacheEntry]?
        /// Cache export destinations
        public var cache_to: [CacheEntry]?
        /// Extra hosts to add at build time
        public var extra_hosts: [String: String?]?
        /// Isolation technology for the build container (e.g. 'default', 'process', 'hyperv')
        public var isolation: String?
        /// Metadata labels for the resulting image
        public var labels: [String: String?]?
        /// Network mode the build container uses ('none', 'host', or a network name)
        public var network: String?
        /// Disable build cache usage
        public var no_cache: Bool?
        /// Target platforms for the build
        public var platforms: [String]?
        /// Run the build container in privileged mode
        public var privileged: Bool?
        /// Always attempt to pull a newer version of the image
        public var pull: Bool?
        /// Secrets exposed to the build
        public var secrets: [Service.Secret?]?
        /// Size of /dev/shm for the build container
        public var shm_size: String?
        /// Target build stage to build
        public var target: String?
        /// SSH agent sockets or keys to expose to the build
        public var ssh: [String]?
        /// Ulimit overrides for the build container
        public var ulimits: [String: Service.Ulimit?]?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            context: String,
            dockerfile: String? = nil,
            dockerfile_inline: String? = nil,
            args: [String: String?]? = nil,
            additional_contexts: [String: String?]? = nil,
            cache_from: [CacheEntry]? = nil,
            cache_to: [CacheEntry]? = nil,
            extra_hosts: [String: String?]? = nil,
            isolation: String? = nil,
            labels: [String: String?]? = nil,
            network: String? = nil,
            no_cache: Bool? = nil,
            platforms: [String]? = nil,
            privileged: Bool? = nil,
            pull: Bool? = nil,
            secrets: [Service.Secret?]? = nil,
            shm_size: String? = nil,
            target: String? = nil,
            ssh: [String]? = nil,
            ulimits: [String: Service.Ulimit?]? = nil,
        ) {
            self.context = context
            self.dockerfile = dockerfile
            self.dockerfile_inline = dockerfile_inline
            self.args = args
            self.additional_contexts = additional_contexts
            self.cache_from = cache_from
            self.cache_to = cache_to
            self.extra_hosts = extra_hosts
            self.isolation = isolation
            self.labels = labels
            self.network = network
            self.no_cache = no_cache
            self.platforms = platforms
            self.privileged = privileged
            self.pull = pull
            self.secrets = secrets
            self.shm_size = shm_size
            self.target = target
            self.ssh = ssh
            self.ulimits = ulimits
        }
    }
}

extension Service.Build: NodeConvertible {

    // Custom initializer to handle `build: .` (string) or `build: { context: . }` (object)
    public init(_ node: Node, envs: [String: String]) throws {
        if let contextString = try node.string(envs: envs) {
            self.context = contextString
            self.tags[CodingKeys.context.stringValue] = node.composeTag
            self.dockerfile = nil
            self.dockerfile_inline = nil
            self.args = nil
            self.additional_contexts = nil
            self.cache_from = nil
            self.cache_to = nil
            self.extra_hosts = nil
            self.isolation = nil
            self.labels = nil
            self.network = nil
            self.no_cache = nil
            self.platforms = nil
            self.privileged = nil
            self.pull = nil
            self.secrets = nil
            self.shm_size = nil
            self.target = nil
            self.ssh = nil
            self.ulimits = nil
            return
        }

        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid yaml data. Expected a string or a mapping."
                )
            )
        }

        guard
            let context = try mapping.value(for: CodingKeys.context).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.context],
                    debugDescription:
                        "Build entry must have a 'context' specified."
                )
            )
        }
        self.context = context
        self.tags[CodingKeys.context.stringValue] = mapping.composeTag(
            for: CodingKeys.context
        )

        self.dockerfile = try? mapping.value(for: CodingKeys.dockerfile).string(
            envs: envs
        )
        self.tags[CodingKeys.dockerfile.stringValue] = mapping.composeTag(
            for: CodingKeys.dockerfile
        )

        self.dockerfile_inline = try? mapping.value(
            for: CodingKeys.dockerfile_inline
        ).string(envs: envs)
        self.tags[CodingKeys.dockerfile_inline.stringValue] =
            mapping.composeTag(
                for: CodingKeys.dockerfile_inline
            )

        self.args = try? mapping.value(for: CodingKeys.args).dictionary(
            envs: envs,
            isEnv: true
        )
        self.tags[CodingKeys.args.stringValue] = mapping.composeTag(
            for: CodingKeys.args
        )

        self.additional_contexts = try? mapping.value(
            for: CodingKeys.additional_contexts
        ).dictionary(envs: envs)
        self.tags[CodingKeys.additional_contexts.stringValue] =
            mapping.composeTag(
                for: CodingKeys.additional_contexts
            )

        self.cache_from = try? mapping.value(for: CodingKeys.cache_from).array(
            of: CacheEntry.self,
            envs: envs
        )
        self.tags[CodingKeys.cache_from.stringValue] = mapping.composeTag(
            for: CodingKeys.cache_from
        )

        self.cache_to = try? mapping.value(for: CodingKeys.cache_to).array(
            of: CacheEntry.self,
            envs: envs
        )
        self.tags[CodingKeys.cache_to.stringValue] = mapping.composeTag(
            for: CodingKeys.cache_to
        )

        self.extra_hosts = try? mapping.value(for: CodingKeys.extra_hosts)
            .dictionary(envs: envs)
        self.tags[CodingKeys.extra_hosts.stringValue] = mapping.composeTag(
            for: CodingKeys.extra_hosts
        )

        self.isolation = try? mapping.value(for: CodingKeys.isolation).string(
            envs: envs
        )
        self.tags[CodingKeys.isolation.stringValue] = mapping.composeTag(
            for: CodingKeys.isolation
        )

        self.labels = try? mapping.value(for: CodingKeys.labels).dictionary(
            envs: envs
        )
        self.tags[CodingKeys.labels.stringValue] = mapping.composeTag(
            for: CodingKeys.labels
        )

        self.network = try? mapping.value(for: CodingKeys.network).string(
            envs: envs
        )
        self.tags[CodingKeys.network.stringValue] = mapping.composeTag(
            for: CodingKeys.network
        )

        self.no_cache = try? mapping.value(for: CodingKeys.no_cache).bool
        self.tags[CodingKeys.no_cache.stringValue] = mapping.composeTag(
            for: CodingKeys.no_cache
        )

        self.platforms = try? mapping.value(for: CodingKeys.platforms).array(
            of: String.self,
            envs: envs
        )
        self.tags[CodingKeys.platforms.stringValue] = mapping.composeTag(
            for: CodingKeys.platforms
        )

        self.privileged = try? mapping.value(for: CodingKeys.privileged).bool
        self.tags[CodingKeys.privileged.stringValue] = mapping.composeTag(
            for: CodingKeys.privileged
        )

        self.pull = try? mapping.value(for: CodingKeys.pull).bool
        self.tags[CodingKeys.pull.stringValue] = mapping.composeTag(
            for: CodingKeys.pull
        )

        self.secrets = try? mapping.value(for: CodingKeys.secrets).array(
            envs: envs
        )
        self.tags[CodingKeys.secrets.stringValue] = mapping.composeTag(
            for: CodingKeys.secrets
        )

        self.shm_size = try? mapping.value(for: CodingKeys.shm_size).string(
            envs: envs
        )
        self.tags[CodingKeys.shm_size.stringValue] = mapping.composeTag(
            for: CodingKeys.shm_size
        )

        self.target = try? mapping.value(for: CodingKeys.target).string(
            envs: envs
        )
        self.tags[CodingKeys.target.stringValue] = mapping.composeTag(
            for: CodingKeys.target
        )

        self.ssh = try? mapping.value(for: CodingKeys.ssh).array(
            of: String.self,
            envs: envs
        )
        self.tags[CodingKeys.ssh.stringValue] = mapping.composeTag(
            for: CodingKeys.ssh
        )

        self.ulimits = try? mapping.value(for: CodingKeys.ulimits).dictionary(
            envs: envs,
            transformMap: { key, value in
                return try Service.Ulimit(value, envs: envs)
            },
            transformArray: { stringArray in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.ulimits],
                        debugDescription:
                            "Invalid yaml data. Expected a mapping or a single value."
                    )
                )
            }
        )

        self.tags[CodingKeys.ulimits.stringValue] = mapping.composeTag(
            for: CodingKeys.ulimits
        )

    }
}

extension Service.Build {

    /// A single `cache_from`/`cache_to` entry.
    ///
    /// Syntax: `[NAME|type=TYPE[,KEY=VALUE...]]`
    /// A bare `NAME` is shorthand for `type=registry,ref=NAME`.
    /// https://docs.docker.com/reference/compose-file/build/#cache_from
    /// NOTE: no tags since it will be an array resolved from Build
    public struct CacheEntry: Codable, Hashable {
        /// Cache backend type, e.g. "registry", "gha", "local", "s3".
        public var type: String
        /// Remaining `key=value` attributes for the given type (e.g. "ref", "mode").
        public var options: [String: String]

        public init(type: String, options: [String: String] = [:]) {
            self.type = type
            self.options = options
        }
    }
}

extension Service.Build.CacheEntry: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let raw = try node.string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid yaml data. Expected a string for cache entry."
                )
            )
        }
        self = try Self.parse(raw)
    }

    private static func parse(_ raw: String) throws -> Service.Build.CacheEntry
    {
        guard raw.contains("type=") else {
            return Service.Build.CacheEntry(
                type: "registry",
                options: ["ref": raw]
            )
        }

        let parts = raw.split(separator: ",").map(String.init).map({
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        })
        var type: String?
        var options: [String: String] = [:]

        for part in parts {
            guard let eqIndex = part.firstIndex(of: "=") else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription:
                            "Invalid cache entry component: \(part) in \(raw)"
                    )
                )
            }
            let key = String(part[..<eqIndex])
            let value = String(part[part.index(after: eqIndex)...])
            if key == "type" {
                type = value
            } else {
                options[key] = value
            }
        }

        guard let resolvedType = type, !resolvedType.isEmpty else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Cache entry missing 'type': \(raw)"
                )
            )
        }

        return Service.Build.CacheEntry(type: resolvedType, options: options)
    }
}

extension Service.Build.CacheEntry {
    func resolvePathToAbsolute(projectDirectory: URL)
        -> Service.Build.CacheEntry
    {
        var resolved = self
        guard resolved.type == "local" else {
            return resolved
        }

        var resolvedOptions: [String: String] = [:]
        for (key, value) in resolved.options {
            guard key == "src" || key == "dest" else {
                resolvedOptions[key] = value
                continue
            }
            resolvedOptions[key] = value.absolutePath(
                relativeTo: projectDirectory
            )
        }
        resolved.options = resolvedOptions
        return resolved
    }
}

extension Service.Build {
    func resolvePathToAbsolute(projectDirectory: URL) -> Service.Build {
        var resolved = self
        if Utility.isLocalPath(self.context) {
            resolved.context = resolved.context.absolutePath(
                relativeTo: projectDirectory
            )
        }

        if let additional_contexts = resolved.additional_contexts {
            resolved.additional_contexts = additional_contexts.mapValues({
                value in
                guard let value, Utility.isLocalPath(value) else {
                    return value
                }
                return value.absolutePath(relativeTo: projectDirectory)
            })
        }

        if let dockerfile = resolved.dockerfile {
            resolved.dockerfile = dockerfile.absolutePath(
                // NOTE: dockerfile is resolved against context instead of the current project directory
                relativeTo: URL(filePath: resolved.context)
            )
        }

        if let cache_to = resolved.cache_to {
            resolved.cache_to = cache_to.map({
                $0.resolvePathToAbsolute(projectDirectory: projectDirectory)
            })
        }

        if let cache_from = resolved.cache_from {
            resolved.cache_from = cache_from.map({
                $0.resolvePathToAbsolute(projectDirectory: projectDirectory)
            })
        }

        return resolved
    }
}
