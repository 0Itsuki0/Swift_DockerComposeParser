//
//  BlkioConfigTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("BlkioConfig Parsing Tests")
struct BlkioConfigTestSuite {

    @Test("Test BlkioConfig parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            weight: 300
            weight_device:
              - path: /dev/sda
                weight: 300
            device_read_bps:
              - path: /dev/sda
                rate: "12mb"
            device_read_iops:
              - path: /dev/sda
                rate: 120
            device_write_bps:
              - path: /dev/sda
                rate: "1024k"
            device_write_iops:
              - path: /dev/sda
                rate: 30
            """
        let node = try Yams.compose(yaml: yaml)
        let config = try Service.BlkioConfig(node!, envs: [:])

        #expect(config.weight == 300)
        #expect(config.weight_device?.first?.path == "/dev/sda")
        #expect(config.weight_device?.first?.weight == 300)
        #expect(config.device_read_bps?.first?.rate == "12mb")
        #expect(config.device_read_iops?.first?.rate == "120")
        #expect(config.device_write_bps?.first?.rate == "1024k")
        #expect(config.device_write_iops?.first?.rate == "30")
    }

    @Test("Test BlkioConfig parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let config = try Service.BlkioConfig(node!, envs: [:])

        #expect(config.weight == nil)
        #expect(config.weight_device == nil)
        #expect(config.device_read_bps == nil)
        #expect(config.device_read_iops == nil)
        #expect(config.device_write_bps == nil)
        #expect(config.device_write_iops == nil)
    }

    @Test("Test BlkioConfig parsing - only weight present")
    func parseOnlyWeight() throws {
        let node = try Yams.compose(yaml: "weight: 500")
        let config = try Service.BlkioConfig(node!, envs: [:])

        #expect(config.weight == 500)
        #expect(config.weight_device == nil)
    }

    @Test("Test BlkioConfig parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            weight_device:
              - path: ${DEVICE_PATH}
                weight: 300
            """
        let node = try Yams.compose(yaml: yaml)
        let config = try Service.BlkioConfig(
            node!,
            envs: ["DEVICE_PATH": "/dev/sda"]
        )
        #expect(config.weight_device?.first?.path == "/dev/sda")
    }

    @Test(
        "Test BlkioConfig parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.BlkioConfig(node!, envs: [:])
        }
    }
}
