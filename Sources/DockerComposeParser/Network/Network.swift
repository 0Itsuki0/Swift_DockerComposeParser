//
//  Network.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Represents a top-level network definition.
/// https://docs.docker.com/reference/compose-file/networks/#attributes
public struct Network: Codable, Hashable {

    public var attachable: Bool?

    /// Network driver (e.g., 'bridge', 'overlay')
    public var driver: String?
    /// Driver-specific options
    /// optional value to handle reset
    public var driver_opts: [String: String?]?

    /// Allow standalone containers to attach to this network
    public var enable_ipv4: Bool?

    public var ipv4: String? {
        guard let ipam else {
            return nil
        }
        return ipam.config?.first(where: { $0.isIPV4 })?.subnet
    }

    /// Enable IPv6 networking
    public var enable_ipv6: Bool?

    public var ipv6: String? {
        guard let ipam else {
            return nil
        }
        return ipam.config?.first(where: { !$0.isIPV4 })?.subnet
    }

    /// Indicates if the network is external (pre-existing)
    public var external: Bool?

    public var ipam: IPAM?

    /// By default, Compose provides external connectivity to networks. internal, when set to true, lets you create an externally isolated network.
    public var `internal`: Bool?
    /// Labels for the network
    /// optional value to handle reset
    public var labels: [String: String?]?

    /// Explicit name for the network
    public var name: String?

    public var tags: [String: ComposeTag?] = [:]

    public init(
        driver: String?,
        driver_opts: [String: String]?,
        attachable: Bool?,
        enable_ipv4: Bool?,
        enable_ipv6: Bool?,
        ipam: IPAM?,
        internal: Bool?,
        labels: [String: String]?,
        name: String?,
        external: Bool?
    ) {
        self.driver = driver
        self.driver_opts = driver_opts
        self.attachable = attachable
        self.enable_ipv4 = enable_ipv4
        self.enable_ipv6 = enable_ipv6
        self.ipam = ipam
        self.internal = `internal`
        self.labels = labels
        self.name = name
        self.external = external
    }

}

extension Network: NodeConvertible {

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
        self.tags[CodingKeys.driver.stringValue] = mapping.composeTag(
            for: CodingKeys.driver
        )

        self.driver_opts = try? mapping.value(for: CodingKeys.driver_opts)
            .dictionary(envs: envs)
        self.tags[CodingKeys.driver_opts.stringValue] = mapping.composeTag(
            for: CodingKeys.driver_opts
        )

        self.attachable = try? mapping.value(for: CodingKeys.attachable).bool
        self.tags[CodingKeys.attachable.stringValue] = mapping.composeTag(
            for: CodingKeys.attachable
        )

        self.enable_ipv4 = try? mapping.value(for: CodingKeys.enable_ipv4).bool
        self.tags[CodingKeys.enable_ipv4.stringValue] = mapping.composeTag(
            for: CodingKeys.enable_ipv4
        )

        self.enable_ipv6 = try? mapping.value(for: CodingKeys.enable_ipv6).bool
        self.tags[CodingKeys.enable_ipv6.stringValue] = mapping.composeTag(
            for: CodingKeys.enable_ipv6
        )

        self.`internal` = try? mapping.value(for: CodingKeys.`internal`).bool
        self.tags[CodingKeys.internal.stringValue] = mapping.composeTag(
            for: CodingKeys.internal
        )

        self.labels = try? mapping.value(for: CodingKeys.labels)
            .dictionary(envs: envs)
        self.tags[CodingKeys.labels.stringValue] = mapping.composeTag(
            for: CodingKeys.labels
        )

        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)
        self.tags[CodingKeys.name.stringValue] = mapping.composeTag(
            for: CodingKeys.name
        )

        self.ipam = try? IPAM(mapping.value(for: CodingKeys.ipam), envs: envs)
        self.tags[CodingKeys.ipam.stringValue] = mapping.composeTag(
            for: CodingKeys.ipam
        )

        self.external = try? mapping.value(for: CodingKeys.external).bool
        self.tags[CodingKeys.external.stringValue] = mapping.composeTag(
            for: CodingKeys.external
        )
    }
}
