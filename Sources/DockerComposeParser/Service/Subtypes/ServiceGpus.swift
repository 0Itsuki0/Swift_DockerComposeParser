//
//  GPU.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// GPU devices to be allocated for container usage (`gpus`). Accepts either the
/// literal string `all`, or a list of specific device requests.
extension Service {
    public struct GPU: Codable, Hashable {
        public var all: Bool
        public var devices: [GpuDevice]?
        
        public var tags: [String: ComposeTag?] = [:]

        public init(all: Bool = false, devices: [GpuDevice]? = nil) {
            self.all = all
            self.devices = devices
        }

        public init(from decoder: Decoder) throws {
            if let flag = try? decoder.singleValueContainer().decode(
                String.self
            ),
                flag == "all"
            {
                all = true
                devices = nil
            } else {
                all = false
                devices = try [GpuDevice](from: decoder)
            }
        }

        public func encode(to encoder: Encoder) throws {
            if all {
                var container = encoder.singleValueContainer()
                try container.encode("all")
            } else {
                try (devices ?? []).encode(to: encoder)
            }
        }
    }
}

import Yams

extension Service.GPU: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        if let flag = try node.string(envs: envs), flag == "all" {
            self.all = true
            self.devices = nil
        } else {
            self.all = false
            self.devices = try node.array(of: Service.GpuDevice.self, envs: envs)
        }
    }
}
