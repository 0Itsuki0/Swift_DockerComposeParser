//
//  GpuDevice.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// A single GPU device request within `gpus`.
extension Service {
    public struct GpuDevice: Codable, Hashable {
        public var driver: String?
        public var count: Int?
        public var device_ids: [String]?
        public var capabilities: [String]?
        // optional value to handle reset
        public var options: [String: String?]?
        
        public var tags: [String: ComposeTag?] = [:]

        public init(
            driver: String? = nil,
            count: Int? = nil,
            deviceIds: [String]? = nil,
            capabilities: [String]? = nil,
            options: [String: String]? = nil
        ) {
            self.driver = driver
            self.count = count
            self.device_ids = deviceIds
            self.capabilities = capabilities
            self.options = options
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.driver = try container.decodeIfPresent(
                String.self,
                forKey: .driver
            )
            self.count = try container.decodeIfPresent(Int.self, forKey: .count)
            self.device_ids = try container.decodeIfPresent(
                [String].self,
                forKey: .device_ids
            )
            self.capabilities = try container.decodeIfPresent(
                [String].self,
                forKey: .capabilities
            )
            self.options = try container.decodeIfPresent(
                [String: String].self,
                forKey: .options
            )
        }
    }
}

import Yams
extension Service.GpuDevice: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.driver = try? mapping.value(for: CodingKeys.driver).string(envs: envs)
        self.count = try? mapping.value(for: CodingKeys.count).int(envs: envs)

        self.device_ids = try? mapping.value(for: CodingKeys.device_ids)
            .array(of: String.self, envs: envs)

        self.capabilities = try? mapping.value(for: CodingKeys.capabilities)
            .array(of: String.self, envs: envs)

        self.options = try? mapping.value(for: CodingKeys.options).dictionary(envs: envs)
    }
}
