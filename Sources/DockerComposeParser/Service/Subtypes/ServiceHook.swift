//
//  Hook.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

extension Service {
    public struct Hook: Codable, Hashable {
        public var command: [String]?
        public var user: String?
        public var privileged: Bool?
        public var environment: [String: String]?
        
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

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let commandArray = try? container.decodeIfPresent(
                [String].self,
                forKey: .command
            ) {
                command = commandArray
            } else if let commandString = try? container.decodeIfPresent(
                String.self,
                forKey: .command
            ) {
                command = [commandString]
            } else {
                command = nil
            }
            user = try container.decodeIfPresent(String.self, forKey: .user)
            privileged = try container.decodeIfPresent(
                Bool.self,
                forKey: .privileged
            )
            if let asMap = try? container.decodeIfPresent(
                [String: String].self,
                forKey: .environment
            ) {
                environment = asMap
            } else if let asList = try? container.decodeIfPresent(
                [String].self,
                forKey: .environment
            ) {
                environment = Service.parseEnvironmentList(asList)
            } else {
                environment = nil
            }
        }
    }
}
import Yams

extension Service.Hook: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
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
        } else if let commandString = try? mapping.value(for: CodingKeys.command)
            .string(envs: envs)
        {
            self.command = [commandString]
        } else {
            self.command = nil
        }

        self.user = try? mapping.value(for: CodingKeys.user).string(envs: envs)
        self.privileged = try? mapping.value(for: CodingKeys.privileged).bool

        // `environment` accepts either a `KEY: VALUE` mapping or a list of
        // `KEY=VALUE` strings, same as the decoder-based init.
        if let asMap = try? mapping.value(for: CodingKeys.environment)
            .dictionary(envs: envs)
        {
            self.environment = asMap
        } else if let asList = try? mapping.value(for: CodingKeys.environment)
            .array(of: String.self, envs: envs), !asList.isEmpty
        {
            self.environment = Service.parseEnvironmentList(asList)
        } else {
            self.environment = nil
        }
    }
}
