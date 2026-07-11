//
//  Dependency.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Service-level `depends_on` options for Compose map-form dependencies.
extension Service {
    public struct Dependency: Codable, Hashable {

        /// Dependency condition, for example `service_started` or `service_healthy`.
        public var condition: DependencyCondition?

        /// Compose optional restart hint for dependency updates.
        public var restart: Bool?

        /// Compose optional required hint. Defaults to true in Docker Compose.
        public var required: Bool?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            condition: DependencyCondition? = nil,
            restart: Bool? = nil,
            required: Bool? = nil
        ) {
            self.condition = condition
            self.restart = restart
            self.required = required
        }
    }

    public enum DependencyCondition: String, Codable, Sendable, Hashable {
        case service_started
        case service_healthy
        case service_completed_successfully

        public static let `default` = Self.service_started
    }
}

extension Service.Dependency: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        if let conditionString = try? mapping.value(for: CodingKeys.condition)
            .string(envs: envs)
        {
            self.condition = Service.DependencyCondition(
                rawValue: conditionString
            )
        } else {
            self.condition = nil
        }
        self.tags[CodingKeys.condition.stringValue] = mapping.composeTag(
            for: CodingKeys.condition
        )

        self.restart = try? mapping.value(for: CodingKeys.restart).bool(envs: envs)
        self.tags[CodingKeys.restart.stringValue] = mapping.composeTag(
            for: CodingKeys.restart
        )

        self.required = try? mapping.value(for: CodingKeys.required).bool(envs: envs)
        self.tags[CodingKeys.required.stringValue] = mapping.composeTag(
            for: CodingKeys.required
        )

    }
}
