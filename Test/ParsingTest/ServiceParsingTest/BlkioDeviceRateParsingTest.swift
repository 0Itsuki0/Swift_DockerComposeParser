//
//  BlkioDeviceRateTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("BlkioDeviceRate Parsing Tests")
struct BlkioDeviceRateTestSuite {

    @Test("Test BlkioDeviceRate parsing - string rate")
    func parseStringRate() throws {
        let yaml = """
            path: /dev/sda
            rate: "12mb"
            """
        let node = try Yams.compose(yaml: yaml)
        let rate = try Service.BlkioDeviceRate(node!, envs: [:])
        #expect(rate.path == "/dev/sda")
        #expect(rate.rate == "12mb")
    }

    @Test("Test BlkioDeviceRate parsing - integer rate coerced to string")
    func parseIntRate() throws {
        let yaml = """
            path: /dev/sda
            rate: 1048576
            """
        let node = try Yams.compose(yaml: yaml)
        let rate = try Service.BlkioDeviceRate(node!, envs: [:])
        #expect(rate.path == "/dev/sda")
        #expect(rate.rate == "1048576")
    }

    @Test("Test BlkioDeviceRate parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            path: ${DEVICE_PATH}
            rate: "12mb"
            """
        let node = try Yams.compose(yaml: yaml)
        let rate = try Service.BlkioDeviceRate(
            node!,
            envs: ["DEVICE_PATH": "/dev/sda"]
        )
        #expect(rate.path == "/dev/sda")
    }

    @Test("Test BlkioDeviceRate parsing - missing path throws")
    func parseMissingPath() throws {
        let node = try Yams.compose(yaml: "rate: \"12mb\"")
        #expect(throws: (any Error).self) {
            try Service.BlkioDeviceRate(node!, envs: [:])
        }
    }

    @Test("Test BlkioDeviceRate parsing - missing rate throws")
    func parseMissingRate() throws {
        let node = try Yams.compose(yaml: "path: /dev/sda")
        #expect(throws: (any Error).self) {
            try Service.BlkioDeviceRate(node!, envs: [:])
        }
    }

    @Test("Test BlkioDeviceRate parsing - non-mapping node throws")
    func parseNonMapping() throws {
        let node = try Yams.compose(yaml: "just_a_string")
        #expect(throws: (any Error).self) {
            try Service.BlkioDeviceRate(node!, envs: [:])
        }
    }
}
