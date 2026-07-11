//
//  ServiceUlimitTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//


//
//  ServiceUlimitTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

@testable import DockerComposeParser
import Testing
import Yams

@Suite("Service.Ulimit Parsing Tests")
struct ServiceUlimitTestSuite {

    @Test("Short - single int applies to soft and hard")
    func short_singleInt() throws {
        let node = try Yams.compose(yaml: "1024")
        let u = try Service.Ulimit(node!, envs: [:])
        #expect(u.soft == 1024)
        #expect(u.hard == 1024)
    }

    @Test("Long - mapping with soft and hard")
    func long_mapping() throws {
        let yaml = """
        soft: 1024
        hard: 2048
        """
        let node = try Yams.compose(yaml: yaml)
        let u = try Service.Ulimit(node!, envs: [:])
        #expect(u.soft == 1024)
        #expect(u.hard == 2048)
    }

    @Test("Env interpolation")
    func envInterpolation() throws {
        let yaml = """
        soft: ${SOFT}
        hard: ${HARD}
        """
        let node = try Yams.compose(yaml: yaml)
        let u = try Service.Ulimit(node!, envs: ["SOFT": "512", "HARD": "1024"])
        #expect(u.soft == 512)
        #expect(u.hard == 1024)
    }

    @Test(
        "Invalid - non-int or non-mapping throws",
        arguments: [
            "\"notAnInt\"",
            "[a, b]",
        ]
    )
    func invalidTop(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            _ = try Service.Ulimit(node!, envs: [:])
        }
    }

    @Test(
        "Invalid - mapping missing fields throws",
        arguments: [
            "soft: 1",
            "hard: 1",
            "{}",
        ]
    )
    func invalidMissingFields(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            _ = try Service.Ulimit(node!, envs: [:])
        }
    }
}
