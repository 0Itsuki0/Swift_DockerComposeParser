//
//  Secret.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Represents a top-level secret definition
/// https://docs.docker.com/reference/compose-file/secrets/
public struct Secret: Codable, Hashable {
    /// Path to the file containing the secret content
    public var file: String?
    /// Environment variable to populate with the secret content
    public var environment: String?
    
    public var tags: [String: ComposeTag?] = [:]

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_sec" }` (object).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decodeIfPresent(String.self, forKey: .file)
        environment = try container.decodeIfPresent(
            String.self,
            forKey: .environment
        )
    }

    public init(file: String?, environment: String?) {
        self.file = file
        self.environment = environment
    }
}

import Yams

extension Secret: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        // `try?` acts as decodeIfPresent
        self.file = try? mapping.value(for: CodingKeys.file).string(envs: envs)
        self.environment = try? mapping.value(for: CodingKeys.environment).string(envs: envs)
    }
}
