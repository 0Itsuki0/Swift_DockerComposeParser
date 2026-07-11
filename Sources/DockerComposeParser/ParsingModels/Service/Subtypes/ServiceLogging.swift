//
//  Logging.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Logging configuration for a service's containers (`logging`).

import Yams

extension Service {
    public struct Logging: Codable, Hashable {
        public var driver: String?
        // optional value to handle reset
        public var options: [String: String?]?

        public var tags: [String: ComposeTag?] = [:]

        public init(driver: String? = nil, options: [String: String]? = nil) {
            self.driver = driver
            self.options = options
        }
    }
}

extension Service.Logging: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.driver = try? mapping.value(for: CodingKeys.driver).string(
            envs: envs
        )
        self.tags[CodingKeys.driver.stringValue] = mapping.composeTag(
            for: CodingKeys.driver
        )

        self.options = try? mapping.value(for: CodingKeys.options).dictionary(
            envs: envs
        )
        self.tags[CodingKeys.options.stringValue] = mapping.composeTag(
            for: CodingKeys.options
        )
    }
}
