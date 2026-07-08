//
//  Volume.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

// TODO: - Check external (https://docs.docker.com/reference/compose-file/volumes/#external)
//
//If set to true:
//
//external specifies that this volume already exists on the platform and its lifecycle is managed outside of that of the application. Compose then doesn't create the volume and returns an error if the volume doesn't exist.
//All other attributes apart from name are irrelevant. If Compose detects any other attribute, it rejects the Compose file as invalid.
//In the following example, instead of attempting to create a volume called {project_name}_db-data, Compose looks for an existing volume simply called db-data and mounts it into the backend service's containers.


/// Represents a top-level volume definition.
/// https://docs.docker.com/reference/compose-file/volumes/#attributes
public struct Volume: Codable, Hashable {
    /// Volume driver (e.g., 'local')
    public var driver: String?

    /// Driver-specific options
    // optional value to handle reset
    public var driver_opts: [String: String?]?

    /// Explicit name for the volume
    public var name: String?

    /// Labels for the volume
    // optional value to handle reset
    public var labels: [String: String?]?

    /// specifies that this volume already exists on the platform and its lifecycle is managed outside of that of the application.
    /// Compose then doesn't create the volume and returns an error if the volume doesn't exist.
    public var external: Bool?

    public var tags: [String: ComposeTag?] = [:]

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_vol" }` (object).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        driver = try container.decodeIfPresent(String.self, forKey: .driver)
        driver_opts = try container.decodeIfPresent(
            [String: String].self,
            forKey: .driver_opts
        )
        name = try container.decodeIfPresent(String.self, forKey: .name)
        labels = try container.decodeIfPresent(
            [String: String].self,
            forKey: .labels
        )

        external = try container.decodeIfPresent(Bool.self, forKey: .external)
    }

    public init(
        driver: String? = nil,
        driver_opts: [String: String]? = nil,
        name: String? = nil,
        labels: [String: String]? = nil,
        external: Bool? = nil
    ) {
        self.driver = driver
        self.driver_opts = driver_opts
        self.name = name
        self.labels = labels
        self.external = external
    }
}

extension Volume: NodeConvertible {

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

        self.driver_opts = try? mapping.value(for: CodingKeys.driver_opts)
            .dictionary(envs: envs)

        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)

        self.labels = try? mapping.value(for: CodingKeys.labels)
            .dictionary(envs: envs)

        self.external = try? mapping.value(for: CodingKeys.external).bool
        self.tags[CodingKeys.external.stringValue] = mapping.composeTag(
            for: CodingKeys.external
        )
    }
}
