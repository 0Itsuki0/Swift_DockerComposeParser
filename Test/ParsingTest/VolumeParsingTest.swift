//
//  VolumeTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams



@Suite("Volume Parsing Tests")
struct VolumeTestSuite {

    @Test("Test Volume parsing - all fields present")
    func parseVolumeAllFields() throws {
        let yaml = """
            driver: local
            driver_opts:
              type: nfs
              o: addr=10.40.0.199,nolock,soft,rw
            name: my_named_volume
            labels:
              com.example.description: "database volume"
              com.example.department: "IT"
            """
        let node = try Yams.compose(yaml: yaml)
        let volume = try Volume(node!, envs: [:])

        #expect(volume.driver == "local")
        #expect(volume.driver_opts?["type"] == "nfs")
        #expect(volume.driver_opts?["o"] == "addr=10.40.0.199,nolock,soft,rw")
        #expect(volume.name == "my_named_volume")
        #expect(volume.labels?["com.example.description"] == "database volume")
        #expect(volume.labels?["com.example.department"] == "IT")
        #expect(volume.external == nil)
    }

    @Test("Test Volume parsing - empty mapping yields all nil")
    func parseVolumeEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let volume = try Volume(node!, envs: [:])

        #expect(volume.driver == nil)
        #expect(volume.driver_opts == nil)
        #expect(volume.name == nil)
        #expect(volume.labels == nil)
        #expect(volume.external == nil)
    }

    @Test("Test Volume parsing - external as boolean true")
    func parseVolumeExternalBool() throws {
        let yaml = """
            external: true
            """
        let node = try Yams.compose(yaml: yaml)
        let volume = try Volume(node!, envs: [:])

        #expect(volume.external == true)
    }

    @Test("Test Volume parsing - external as boolean false")
    func parseVolumeExternalBoolFalse() throws {
        let yaml = """
            external: false
            """
        let node = try Yams.compose(yaml: yaml)
        let volume = try Volume(node!, envs: [:])

        #expect(volume.external == false)
    }

    @Test("Test Volume parsing - env var interpolation")
    func parseVolumeEnvInterpolation() throws {
        let yaml = """
            name: ${PROJECT_NAME}_data
            driver_opts:
              device: ${DEVICE_PATH}
            labels:
              owner: ${OWNER}
            external: true
            """
        let node = try Yams.compose(yaml: yaml)
        let volume = try Volume(
            node!,
            envs: [
                "PROJECT_NAME": "myapp",
                "DEVICE_PATH": "/dev/sdb1",
                "OWNER": "platform-team",
            ]
        )

        #expect(volume.name == "myapp_data")
        #expect(volume.driver_opts?["device"] == "/dev/sdb1")
        #expect(volume.labels?["owner"] == "platform-team")
    }

    @Test(
        "Test Volume parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseVolumeInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Volume(node!, envs: [:])
        }
    }
}
