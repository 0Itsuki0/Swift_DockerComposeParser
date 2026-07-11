//
//  BlkioWeightDeviceTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("BlkioWeightDevice Parsing Tests")
struct BlkioWeightDeviceTestSuite {

    @Test("Test BlkioWeightDevice parsing - valid")
    func parseValid() throws {
        let yaml = """
            path: /dev/sda
            weight: 300
            """
        let node = try Yams.compose(yaml: yaml)
        let device = try Service.BlkioWeightDevice(node!, envs: [:])
        #expect(device.path == "/dev/sda")
        #expect(device.weight == 300)
    }

    @Test("Test BlkioWeightDevice parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            path: ${DEVICE_PATH}
            weight: 300
            """
        let node = try Yams.compose(yaml: yaml)
        let device = try Service.BlkioWeightDevice(
            node!,
            envs: ["DEVICE_PATH": "/dev/sda"]
        )
        #expect(device.path == "/dev/sda")
    }

    @Test("Test BlkioWeightDevice parsing - missing path throws")
    func parseMissingPath() throws {
        let node = try Yams.compose(yaml: "weight: 300")
        #expect(throws: (any Error).self) {
            try Service.BlkioWeightDevice(node!, envs: [:])
        }
    }

    @Test("Test BlkioWeightDevice parsing - missing weight throws")
    func parseMissingWeight() throws {
        let node = try Yams.compose(yaml: "path: /dev/sda")
        #expect(throws: (any Error).self) {
            try Service.BlkioWeightDevice(node!, envs: [:])
        }
    }

    @Test("Test BlkioWeightDevice parsing - non-mapping node throws")
    func parseNonMapping() throws {
        let node = try Yams.compose(yaml: "[a, b]")
        #expect(throws: (any Error).self) {
            try Service.BlkioWeightDevice(node!, envs: [:])
        }
    }
}
