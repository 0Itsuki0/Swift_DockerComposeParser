//
//  Network.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Service-specific network options for Compose object-form networks.
extension Service {
    // https://docs.docker.com/reference/compose-file/services/#networks
    public struct Network: Codable, Hashable {
        /// Additional DNS aliases requested for this service on the network.
        public var aliases: [String]?

        /// Static IPv4 address requested by the Compose file.
        public var ipv4_address: String?

        /// Static IPv6 address requested by the Compose file.
        public var ipv6_address: String?

        public var interface_name: String?

        public var link_local_ips: [String]?

        public var mac_address: String?
        // optional value to handle reset
        public var driver_opts: [String: String?]?

        public var gw_priority: Int?

        public var priority: Int?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            aliases: [String]? = nil,
            ipv4_address: String? = nil,
            ipv6_address: String? = nil,
            interface_name: String? = nil,
            link_local_ips: [String]? = nil,
            mac_address: String? = nil,
            driver_opts: [String: String]? = nil,
            gw_priority: Int? = nil,
            priority: Int? = nil
        ) {
            self.aliases = aliases
            self.ipv4_address = ipv4_address
            self.ipv6_address = ipv6_address
            self.interface_name = interface_name
            self.link_local_ips = link_local_ips
            self.mac_address = mac_address
            self.driver_opts = driver_opts
            self.gw_priority = gw_priority
            self.priority = priority
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
        self.tags[CodingKeys.aliases.stringValue] = mapping.composeTag(
            for: CodingKeys.aliases
        )

        self.ipv4_address = try? mapping.value(for: CodingKeys.ipv4_address)
            .string(envs: envs)
        self.tags[CodingKeys.ipv4_address.stringValue] = mapping.composeTag(
            for: CodingKeys.ipv4_address
        )

        self.ipv6_address = try? mapping.value(for: CodingKeys.ipv6_address)
            .string(envs: envs)
        self.tags[CodingKeys.ipv6_address.stringValue] = mapping.composeTag(
            for: CodingKeys.ipv6_address
        )

        self.interface_name = try? mapping.value(for: CodingKeys.interface_name)
            .string(envs: envs)
        self.tags[CodingKeys.interface_name.stringValue] = mapping.composeTag(
            for: CodingKeys.interface_name
        )

        self.link_local_ips = try? mapping.value(for: CodingKeys.link_local_ips)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.link_local_ips.stringValue] = mapping.composeTag(
            for: CodingKeys.link_local_ips
        )

        self.mac_address = try? mapping.value(for: CodingKeys.mac_address)
            .string(envs: envs)
        self.tags[CodingKeys.mac_address.stringValue] = mapping.composeTag(
            for: CodingKeys.mac_address
        )

        self.driver_opts = try? mapping.value(for: CodingKeys.driver_opts)
            .dictionary(envs: envs)
        self.tags[CodingKeys.driver_opts.stringValue] = mapping.composeTag(
            for: CodingKeys.driver_opts
        )

        self.gw_priority = try? mapping.value(for: CodingKeys.gw_priority)
            .int(envs: envs)
        self.tags[CodingKeys.gw_priority.stringValue] = mapping.composeTag(
            for: CodingKeys.gw_priority
        )

        self.priority = try? mapping.value(for: CodingKeys.priority)
            .int(envs: envs)
        self.tags[CodingKeys.priority.stringValue] = mapping.composeTag(
            for: CodingKeys.priority
        )
    }
}
