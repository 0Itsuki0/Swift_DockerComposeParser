//
//  Build.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Represents the `build` configuration for a service.
extension Service {
    public struct Build: Codable, Hashable {
        /// Path to the build context
        public var context: String
        /// Optional path to the Dockerfile within the context
        public var dockerfile: String?
        /// Build arguments
        public var args: [String: String]?
        
        public var tags: [String: ComposeTag?] = [:]

        /// Custom initializer to handle `build: .` (string) or `build: { context: . }` (object)
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let contextString = try? container.decode(String.self) {
                self.context = contextString
                self.dockerfile = nil
                self.args = nil
            } else {
                let keyedContainer = try decoder.container(
                    keyedBy: CodingKeys.self
                )
                self.context = try keyedContainer.decode(
                    String.self,
                    forKey: .context
                )
                self.dockerfile = try keyedContainer.decodeIfPresent(
                    String.self,
                    forKey: .dockerfile
                )
                self.args = try keyedContainer.decodeIfPresent(
                    [String: String].self,
                    forKey: .args
                )
            }
        }

        public init(
            context: String,
            dockerfile: String?,
            args: [String: String]?
        ) {
            self.context = context
            self.dockerfile = dockerfile
            self.args = args
        }
    }
}


import Yams
extension Service.Build: NodeConvertible {

    // Custom initializer to handle `build: .` (string) or `build: { context: . }` (object)
    public init(_ node: Node, envs: [String: String]) throws {
        if let contextString = try node.string(envs: envs) {
            self.context = contextString
            self.dockerfile = nil
            self.args = nil
            return
        }

        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a string or a mapping."
                )
            )
        }

        guard let context = try mapping.value(for: CodingKeys.context).string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.context],
                    debugDescription: "Build entry must have a 'context' specified."
                )
            )
        }
        self.context = context

        self.dockerfile = try? mapping.value(for: CodingKeys.dockerfile).string(envs: envs)
        self.args = try? mapping.value(for: CodingKeys.args).dictionary(envs: envs)
    }
}
