//
//  CredentialSpec.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

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
import Yams
extension Service.CredentialSpec: NodeConvertible {

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
        self.registry = try? mapping.value(for: CodingKeys.registry).string(envs: envs)
        self.config = try? mapping.value(for: CodingKeys.config).string(envs: envs)
    }
}
