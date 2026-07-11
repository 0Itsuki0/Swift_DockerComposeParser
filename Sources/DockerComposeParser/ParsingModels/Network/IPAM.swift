//
//  IPAM.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//

import Yams

extension Network {
    public struct IPAM: Codable, Hashable {
        public var driver: String?
        public var config: [IPAMConfig]?
        // optional value to handle reset
        public var options: [String: String?]?
        public var tags: [String: ComposeTag?] = [:]

        public init(
            driver: String?,
            config: [IPAMConfig]?,
            options: [String: String]?
        ) {
            self.driver = driver
            self.config = config
            self.options = options
        }
    }

    public struct IPAMConfig: Codable, Hashable {
        public var subnet: String?
        public var ip_range: String?
        public var gateway: String?
        // optional value to handle reset
        public var aux_addresses: [String: String?]?
        public var tags: [String: ComposeTag?] = [:]

        public var isIPV4: Bool {
            subnet?.contains(":") == false
        }

        public init(
            subnet: String?,
            ip_range: String?,
            gateway: String?,
            aux_addresses: [String: String]?
        ) {
            self.subnet = subnet
            self.ip_range = ip_range
            self.gateway = gateway
            self.aux_addresses = aux_addresses
        }

    }
}

extension Network.IPAM: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        // `try?` acts as decodeIfPresent
        self.driver = try? mapping.value(for: CodingKeys.driver).string(
            envs: envs
        )
        self.tags[CodingKeys.driver.stringValue] = mapping.composeTag(
            for: CodingKeys.driver
        )

        self.config = try? mapping.value(for: CodingKeys.config)
            .array(of: Network.IPAMConfig.self, envs: envs)
        self.tags[CodingKeys.config.stringValue] = mapping.composeTag(
            for: CodingKeys.config
        )

        self.options = try? mapping.value(for: CodingKeys.options)
            .dictionary(envs: envs)
        self.tags[CodingKeys.options.stringValue] = mapping.composeTag(
            for: CodingKeys.options
        )

    }
}

extension Network.IPAMConfig: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        // `try?` acts as decodeIfPresent
        self.subnet = try? mapping.value(for: CodingKeys.subnet).string(
            envs: envs
        )
        self.tags[CodingKeys.subnet.stringValue] = mapping.composeTag(
            for: CodingKeys.subnet
        )

        self.ip_range = try? mapping.value(for: CodingKeys.ip_range).string(
            envs: envs
        )
        self.tags[CodingKeys.ip_range.stringValue] = mapping.composeTag(
            for: CodingKeys.ip_range
        )

        self.gateway = try? mapping.value(for: CodingKeys.gateway).string(
            envs: envs
        )
        self.tags[CodingKeys.gateway.stringValue] = mapping.composeTag(
            for: CodingKeys.gateway
        )

        self.aux_addresses = try? mapping.value(for: CodingKeys.aux_addresses)
            .dictionary(envs: envs)
        self.tags[CodingKeys.aux_addresses.stringValue] = mapping.composeTag(
            for: CodingKeys.aux_addresses
        )
    }
}
