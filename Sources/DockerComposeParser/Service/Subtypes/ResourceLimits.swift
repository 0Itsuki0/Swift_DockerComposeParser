//
//  ResourceLimits.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/09.
//

import Yams

extension Service {
    public struct ResourceLimits: Codable, Hashable {
        /// CPU limit (e.g., "0.5")
        public var cpus: String?
        /// Memory limit (e.g., "512M")
        public var memory: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(cpus: String?, memory: String?) {
            self.cpus = cpus
            self.memory = memory
        }
    }

}

extension Service.ResourceLimits: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.cpus = try? mapping.value(for: CodingKeys.cpus).string(envs: envs)
        self.tags[CodingKeys.cpus.stringValue] = mapping.composeTag(
            for: CodingKeys.cpus
        )

        self.memory = try? mapping.value(for: CodingKeys.memory).string(
            envs: envs
        )
        self.tags[CodingKeys.memory.stringValue] = mapping.composeTag(
            for: CodingKeys.memory
        )

    }
}
