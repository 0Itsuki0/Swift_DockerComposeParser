//
//  Config.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Represents a top-level config definition
public struct Config: Codable {
    /// Path to the file containing the config content
    public var file: String?
    /// Indicates if the config is external (pre-existing)
    public var external: Bool?
    /// Explicit name for the config
    public var name: String?
    public var environment: String?
    public var content: String?

    // key : tag
    public var tags: [String: ComposeTag?] = [:]

    public init(
        file: String? = nil,
        external: Bool? = nil,
        name: String? = nil,
        environment: String? = nil,
        content: String? = nil
    ) {
        self.file = file
        self.external = external
        self.name = name
        self.environment = environment
        self.content = content
    }
}

extension Config: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.file = try? mapping.value(for: CodingKeys.file).string(envs: envs)
        self.tags[CodingKeys.file.stringValue] = mapping.composeTag(
            for: CodingKeys.file
        )

        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)
        self.tags[CodingKeys.name.stringValue] = mapping.composeTag(
            for: CodingKeys.name
        )

        self.external = try? mapping.value(for: CodingKeys.external).bool
        self.tags[CodingKeys.external.stringValue] = mapping.composeTag(
            for: CodingKeys.external
        )

        self.environment = try? mapping.value(for: CodingKeys.environment)
            .string(envs: envs)
        self.tags[CodingKeys.environment.stringValue] = mapping.composeTag(
            for: CodingKeys.environment
        )

        self.content = try? mapping.value(for: CodingKeys.content).string(
            envs: envs
        )
        self.tags[CodingKeys.content.stringValue] = mapping.composeTag(
            for: CodingKeys.content
        )
    }
}
