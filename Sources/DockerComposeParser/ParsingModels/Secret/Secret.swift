//
//  Secret.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Yams

/// Represents a top-level secret definition
/// https://docs.docker.com/reference/compose-file/secrets/
public struct Secret: Codable, Hashable {
    /// Path to the file containing the secret content
    public var file: String?
    /// Environment variable to populate with the secret content
    public var environment: String?

    public var tags: [String: ComposeTag?] = [:]

    public init(
        file: String? = nil,
        environment: String? = nil,
    ) {
        self.file = file
        self.environment = environment
    }
}

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
        self.tags[CodingKeys.file.stringValue] = mapping.composeTag(
            for: CodingKeys.file
        )

        self.environment = try? mapping.value(for: CodingKeys.environment)
            .string(envs: envs)
        self.tags[CodingKeys.environment.stringValue] = mapping.composeTag(
            for: CodingKeys.environment
        )

    }
}

extension Secret {
    func resolvePathToAbsolute(projectDirectory: URL) -> Secret {
        var resolved = self
        resolved.file = resolved.file?.absolutePath(
            relativeTo: projectDirectory
        )
        return resolved
    }
}
