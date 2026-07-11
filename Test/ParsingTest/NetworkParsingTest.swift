//
//  IPAMTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams




@Suite("IPAM Parsing Tests")
struct IPAMTestSuite {

    @Test("Test IPAM parsing - all fields present")
    func parseIPAMAllFields() throws {
        let yaml = """
            driver: default
            config:
              - subnet: 172.28.0.0/16
                ip_range: 172.28.5.0/24
                gateway: 172.28.5.254
              - subnet: 2001:3984:3989::/64
                gateway: 2001:3984:3989::1
            options:
              foo: bar
            """
        let node = try Yams.compose(yaml: yaml)
        let ipam = try Network.IPAM(node!, envs: [:])

        #expect(ipam.driver == "default")
        #expect(ipam.config?.count == 2)
        #expect(ipam.config?[0].subnet == "172.28.0.0/16")
        #expect(ipam.config?[0].ip_range == "172.28.5.0/24")
        #expect(ipam.config?[0].gateway == "172.28.5.254")
        #expect(ipam.config?[1].subnet == "2001:3984:3989::/64")
        #expect(ipam.config?[1].isIPV4 == false)
        #expect(ipam.options?["foo"] == "bar")
    }

    @Test("Test IPAM parsing - empty mapping yields all nil")
    func parseIPAMEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let ipam = try Network.IPAM(node!, envs: [:])

        #expect(ipam.driver == nil)
        #expect(ipam.config == nil)
        #expect(ipam.options == nil)
    }

    @Test("Test IPAM parsing - only driver present")
    func parseIPAMOnlyDriver() throws {
        let yaml = "driver: default"
        let node = try Yams.compose(yaml: yaml)
        let ipam = try Network.IPAM(node!, envs: [:])

        #expect(ipam.driver == "default")
        #expect(ipam.config == nil)
        #expect(ipam.options == nil)
    }

    @Test("Test IPAM parsing - env var interpolation")
    func parseIPAMEnvInterpolation() throws {
        let yaml = """
            driver: ${NETWORK_DRIVER}
            config:
              - subnet: ${SUBNET_CIDR}
            options:
              key: ${OPTION_VALUE}
            """
        let node = try Yams.compose(yaml: yaml)
        let ipam = try Network.IPAM(
            node!,
            envs: [
                "NETWORK_DRIVER": "default",
                "SUBNET_CIDR": "172.28.0.0/16",
                "OPTION_VALUE": "bar",
            ]
        )

        #expect(ipam.driver == "default")
        #expect(ipam.config?[0].subnet == "172.28.0.0/16")
        #expect(ipam.options?["key"] == "bar")
    }

    @Test(
        "Test IPAM parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseIPAMInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Network.IPAM(node!, envs: [:])
        }
    }
}

@Suite("IPAMConfig Parsing Tests")
struct IPAMConfigTestSuite {

    @Test("Test IPAMConfig parsing - all fields present (IPv4)")
    func parseIPAMConfigIPv4() throws {
        let yaml = """
            subnet: 172.28.0.0/16
            ip_range: 172.28.5.0/24
            gateway: 172.28.5.254
            aux_addresses:
              host1: 172.28.1.5
              host2: 172.28.1.6
            """
        let node = try Yams.compose(yaml: yaml)
        let config = try Network.IPAMConfig(node!, envs: [:])

        #expect(config.subnet == "172.28.0.0/16")
        #expect(config.ip_range == "172.28.5.0/24")
        #expect(config.gateway == "172.28.5.254")
        #expect(config.aux_addresses?["host1"] == "172.28.1.5")
        #expect(config.aux_addresses?["host2"] == "172.28.1.6")
        #expect(config.isIPV4 == true)
    }

    @Test("Test IPAMConfig parsing - IPv6 subnet")
    func parseIPAMConfigIPv6() throws {
        let yaml = "subnet: 2001:3984:3989::/64"
        let node = try Yams.compose(yaml: yaml)
        let config = try Network.IPAMConfig(node!, envs: [:])

        #expect(config.isIPV4 == false)
    }

    @Test("Test IPAMConfig parsing - empty mapping yields all nil")
    func parseIPAMConfigEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let config = try Network.IPAMConfig(node!, envs: [:])

