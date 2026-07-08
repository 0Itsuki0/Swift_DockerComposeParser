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
        public var options: [String: String]?
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

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.driver = try container.decodeIfPresent(
                String.self,
                forKey: .driver
            )
            self.config = try container.decodeIfPresent(
                [IPAMConfig].self,
                forKey: .config
            )
            self.options = try container.decodeIfPresent(
                [String: String].self,
                forKey: .options
            )
        }
    }

    public struct IPAMConfig: Codable, Hashable {
        public var subnet: String?
        public var ip_range: String?
        public var gateway: String?
        public var aux_addresses: [String: String]?
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

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.subnet = try container.decodeIfPresent(
                String.self,
                forKey: .subnet
            )
            self.ip_range = try container.decodeIfPresent(
                String.self,
                forKey: .ip_range
            )
            self.gateway = try container.decodeIfPresent(
                String.self,
                forKey: .gateway
            )
            self.aux_addresses = try container.decodeIfPresent(
                [String: String].self,
                forKey: .aux_addresses
            )
        }
    }
}

extension Network.IPAM: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
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

        self.config = try? mapping.value(for: CodingKeys.config)
            .array(of: Network.IPAMConfig.self, envs: envs)

        self.options = try? mapping.value(for: CodingKeys.options)
            .dictionary(envs: envs)
    }
}

extension Network.IPAMConfig: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
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
        self.ip_range = try? mapping.value(for: CodingKeys.ip_range).string(
            envs: envs
        )
        self.gateway = try? mapping.value(for: CodingKeys.gateway).string(
            envs: envs
        )
        self.aux_addresses = try? mapping.value(for: CodingKeys.aux_addresses)
            .dictionary(envs: envs)
    }
}
