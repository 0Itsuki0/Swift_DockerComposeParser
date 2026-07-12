//
//  ResourceReservations.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/09.
//

import Yams

extension Service {

    public struct ResourceReservations: Codable, Sendable, Equatable, Hashable {
        /// CPU reservation (e.g., "0.25")
        public var cpus: String?
        /// Memory reservation (e.g., "256M")
        public var memory: String?
        /// Device reservations for GPUs or other devices
        public var devices: [DeviceReservation]?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            cpus: String?,
            memory: String?,
            devices: [DeviceReservation]?
        ) {
            self.cpus = cpus
            self.memory = memory
            self.devices = devices
        }

    }

}

extension Service.ResourceReservations: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.cpus = try? mapping.value(for: CodingKeys.cpus).string(envs: envs)
        self.tags[CodingKeys.cpus.stringValue] = mapping.composeTag(
            for: CodingKeys.cpus
        )

        self.memory = try? mapping.value(for: CodingKeys.memory).string(
            envs: envs
        )
        self.tags[CodingKeys.memory.stringValue] = mapping.composeTag(
            for: CodingKeys.memory
        )

        self.devices = try? mapping.value(for: CodingKeys.devices)
            .array(of: Service.DeviceReservation.self, envs: envs)
        self.tags[CodingKeys.devices.stringValue] = mapping.composeTag(
            for: CodingKeys.devices
        )

    }
}
