//
//  BlkioDeviceRate.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

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

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            path = try container.decode(String.self, forKey: .path)
            if let rateString = try? container.decode(
                String.self,
                forKey: .rate
            ) {
                rate = rateString
            } else {
                rate = "\(try container.decode(Int.self, forKey: .rate))"
            }
        }
    }
}

import Yams

extension Service.BlkioDeviceRate: NodeConvertible {

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
                    debugDescription: "BlkioDeviceRate entry must have a 'path' specified."
                )
            )
        }
        self.path = path

        let rateNode = try mapping.value(for: CodingKeys.rate)
        if let rateString = try? rateNode.string(envs: envs) {
            self.rate = rateString
        } else if let rateInt = try? rateNode.int(envs: envs) {
            self.rate = "\(rateInt)"
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.rate],
                    debugDescription: "BlkioDeviceRate entry must have a 'rate' specified."
                )
            )
        }
    }
}
