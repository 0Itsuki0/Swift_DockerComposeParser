//
//  Deploy.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Represents the `deploy` configuration for a service (primarily for Swarm orchestration).
extension Service {
    public struct Deploy: Codable, Sendable, Equatable, Hashable {
        /// Endpoint mode for service discovery (e.g., 'vip', 'dnsrr')
        public var endpoint_mode: String?
        /// Metadata labels for the service
        public var labels: [String: String]?
        /// Deployment mode (e.g., 'replicated', 'global')
        public var mode: String?
        /// Placement constraints and preferences
        public var placement: DeployPlacement?
        /// Number of replicated service tasks
        public var replicas: Int?
        /// Resource constraints (limits, reservations)
        public var resources: DeployResources?
        /// Restart policy for tasks
        public var restart_policy: DeployRestartPolicy?
        /// Configuration for rolling back after a failed update
        public var rollback_config: DeployRollbackConfig?
        /// Configuration for rolling updates
        public var update_config: DeployUpdateConfig?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            endpoint_mode: String?,
            labels: [String: String]?,
            mode: String?,
            placement: DeployPlacement?,
            replicas: Int?,
            resources: DeployResources?,
            restart_policy: DeployRestartPolicy?,
            rollback_config: DeployRollbackConfig?,
            update_config: DeployUpdateConfig?
        ) {
            self.endpoint_mode = endpoint_mode
            self.labels = labels
            self.mode = mode
            self.placement = placement
            self.replicas = replicas
            self.resources = resources
            self.restart_policy = restart_policy
            self.rollback_config = rollback_config
            self.update_config = update_config
        }

    }
}

extension Service.Deploy: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.endpoint_mode = try? mapping.value(for: CodingKeys.endpoint_mode)
            .string(envs: envs)
        self.tags[CodingKeys.endpoint_mode.stringValue] = mapping.composeTag(
            for: CodingKeys.endpoint_mode
        )

        self.labels = try? mapping.value(for: CodingKeys.labels)
            .dictionary(envs: envs)
        self.tags[CodingKeys.labels.stringValue] = mapping.composeTag(
            for: CodingKeys.labels
        )

        self.mode = try? mapping.value(for: CodingKeys.mode).string(envs: envs)
        self.tags[CodingKeys.mode.stringValue] = mapping.composeTag(
            for: CodingKeys.mode
        )

        self.placement = try? Service.DeployPlacement(
            mapping.value(for: CodingKeys.placement),
            envs: envs
        )
        self.tags[CodingKeys.placement.stringValue] = mapping.composeTag(
            for: CodingKeys.placement
        )

        self.replicas = try? mapping.value(for: CodingKeys.replicas).int(
            envs: envs
        )
        self.tags[CodingKeys.replicas.stringValue] = mapping.composeTag(
            for: CodingKeys.replicas
        )

        self.resources = try? Service.DeployResources(
            mapping.value(for: CodingKeys.resources),
            envs: envs
        )
        self.tags[CodingKeys.resources.stringValue] = mapping.composeTag(
            for: CodingKeys.resources
        )

        self.restart_policy = try? Service.DeployRestartPolicy(
            mapping.value(for: CodingKeys.restart_policy),
            envs: envs
        )
        self.tags[CodingKeys.restart_policy.stringValue] = mapping.composeTag(
            for: CodingKeys.restart_policy
        )

        self.rollback_config = try? Service.DeployRollbackConfig(
            mapping.value(for: CodingKeys.rollback_config),
            envs: envs
        )
        self.tags[CodingKeys.rollback_config.stringValue] = mapping.composeTag(
            for: CodingKeys.rollback_config
        )

        self.update_config = try? Service.DeployUpdateConfig(
            mapping.value(for: CodingKeys.update_config),
            envs: envs
        )
        self.tags[CodingKeys.update_config.stringValue] = mapping.composeTag(
            for: CodingKeys.update_config
        )

    }
}

// MARK: - DeployPlacement

extension Service {
    public struct DeployPlacement: Codable, Sendable, Equatable, Hashable {
        /// List of constraints
        public var constraints: [String]?
        /// List of preferences
        public var preferences: [DeployPlacementPreference]?
        /// Maximum number of replicas per node
        public var max_replicas_per_node: Int?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            constraints: [String]?,
            preferences: [DeployPlacementPreference]?,
            max_replicas_per_node: Int?
        ) {
            self.constraints = constraints
            self.preferences = preferences
            self.max_replicas_per_node = max_replicas_per_node
        }

    }
}

extension Service.DeployPlacement: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.constraints = try? mapping.value(for: CodingKeys.constraints)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.constraints.stringValue] = mapping.composeTag(
            for: CodingKeys.constraints
        )

        self.preferences = try? mapping.value(for: CodingKeys.preferences)
            .array(envs: envs)
        self.tags[CodingKeys.preferences.stringValue] = mapping.composeTag(
            for: CodingKeys.preferences
        )

        self.max_replicas_per_node = try? mapping.value(
            for: CodingKeys.max_replicas_per_node
        ).int(envs: envs)
        self.tags[CodingKeys.max_replicas_per_node.stringValue] =
            mapping.composeTag(for: CodingKeys.max_replicas_per_node)

    }
}

// MARK: - DeployPlacementPreference

