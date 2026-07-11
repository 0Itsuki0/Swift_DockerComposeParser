//
//  Hook.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

extension Service {
    public struct Hook: Codable, Hashable {
        public var command: [String]?
        public var user: String?
        public var privileged: Bool?
        // optional value to handle reset
        public var environment: [String: String?]?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            command: [String]? = nil,
            user: String? = nil,
            privileged: Bool? = nil,
            environment: [String: String]? = nil
        ) {
            self.command = command
            self.user = user
            self.privileged = privileged
            self.environment = environment
        }
    }
}

extension Service.Hook: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        // `command` accepts either a list of strings or a single string.
        if let commandArray = try? mapping.value(for: CodingKeys.command)
            .array(of: String.self, envs: envs), !commandArray.isEmpty
        {
            self.command = commandArray
        } else {
            self.command = nil
        }
        self.tags[CodingKeys.command.stringValue] = mapping.composeTag(
            for: CodingKeys.command
        )

        self.user = try? mapping.value(for: CodingKeys.user).string(envs: envs)
        self.tags[CodingKeys.user.stringValue] = mapping.composeTag(
            for: CodingKeys.user
        )

        self.privileged = try? mapping.value(for: CodingKeys.privileged).bool(envs: envs)
        self.tags[CodingKeys.privileged.stringValue] = mapping.composeTag(
            for: CodingKeys.privileged
        )

        // `environment` accepts either a `KEY: VALUE` mapping or a list of
        // `KEY=VALUE` strings, same as the decoder-based init.
        self.environment = try? mapping.value(for: CodingKeys.environment)
            .dictionary(envs: envs, isEnv: true)
        self.tags[CodingKeys.environment.stringValue] = mapping.composeTag(
            for: CodingKeys.environment
        )
    }
}
