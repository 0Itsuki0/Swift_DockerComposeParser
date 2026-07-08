//
//  BlkioConfig.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Block I/O (blkio) limits for a service container, as set by `blkio_config`.
extension Service {

    public struct BlkioConfig: Codable, Hashable {
        public var weight: Int?
        public var weight_device: [BlkioWeightDevice]?
        public var device_read_bps: [BlkioDeviceRate]?
        public var device_read_iops: [BlkioDeviceRate]?
        public var device_write_bps: [BlkioDeviceRate]?
        public var device_write_iops: [BlkioDeviceRate]?
        
        public var tags: [String: ComposeTag?] = [:]

        public init(
            weight: Int? = nil,
            weightDevice: [BlkioWeightDevice]? = nil,
            deviceReadBps: [BlkioDeviceRate]? = nil,
            deviceReadIops: [BlkioDeviceRate]? = nil,
            deviceWriteBps: [BlkioDeviceRate]? = nil,
            deviceWriteIops: [BlkioDeviceRate]? = nil
        ) {
            self.weight = weight
            self.weight_device = weightDevice
            self.device_read_bps = deviceReadBps
            self.device_read_iops = deviceReadIops
            self.device_write_bps = deviceWriteBps
            self.device_write_iops = deviceWriteIops
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.weight = try container.decodeIfPresent(
                Int.self,
                forKey: .weight
            )
            self.weight_device = try container.decodeIfPresent(
                [BlkioWeightDevice].self,
                forKey: .weight_device
            )
            self.device_read_bps = try container.decodeIfPresent(
                [BlkioDeviceRate].self,
                forKey: .device_read_bps
            )
            self.device_read_iops = try container.decodeIfPresent(
                [BlkioDeviceRate].self,
                forKey: .device_read_iops
            )
            self.device_write_bps = try container.decodeIfPresent(
                [BlkioDeviceRate].self,
                forKey: .device_write_bps
            )
            self.device_write_iops = try container.decodeIfPresent(
                [BlkioDeviceRate].self,
                forKey: .device_write_iops
            )
        }
    }
}


import Yams
extension Service.BlkioConfig: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.weight = try? mapping.value(for: CodingKeys.weight).int(envs: envs)

        self.weight_device = try? mapping.value(for: CodingKeys.weight_device)
            .array(of: Service.BlkioWeightDevice.self, envs: envs)

        self.device_read_bps = try? mapping.value(for: CodingKeys.device_read_bps)
            .array(of: Service.BlkioDeviceRate.self, envs: envs)

        self.device_read_iops = try? mapping.value(for: CodingKeys.device_read_iops)
            .array(of: Service.BlkioDeviceRate.self, envs: envs)

        self.device_write_bps = try? mapping.value(for: CodingKeys.device_write_bps)
            .array(of: Service.BlkioDeviceRate.self, envs: envs)

        self.device_write_iops = try? mapping.value(for: CodingKeys.device_write_iops)
            .array(of: Service.BlkioDeviceRate.self, envs: envs)
    }
}