extension Service {
    public struct DeployPlacementPreference: Codable, Sendable, Equatable, Hashable {
        /// Spread placement preference
        public var spread: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(spread: String?) {
            self.spread = spread
        }

    }
}

extension Service.DeployPlacementPreference: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.spread = try? mapping.value(for: CodingKeys.spread).string(
            envs: envs
        )
        self.tags[CodingKeys.spread.stringValue] = mapping.composeTag(
            for: CodingKeys.spread
        )

    }
}

// MARK: - DeployUpdateConfig

extension Service {
    public struct DeployUpdateConfig: Codable, Sendable, Equatable, Hashable {
        /// Number of tasks updated simultaneously
        public var parallelism: Int?
        /// Time to wait between updating a group of tasks
        public var delay: String?
        /// Action taken on update failure ('continue', 'rollback', 'pause')
        public var failure_action: String?
        /// Duration after each task update to monitor for failure
        public var monitor: String?
        /// Failure rate to tolerate during an update
        public var max_failure_ratio: Double?
        /// Update order ('stop-first', 'start-first')
        public var order: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            parallelism: Int?,
            delay: String?,
            failure_action: String?,
            monitor: String?,
            max_failure_ratio: Double?,
            order: String?
        ) {
            self.parallelism = parallelism
            self.delay = delay
            self.failure_action = failure_action
            self.monitor = monitor
            self.max_failure_ratio = max_failure_ratio
            self.order = order
        }

    }
}

extension Service.DeployUpdateConfig: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.parallelism = try? mapping.value(for: CodingKeys.parallelism)
            .int(envs: envs)
        self.tags[CodingKeys.parallelism.stringValue] = mapping.composeTag(
            for: CodingKeys.parallelism
        )

        self.delay = try? mapping.value(for: CodingKeys.delay).string(
            envs: envs
        )
        self.tags[CodingKeys.delay.stringValue] = mapping.composeTag(
            for: CodingKeys.delay
        )

        self.failure_action = try? mapping.value(
            for: CodingKeys.failure_action
        ).string(envs: envs)
        self.tags[CodingKeys.failure_action.stringValue] = mapping.composeTag(
            for: CodingKeys.failure_action
        )

        self.monitor = try? mapping.value(for: CodingKeys.monitor).string(
            envs: envs
        )
        self.tags[CodingKeys.monitor.stringValue] = mapping.composeTag(
            for: CodingKeys.monitor
        )

        self.max_failure_ratio = try? mapping.value(
            for: CodingKeys.max_failure_ratio
        ).float(envs: envs)
        self.tags[CodingKeys.max_failure_ratio.stringValue] =
            mapping.composeTag(for: CodingKeys.max_failure_ratio)

        self.order = try? mapping.value(for: CodingKeys.order).string(
            envs: envs
        )
        self.tags[CodingKeys.order.stringValue] = mapping.composeTag(
            for: CodingKeys.order
        )

    }
}

// MARK: - DeployRollbackConfig

extension Service {
    public struct DeployRollbackConfig: Codable, Sendable, Equatable, Hashable {
        /// Number of tasks rolled back simultaneously
        public var parallelism: Int?
        /// Time to wait between rolling back a group of tasks
        public var delay: String?
        /// Action taken on rollback failure ('continue', 'pause')
        public var failure_action: String?
        /// Duration after each task rollback to monitor for failure
        public var monitor: String?
        /// Failure rate to tolerate during a rollback
        public var max_failure_ratio: Double?
        /// Rollback order ('stop-first', 'start-first')
        public var order: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            parallelism: Int?,
            delay: String?,
            failure_action: String?,
            monitor: String?,
            max_failure_ratio: Double?,
            order: String?
        ) {
            self.parallelism = parallelism
            self.delay = delay
            self.failure_action = failure_action
            self.monitor = monitor
            self.max_failure_ratio = max_failure_ratio
            self.order = order
        }

    }
}

extension Service.DeployRollbackConfig: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.parallelism = try? mapping.value(for: CodingKeys.parallelism)
            .int(envs: envs)
        self.tags[CodingKeys.parallelism.stringValue] = mapping.composeTag(
            for: CodingKeys.parallelism
        )

        self.delay = try? mapping.value(for: CodingKeys.delay).string(
            envs: envs
        )
        self.tags[CodingKeys.delay.stringValue] = mapping.composeTag(
            for: CodingKeys.delay
        )

        self.failure_action = try? mapping.value(
            for: CodingKeys.failure_action
        ).string(envs: envs)
        self.tags[CodingKeys.failure_action.stringValue] = mapping.composeTag(
            for: CodingKeys.failure_action
        )

        self.monitor = try? mapping.value(for: CodingKeys.monitor).string(
            envs: envs
        )
        self.tags[CodingKeys.monitor.stringValue] = mapping.composeTag(
            for: CodingKeys.monitor
        )

        self.max_failure_ratio = try? mapping.value(
            for: CodingKeys.max_failure_ratio
        ).float(envs: envs)
        self.tags[CodingKeys.max_failure_ratio.stringValue] =
            mapping.composeTag(for: CodingKeys.max_failure_ratio)

        self.order = try? mapping.value(for: CodingKeys.order).string(
            envs: envs
        )
        self.tags[CodingKeys.order.stringValue] = mapping.composeTag(
            for: CodingKeys.order
        )
    }
}
