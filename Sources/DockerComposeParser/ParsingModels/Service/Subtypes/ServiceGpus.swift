//
//  GPU.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// GPU devices to be allocated for container usage (`gpus`). Accepts either the
/// literal string `all`, or a list of specific device requests.
extension Service {
    public struct GPU: Codable, Hashable {
        public var all: Bool
        public var devices: [GpuDevice]?

        // tag is a global flag, ie: same one for both "all" and "devices"
        public var tags: [String: ComposeTag?] = [:]

        public init(all: Bool = false, devices: [GpuDevice]? = nil) {
            self.all = all
            self.devices = devices
        }
    }
}

extension Service.GPU: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        if let flag = try node.string(envs: envs), flag == "all" {
            self.all = true
            self.devices = nil
        } else {
            self.all = false
            self.devices = try node.array(
                of: Service.GpuDevice.self,
                envs: envs
            )
        }

        self.tags[CodingKeys.all.stringValue] = node.composeTag
        self.tags[CodingKeys.devices.stringValue] = node.composeTag
    }
}
