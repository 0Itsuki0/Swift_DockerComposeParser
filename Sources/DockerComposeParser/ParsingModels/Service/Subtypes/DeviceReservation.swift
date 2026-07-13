//
//  DeviceReservation.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/09.
//

import Yams

extension Service {
    public struct DeviceReservation: Codable, Sendable, Equatable, Hashable {
        /// Device capabilities
        public var capabilities: [String]?
        /// Device driver
        public var driver: String?
        /// Number of devices
        public var count: String?
        /// Specific device IDs
        public var device_ids: [String]?

        public var options: [String: String?]?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            capabilities: [String]? = nil,
            driver: String? = nil,
            count: String? = nil,
            device_ids: [String]? = nil,
            options: [String: String?] = [:],
        ) {
            self.capabilities = capabilities
            self.driver = driver
            self.count = count
            self.device_ids = device_ids
            self.options = options
        }
    }

}

extension Service.DeviceReservation: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.capabilities = try? mapping.value(for: CodingKeys.capabilities)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.capabilities.stringValue] = mapping.composeTag(
            for: CodingKeys.capabilities
        )

        self.driver = try? mapping.value(for: CodingKeys.driver).string(
            envs: envs
        )
        self.tags[CodingKeys.driver.stringValue] = mapping.composeTag(
            for: CodingKeys.driver
        )

        self.count = try? mapping.value(for: CodingKeys.count).string(
            envs: envs
        )
        self.tags[CodingKeys.count.stringValue] = mapping.composeTag(
            for: CodingKeys.count
        )

        self.device_ids = try? mapping.value(for: CodingKeys.device_ids)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.device_ids.stringValue] = mapping.composeTag(
            for: CodingKeys.device_ids
        )

        self.options = try? mapping.value(for: CodingKeys.options).dictionary(
            envs: envs,
            isEnv: false
        )

        self.tags[CodingKeys.options.stringValue] = mapping.composeTag(
            for: CodingKeys.options
        )

    }
}
