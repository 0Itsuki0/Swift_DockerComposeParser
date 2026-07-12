//
//  BlkioWeightDevice.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// A single path/weight pair used within `blkio_config.weight_device`.
extension Service {
    public struct BlkioWeightDevice: Codable, Sendable, Equatable, Hashable {
        public var path: String
        public var weight: Int

        public var tags: [String: ComposeTag?] = [:]

        public init(path: String, weight: Int) {
            self.path = path
            self.weight = weight
        }
    }
}
extension Service.BlkioWeightDevice: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        guard
            let path = try mapping.value(for: CodingKeys.path).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.path],
                    debugDescription:
                        "BlkioWeightDevice entry must have a 'path' specified."
                )
            )
        }
        self.path = path
        self.tags[CodingKeys.path.stringValue] = mapping.composeTag(
            for: CodingKeys.path
        )

        guard
            let weight = try mapping.value(for: CodingKeys.weight).int(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.weight],
                    debugDescription:
                        "BlkioWeightDevice entry must have a 'weight' specified."
                )
            )
        }
        self.weight = weight
        self.tags[CodingKeys.weight.stringValue] = mapping.composeTag(
            for: CodingKeys.weight
        )
    }
}
