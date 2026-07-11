//
//  ServiceVolumeTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("Service.Volume Parsing Tests")
struct ServiceVolumeTestSuite {

    // Short syntax

    @Test("Short - anonymous volume: target only")
    func short_anonymousTargetOnly() throws {
        let node = try Yams.compose(yaml: "\"/var/lib/data\"")
        let vol = try Service.Volume(node!, envs: [:])
        #expect(vol.source == nil as String?)
        #expect(vol.target == "/var/lib/data")
        #expect(vol.type == Service.VolumeType.volume)
        #expect(vol.read_only == nil as Bool?)
    }

    @Test("Short - named volume with target")
    func short_namedWithTarget() throws {
        let node = try Yams.compose(yaml: "\"db-data:/var/lib/mysql\"")
        let vol = try Service.Volume(node!, envs: [:])
        #expect(vol.source == "db-data")
        #expect(vol.target == "/var/lib/mysql")
        #expect(vol.type == Service.VolumeType.volume)
    }

    @Test("Short - bind mount with options")
    func short_bindWithOptions() throws {
        let node = try Yams.compose(
            yaml: "\"./data:/var/lib/data:ro,z,rshared,cached\""
        )
        let vol = try Service.Volume(node!, envs: [:])
        #expect(vol.type == Service.VolumeType.bind)
        #expect(vol.read_only == true)
        #expect(vol.bind?.selinux == "z")
        #expect(vol.bind?.propagation == Service.BindPropagation.rshared)
        #expect(vol.consistency == "cached")
    }

    @Test("Short - windows drive letter path preserved")
    func short_windowsDrive() throws {
        let node = try Yams.compose(
            yaml: "\"C:\\\\data:/var/lib/data:rw,delegated\""
        )
        let vol = try Service.Volume(node!, envs: [:])
        #expect((vol.source ?? "").hasPrefix("C:"))
        #expect(vol.read_only == false)
        #expect(vol.consistency == "delegated")
        #expect(vol.type == Service.VolumeType.bind)
    }

    @Test("Short - env interpolation")
    func short_envInterpolation() throws {
        let node = try Yams.compose(yaml: "\"${SRC}:/app/data:ro\"")
        let vol = try Service.Volume(node!, envs: ["SRC": "./data"])
        #expect(vol.source == "./data")
        #expect(vol.target == "/app/data")
        #expect(vol.read_only == true)
    }

    @Test(
        "Short - invalid strings throw",
        arguments: [
            "\"a:b:c:d\"",
            "\"\"",
        ]
    )
    func short_invalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            let _ = try Service.Volume(node!, envs: [:])
        }
    }

    // Long syntax

    @Test("Long - minimal mapping (target only, defaults to volume)")
    func long_minimal() throws {
        let node = try Yams.compose(yaml: "target: /data")
        let vol = try Service.Volume(node!, envs: [:])
        #expect(vol.type == Service.VolumeType.volume)
        #expect(vol.target == "/data")
        #expect(vol.source == nil as String?)
        #expect(vol.read_only == nil as Bool?)
        #expect(vol.bind == nil as Service.BindOptions?)
        #expect(vol.volume == nil as Service.VolumeOptions?)
        #expect(vol.tmpfs == nil as Service.TmpfsOptions?)
        #expect(vol.consistency == nil as String?)
    }

    @Test("Long - full mapping with bind options")
    func long_fullBind() throws {
        let yaml = """
            type: bind
            source: ./data
            target: /data
            read_only: true
            bind:
              propagation: rshared
              create_host_path: true
              selinux: "Z"
            consistency: cached
            """
        let node = try Yams.compose(yaml: yaml)
        let vol = try Service.Volume(node!, envs: [:])
        #expect(vol.type == Service.VolumeType.bind)
        #expect(vol.source == "./data")
        #expect(vol.target == "/data")
        #expect(vol.read_only == true)
        #expect(vol.bind?.propagation == Service.BindPropagation.rshared)
        #expect(vol.bind?.create_host_path == true)
        #expect(vol.bind?.selinux == "Z")
        #expect(vol.consistency == "cached")
    }

    @Test("Long - volume options and tmpfs")
    func long_volumeAndTmpfs() throws {
        let yaml = """
            type: volume
            source: db-data
            target: /var/lib/mysql
            volume:
              nocopy: true
              subpath: sub/dir
            tmpfs:
              size: 1048576
              mode: 0700
            """
        let node = try Yams.compose(yaml: yaml)
        let vol = try Service.Volume(node!, envs: [:])
        #expect(vol.type == Service.VolumeType.volume)
        #expect(vol.volume?.nocopy == true)
        #expect(vol.volume?.subpath == "sub/dir")
        #expect(vol.tmpfs?.size == 1_048_576)
        #expect(vol.tmpfs?.mode == 700)
    }

    @Test("Long - env interpolation")
    func long_envInterpolation() throws {
        let yaml = """
            type: ${TYPE}
            source: ${SRC}
            target: ${TGT}
            consistency: ${CONSISTENCY}
            """
        let node = try Yams.compose(yaml: yaml)
        let vol = try Service.Volume(
            node!,
            envs: [
                "TYPE": "bind",
                "SRC": "./data",
                "TGT": "/data",
                "CONSISTENCY": "delegated",
            ]
        )
        #expect(vol.type == Service.VolumeType.bind)
        #expect(vol.source == "./data")
        #expect(vol.target == "/data")
        #expect(vol.consistency == "delegated")
    }

    @Test("Long - missing target throws")
    func long_missingTarget() throws {
        let node = try Yams.compose(yaml: "{}")
        #expect(throws: (any Error).self) {
            _ = try Service.Volume(node!, envs: [:])
        }
    }

    @Test(
        "Long - invalid top-level node throws",
        arguments: [
            "[a, b, c]"
        ]
    )
    func long_invalidTop(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            _ = try Service.Volume(node!, envs: [:])
        }
    }
}
