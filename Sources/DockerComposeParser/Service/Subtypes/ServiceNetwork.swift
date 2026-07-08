//
//  Network.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Service-specific network options for Compose object-form networks.
extension Service {
    public struct Network: Codable, Hashable {
        /// Additional DNS aliases requested for this service on the network.
        public var aliases: [String]?

        /// Static IPv4 address requested by the Compose file.
        public var ipv4_address: String?

        /// Static IPv6 address requested by the Compose file.
        public var ipv6_address: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            aliases: [String]? = nil,
            ipv4_address: String? = nil,
            ipv6_address: String? = nil
        ) {
            self.aliases = aliases
            self.ipv4_address = ipv4_address
            self.ipv6_address = ipv6_address
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.aliases = try container.decodeIfPresent(
                [String].self,
                forKey: .aliases
            )
            self.ipv4_address = try container.decodeIfPresent(
                String.self,
                forKey: .ipv4_address
            )
            self.ipv6_address = try container.decodeIfPresent(
                String.self,
                forKey: .ipv6_address
            )
        }
    }
}

extension Service.Network: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.aliases = try? mapping.value(for: CodingKeys.aliases)
            .array(of: String.self, envs: envs)

        self.ipv4_address = try? mapping.value(for: CodingKeys.ipv4_address)
            .string(envs: envs)

        self.ipv6_address = try? mapping.value(for: CodingKeys.ipv6_address)
            .string(envs: envs)
    }
}
