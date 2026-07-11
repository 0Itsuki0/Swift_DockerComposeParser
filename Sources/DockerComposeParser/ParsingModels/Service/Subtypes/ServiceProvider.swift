//
//  Provider.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Configuration for a service implemented by a Compose provider plugin (`provider`).
extension Service {
    public struct Provider: Codable, Hashable {
        public var type: String
        // optional value to handle reset
        public var options: [String: String?]?

        public var tags: [String: ComposeTag?] = [:]

        public init(type: String, options: [String: String]? = nil) {
            self.type = type
            self.options = options
        }
    }
}

// MARK: - ServiceProvider.swift

extension Service.Provider: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        guard
            let type = try mapping.value(for: CodingKeys.type).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.type],
                    debugDescription:
                        "Provider entry must have a 'type' specified."
                )
            )
        }
        self.type = type
        self.tags[CodingKeys.type.stringValue] = mapping.composeTag(
            for: CodingKeys.type
        )

        self.options = try? mapping.value(for: CodingKeys.options).dictionary(
            envs: envs
        )
        self.tags[CodingKeys.options.stringValue] = mapping.composeTag(
            for: CodingKeys.options
        )
    }
}
