//
//  GpuDeviceTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams


@Suite("GpuDevice Parsing Tests")
struct GpuDeviceTestSuite {

    @Test("Test GpuDevice parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            driver: nvidia
            count: 2
            device_ids:
              - "0"
              - "1"
            capabilities:
              - gpu
              - utility
            options:
              key: value
            """
        let node = try Yams.compose(yaml: yaml)
        let device = try Service.GpuDevice(node!, envs: [:])

        #expect(device.driver == "nvidia")
        #expect(device.count == 2)
        #expect(device.device_ids == ["0", "1"])
        #expect(device.capabilities == ["gpu", "utility"])
        #expect(device.options?["key"] == "value")
    }

    @Test("Test GpuDevice parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let device = try Service.GpuDevice(node!, envs: [:])
        #expect(device.driver == nil)
        #expect(device.count == nil)
        #expect(device.device_ids == nil)
        #expect(device.capabilities == nil)
        #expect(device.options == nil)
    }

    @Test("Test GpuDevice parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            driver: ${GPU_DRIVER}
            options:
              key: ${OPTION_VALUE}
            """
        let node = try Yams.compose(yaml: yaml)
        let device = try Service.GpuDevice(
            node!,
            envs: ["GPU_DRIVER": "nvidia", "OPTION_VALUE": "value"]
        )
        #expect(device.driver == "nvidia")
        #expect(device.options?["key"] == "value")
    }

    @Test(
        "Test GpuDevice parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.GpuDevice(node!, envs: [:])
        }
    }
}
