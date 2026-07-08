//
//  BlkioWeightDevice.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// A single path/weight pair used within `blkio_config.weight_device`.
extension Service {
    public struct BlkioWeightDevice: Codable, Hashable {
        public var path: String
        public var weight: Int
        
        public var tags: [String: ComposeTag?] = [:]

        public init(path: String, weight: Int) {
            self.path = path
            self.weight = weight
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.path = try container.decode(String.self, forKey: .path)
            self.weight = try container.decode(Int.self, forKey: .weight)
        }
    }
}
import Yams
extension Service.BlkioWeightDevice: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        guard let path = try mapping.value(for: CodingKeys.path).string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.path],
                    debugDescription: "BlkioWeightDevice entry must have a 'path' specified."
                )
            )
        }
        self.path = path

        guard let weight = try mapping.value(for: CodingKeys.weight).int(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.weight],
                    debugDescription: "BlkioWeightDevice entry must have a 'weight' specified."
                )
            )
        }
        self.weight = weight
    }
}
