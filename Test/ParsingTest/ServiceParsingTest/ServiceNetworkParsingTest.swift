//
//  ServiceNetworkTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



@Suite("ServiceNetwork Parsing Tests")
struct ServiceNetworkTestSuite {

    @Test("Test Network parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            aliases:
              - db
              - database
            ipv4_address: 172.16.238.10
            ipv6_address: 2001:3984:3989::10
            """
        let node = try Yams.compose(yaml: yaml)
        let network = try Service.Network(node!, envs: [:])
        #expect(network.aliases == ["db", "database"])
        #expect(network.ipv4_address == "172.16.238.10")
        #expect(network.ipv6_address == "2001:3984:3989::10")
    }

    @Test("Test Network parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let network = try Service.Network(node!, envs: [:])
        #expect(network.aliases == nil)
        #expect(network.ipv4_address == nil)
        #expect(network.ipv6_address == nil)
    }

    @Test("Test Network parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "ipv4_address: ${STATIC_IP}"
        let node = try Yams.compose(yaml: yaml)
        let network = try Service.Network(
            node!,
            envs: ["STATIC_IP": "172.16.238.10"]
        )
        #expect(network.ipv4_address == "172.16.238.10")
    }

    @Test(
        "Test Network parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Network(node!, envs: [:])
        }
    }
}
