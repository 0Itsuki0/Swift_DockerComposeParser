//
//  Deploy.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Represents the `deploy` configuration for a service (primarily for Swarm orchestration).
extension Service {
    public struct Deploy: Codable, Hashable {
        /// Deployment mode (e.g., 'replicated', 'global')
        public var mode: String?
        /// Number of replicated service tasks
        public var replicas: Int?
        /// Resource constraints (limits, reservations)
        public var resources: DeployResources?
        /// Restart policy for tasks
        public var restart_policy: DeployRestartPolicy?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            mode: String?,
            replicas: Int?,
            resources: DeployResources?,
            restart_policy: DeployRestartPolicy?
        ) {
            self.mode = mode
            self.replicas = replicas
            self.resources = resources
            self.restart_policy = restart_policy
        }

    }

    public struct DeployResources: Codable, Hashable {
        /// Hard limits on resources
        public var limits: ResourceLimits?
        /// Guarantees for resources
        public var reservations: ResourceReservations?

        public init(
            limits: ResourceLimits?,
            reservations: ResourceReservations?
        ) {
            self.limits = limits
            self.reservations = reservations
        }
    }

    public struct DeployRestartPolicy: Codable, Hashable {
        /// Condition to restart on (e.g., 'on-failure', 'any')
        public var condition: String?
        /// Delay before attempting restart
        public var delay: String?
        /// Maximum number of restart attempts
        public var max_attempts: Int?
        /// Window to evaluate restart policy
        public var window: String?

        public init(
            condition: String?,
            delay: String?,
            max_attempts: Int?,
            window: String?
        ) {
            self.condition = condition
            self.delay = delay
            self.max_attempts = max_attempts
            self.window = window
        }

    }

    public struct ResourceLimits: Codable, Hashable {
        /// CPU limit (e.g., "0.5")
        public var cpus: String?
        /// Memory limit (e.g., "512M")
        public var memory: String?

        public init(cpus: String?, memory: String?) {
            self.cpus = cpus
            self.memory = memory
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.cpus = try container.decodeIfPresent(
                String.self,
                forKey: .cpus
            )
            self.memory = try container.decodeIfPresent(
                String.self,
                forKey: .memory
            )
        }
    }

    public struct ResourceReservations: Codable, Hashable {
        /// CPU reservation (e.g., "0.25")
        public var cpus: String?
        /// Memory reservation (e.g., "256M")
        public var memory: String?
        /// Device reservations for GPUs or other devices
        public var devices: [DeviceReservation]?

        public init(
            cpus: String?,
            memory: String?,
            devices: [DeviceReservation]?
        ) {
            self.cpus = cpus
            self.memory = memory
            self.devices = devices
        }

    }

    public struct DeviceReservation: Codable, Hashable {
        /// Device capabilities
        public var capabilities: [String]?
        /// Device driver
        public var driver: String?
        /// Number of devices
        public var count: String?
        /// Specific device IDs
        public var device_ids: [String]?

        public init(
            capabilities: [String]?,
            driver: String?,
            count: String?,
            device_ids: [String]?
        ) {
            self.capabilities = capabilities
            self.driver = driver
            self.count = count
            self.device_ids = device_ids
        }
    }
}

extension Service.Deploy: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.mode = try? mapping.value(for: CodingKeys.mode).string(envs: envs)
        self.replicas = try? mapping.value(for: CodingKeys.replicas).int(
            envs: envs
        )

        self.resources = try? Service.DeployResources(
            mapping.value(for: CodingKeys.resources),
            envs: envs
        )

        self.restart_policy = try? Service.DeployRestartPolicy(
            mapping.value(for: CodingKeys.restart_policy),
            envs: envs
        )
    }
}

extension Service.DeployResources: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.limits = try? Service.ResourceLimits(
            mapping.value(for: CodingKeys.limits),
            envs: envs
        )

        self.reservations = try? Service.ResourceReservations(
            mapping.value(for: CodingKeys.reservations),
            envs: envs
        )
    }
}

extension Service.DeployRestartPolicy: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.condition = try? mapping.value(for: CodingKeys.condition).string(
            envs: envs
        )
        self.delay = try? mapping.value(for: CodingKeys.delay).string(
            envs: envs
        )
        self.max_attempts = try? mapping.value(for: CodingKeys.max_attempts)
            .int(envs: envs)
        self.window = try? mapping.value(for: CodingKeys.window).string(
            envs: envs
        )
    }
}

extension Service.ResourceLimits: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.cpus = try? mapping.value(for: CodingKeys.cpus).string(envs: envs)
        self.memory = try? mapping.value(for: CodingKeys.memory).string(
            envs: envs
        )
    }
}

extension Service.ResourceReservations: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.cpus = try? mapping.value(for: CodingKeys.cpus).string(envs: envs)
        self.memory = try? mapping.value(for: CodingKeys.memory).string(
            envs: envs
        )

        self.devices = try? mapping.value(for: CodingKeys.devices)
            .array(of: Service.DeviceReservation.self, envs: envs)
    }
}

extension Service.DeviceReservation: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.capabilities = try? mapping.value(for: CodingKeys.capabilities)
            .array(of: String.self, envs: envs)

        self.driver = try? mapping.value(for: CodingKeys.driver).string(
            envs: envs
        )
        self.count = try? mapping.value(for: CodingKeys.count).string(
            envs: envs
        )

        self.device_ids = try? mapping.value(for: CodingKeys.device_ids)
            .array(of: String.self, envs: envs)
    }
}
