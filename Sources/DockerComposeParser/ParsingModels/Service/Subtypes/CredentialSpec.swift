//
//  CredentialSpec.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Yams

/// Credential spec for a managed service account (`credential_spec`), primarily used by Windows containers.
extension Service {
    public struct CredentialSpec: Codable, Hashable {
        public var file: String?
        public var registry: String?
        public var config: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            file: String? = nil,
            registry: String? = nil,
            config: String? = nil
        ) {
            self.file = file
            self.registry = registry
            self.config = config
        }
    }
}
extension Service.CredentialSpec: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
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

        self.registry = try? mapping.value(for: CodingKeys.registry).string(
            envs: envs
        )
        self.tags[CodingKeys.registry.stringValue] = mapping.composeTag(
            for: CodingKeys.registry
        )

        self.config = try? mapping.value(for: CodingKeys.config).string(
            envs: envs
        )
        self.tags[CodingKeys.config.stringValue] = mapping.composeTag(
            for: CodingKeys.config
        )
    }
}

extension Service.CredentialSpec {
    func resolvePathToAbsolute(projectDirectory: URL) -> Service.CredentialSpec
    {
        var resolved = self
        resolved.file = resolved.file?.absolutePath(
            relativeTo: projectDirectory
        )
        return resolved
    }
}