        #expect(config.subnet == nil)
        #expect(config.ip_range == nil)
        #expect(config.gateway == nil)
        #expect(config.aux_addresses == nil)
        #expect(config.isIPV4 == false)
    }

    @Test("Test IPAMConfig parsing - env var interpolation")
    func parseIPAMConfigEnvInterpolation() throws {
        let yaml = """
            subnet: ${SUBNET}
            gateway: ${GATEWAY}
            """
        let node = try Yams.compose(yaml: yaml)
        let config = try Network.IPAMConfig(
            node!,
            envs: [
                "SUBNET": "172.28.0.0/16",
                "GATEWAY": "172.28.5.254",
            ]
        )

        #expect(config.subnet == "172.28.0.0/16")
        #expect(config.gateway == "172.28.5.254")
    }

    @Test(
        "Test IPAMConfig parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseIPAMConfigInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Network.IPAMConfig(node!, envs: [:])
        }
    }
}

@Suite("Network Parsing Tests")
struct NetworkTestSuite {

    @Test("Test Network parsing - all fields present")
    func parseNetworkAllFields() throws {
        let yaml = """
            driver: bridge
            driver_opts:
              com.docker.network.bridge.name: br0
            attachable: true
            enable_ipv4: true
            enable_ipv6: false
            internal: true
            labels:
              com.example.description: "frontend network"
            name: my_network
            ipam:
              driver: default
              config:
                - subnet: 172.28.0.0/16
                  gateway: 172.28.5.254
            """
        let node = try Yams.compose(yaml: yaml)
        let network = try Network(node!, envs: [:])

        #expect(network.driver == "bridge")
        #expect(network.driver_opts?["com.docker.network.bridge.name"] == "br0")
        #expect(network.attachable == true)
        #expect(network.enable_ipv4 == true)
        #expect(network.enable_ipv6 == false)
        #expect(network.`internal` == true)
        #expect(
            network.labels?["com.example.description"] == "frontend network"
        )
        #expect(network.name == "my_network")
        #expect(network.ipam?.driver == "default")
        #expect(network.ipam?.config?.first?.subnet == "172.28.0.0/16")
        #expect(network.ipv4 == "172.28.0.0/16")
        #expect(network.ipv6 == nil)
        #expect(network.external == nil)
    }

    @Test("Test Network parsing - empty mapping yields all nil")
    func parseNetworkEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let network = try Network(node!, envs: [:])

        #expect(network.driver == nil)
        #expect(network.driver_opts == nil)
        #expect(network.attachable == nil)
        #expect(network.enable_ipv4 == nil)
        #expect(network.enable_ipv6 == nil)
        #expect(network.`internal` == nil)
        #expect(network.labels == nil)
        #expect(network.name == nil)
        #expect(network.ipam == nil)
        #expect(network.external == nil)
        #expect(network.ipv4 == nil)
        #expect(network.ipv6 == nil)
    }

    @Test("Test Network parsing - external as boolean true")
    func parseNetworkExternalBool() throws {
        let yaml = "external: true"
        let node = try Yams.compose(yaml: yaml)
        let network = try Network(node!, envs: [:])

        #expect(network.external == true)
    }

    @Test(
        "Test Network parsing - ipv4 and ipv6 computed properties with dual stack"
    )
    func parseNetworkDualStackIPAM() throws {
        let yaml = """
            ipam:
              config:
                - subnet: 172.28.0.0/16
                - subnet: 2001:3984:3989::/64
            """
        let node = try Yams.compose(yaml: yaml)
        let network = try Network(node!, envs: [:])

        #expect(network.ipv4 == "172.28.0.0/16")
        #expect(network.ipv6 == "2001:3984:3989::/64")
    }

    @Test("Test Network parsing - env var interpolation")
    func parseNetworkEnvInterpolation() throws {
        let yaml = """
            driver: ${NETWORK_DRIVER}
            name: ${PROJECT_NAME}_net
            labels:
              owner: ${OWNER}
            """
        let node = try Yams.compose(yaml: yaml)
        let network = try Network(
            node!,
            envs: [
                "NETWORK_DRIVER": "bridge",
                "PROJECT_NAME": "myapp",
                "OWNER": "platform-team",
            ]
        )

        #expect(network.driver == "bridge")
        #expect(network.name == "myapp_net")
        #expect(network.labels?["owner"] == "platform-team")
    }

    @Test(
        "Test Network parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseNetworkInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Network(node!, envs: [:])
        }
    }
}
