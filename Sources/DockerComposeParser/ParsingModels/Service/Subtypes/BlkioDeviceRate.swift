//
//  BlkioDeviceRate.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// A single path/rate pair used within `blkio_config`'s bps and iops lists.
extension Service {
    public struct BlkioDeviceRate: Codable, Hashable {
        public var path: String
        public var rate: String

        public var tags: [String: ComposeTag?] = [:]

        public init(path: String, rate: String) {
            self.path = path
            self.rate = rate
        }
    }
}

extension Service.BlkioDeviceRate: NodeConvertible {

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
                        "BlkioDeviceRate entry must have a 'path' specified."
                )
            )
        }
        self.path = path
        self.tags[CodingKeys.path.stringValue] = mapping.composeTag(
            for: CodingKeys.path
        )

        self.rate =
            if let rate = try mapping.value(for: CodingKeys.rate).string(
                envs: envs
            ) {
                rate
            } else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.path],
                        debugDescription:
                            "BlkioDeviceRate entry must have a 'rate' specified."
                    )
                )
            }
        self.tags[CodingKeys.rate.stringValue] = mapping.composeTag(
            for: CodingKeys.rate
        )
    }
}
