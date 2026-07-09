//
//  DeployResources.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/09.
//

import Yams

extension Service {
    public struct DeployResources: Codable, Hashable {
        /// Hard limits on resources
        public var limits: ResourceLimits?
        /// Guarantees for resources
        public var reservations: ResourceReservations?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            limits: ResourceLimits?,
            reservations: ResourceReservations?
        ) {
            self.limits = limits
            self.reservations = reservations
        }
    }

}

extension Service.DeployResources: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.limits = try? Service.ResourceLimits(
            mapping.value(for: CodingKeys.limits),
            envs: envs
        )
        self.tags[CodingKeys.limits.stringValue] = mapping.composeTag(
            for: CodingKeys.limits
        )

        self.reservations = try? Service.ResourceReservations(
            mapping.value(for: CodingKeys.reservations),
            envs: envs
        )
        self.tags[CodingKeys.reservations.stringValue] = mapping.composeTag(
            for: CodingKeys.reservations
        )

    }
}
