//
//  Deploy.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Represents the `deploy` configuration for a service (primarily for Swarm orchestration).
extension Service {
 
    public struct DeployRestartPolicy: Codable, Hashable {
        /// Condition to restart on (e.g., 'on-failure', 'any')
        public var condition: String?
        /// Delay before attempting restart
        public var delay: String?
        /// Maximum number of restart attempts
        public var max_attempts: Int?
        /// Window to evaluate restart policy
        public var window: String?

        public var tags: [String: ComposeTag?] = [:]

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
        self.tags[CodingKeys.condition.stringValue] = mapping.composeTag(
            for: CodingKeys.condition
        )

        self.delay = try? mapping.value(for: CodingKeys.delay).string(
            envs: envs
        )
        self.tags[CodingKeys.delay.stringValue] = mapping.composeTag(
            for: CodingKeys.delay
        )

        self.max_attempts = try? mapping.value(for: CodingKeys.max_attempts)
            .int(envs: envs)
        self.tags[CodingKeys.max_attempts.stringValue] = mapping.composeTag(
            for: CodingKeys.max_attempts
        )

        self.window = try? mapping.value(for: CodingKeys.window).string(
            envs: envs
        )
        self.tags[CodingKeys.window.stringValue] = mapping.composeTag(
            for: CodingKeys.window
        )

    }
}
