//
//  Build.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

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
        public var cache_from: [String]?
        /// Cache export destinations
        public var cache_to: [String]?
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
            dockerfile: String?,
            dockerfile_inline: String?,
            args: [String: String]?,
            additional_contexts: [String: String]?,
            cache_from: [String]?,
            cache_to: [String]?,
            extra_hosts: [String: String]?,
            isolation: String?,
            labels: [String: String]?,
            network: String?,
            no_cache: Bool?,
            platforms: [String]?,
            privileged: Bool?,
            pull: Bool?,
            secrets: [Service.Secret]?,
            shm_size: String?,
            target: String?,
            ssh: [String]?,
            ulimits: [String: Service.Ulimit]?
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
            of: String.self,
            envs: envs
        )
        self.tags[CodingKeys.cache_from.stringValue] = mapping.composeTag(
            for: CodingKeys.cache_from
        )

        self.cache_to = try? mapping.value(for: CodingKeys.cache_to).array(
            of: String.self,
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
