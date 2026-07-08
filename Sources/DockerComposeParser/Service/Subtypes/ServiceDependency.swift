//
//  Dependency.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

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

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.condition = try container.decodeIfPresent(
                DependencyCondition.self,
                forKey: .condition
            )
            self.restart = try container.decodeIfPresent(
                Bool.self,
                forKey: .restart
            )
            self.required = try container.decodeIfPresent(
                Bool.self,
                forKey: .required
            )
        }
    }

    public enum DependencyCondition: String, Codable, Sendable, Hashable
    {
        case service_started
        case service_healthy
        case service_completed_successfully

        public static let `default` = Self.service_started
    }
}

import Yams
extension Service.Dependency: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
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
            self.condition = Service.DependencyCondition(rawValue: conditionString)
        } else {
            self.condition = nil
        }

        self.restart = try? mapping.value(for: CodingKeys.restart).bool
        self.required = try? mapping.value(for: CodingKeys.required).bool
    }
}
