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
    /// Labels for the config
    public var labels: [String: String]?

    // key : tag
    public var tags: [String: ComposeTag?] = [:]

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_cfg" }` (object).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decodeIfPresent(String.self, forKey: .file)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        labels = try container.decodeIfPresent(
            [String: String].self,
            forKey: .labels
        )
        external = try container.decodeIfPresent(Bool.self, forKey: .external)
    }

    public init(
        file: String? = nil,
        external: Bool? = nil,
        name: String? = nil,
        labels: [String: String]? = nil
    ) {
        self.file = file
        self.external = external
        self.name = name
        self.labels = labels
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
        self.tags[CodingKeys.file.stringValue] = mapping.composeTag(for: CodingKeys.file)

        self.labels = try? mapping.value(for: CodingKeys.labels)
            .dictionary(envs: envs)
        self.tags[CodingKeys.labels.stringValue] = mapping.composeTag(for: CodingKeys.labels)

        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)
        self.tags[CodingKeys.name.stringValue] = mapping.composeTag(for: CodingKeys.name)

        self.external = try? mapping.value(for: CodingKeys.external).bool
        self.tags[CodingKeys.external.stringValue] = mapping.composeTag(for: CodingKeys.external)
    }
}
