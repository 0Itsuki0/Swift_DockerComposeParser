//
//  ServicePortsTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//


//
//  ServicePortsTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//
//
//  ServiceVolumeTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//
//
//  ServicePortsTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

@testable import DockerComposeParser
import Testing
import Yams

@Suite("ServicePorts Parsing Tests")
struct ServicePortsTestSuite {

    // Short syntax

    @Test("Short - container-only as string")
    func short_containerOnlyString() throws {
        let node = try Yams.compose(yaml: "\"80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == nil as String?)
        #expect(port.host_ip == nil as String?)
        #expect(port.protocol == nil as Service.PortProtocol?)
    }

    @Test("Short - container-only as bare int")
    func short_containerOnlyInt() throws {
        let node = try Yams.compose(yaml: "3000")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "3000")
        #expect(port.published == nil as String?)
        #expect(port.host_ip == nil as String?)
        #expect(port.protocol == nil as Service.PortProtocol?)
    }

    @Test("Short - host:container")
    func short_hostContainer() throws {
        let node = try Yams.compose(yaml: "\"8080:80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == nil as String?)
        #expect(port.protocol == nil as Service.PortProtocol?)
    }

    @Test("Short - IPv4 host_ip:host:container")
    func short_ipv4HostIp() throws {
        let node = try Yams.compose(yaml: "\"127.0.0.1:8080:80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "127.0.0.1")
    }

    @Test("Short - IPv6 bracketed host_ip:host:container")
    func short_ipv6Bracketed() throws {
        let node = try Yams.compose(yaml: "\"[::1]:8080:80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "::1")
    }

    @Test("Short - protocol suffix '/udp'")
    func short_udpSuffix() throws {
        let node = try Yams.compose(yaml: "\"8080:80/udp\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.protocol == Service.PortProtocol.udp)
    }

    @Test("Short - container-only with '/tcp'")
    func short_tcpSuffixContainerOnly() throws {
        let node = try Yams.compose(yaml: "\"80/tcp\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == nil as String?)
        #expect(port.protocol == Service.PortProtocol.tcp)
    }

    @Test("Short - ranges")
    func short_ranges() throws {
        let node = try Yams.compose(yaml: "\"8000-8003:80-83\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80-83")
        #expect(port.published == "8000-8003")
        #expect(port.protocol == nil as Service.PortProtocol?)
    }

    @Test("Short - env interpolation")
    func short_envInterpolation() throws {
        let node = try Yams.compose(yaml: "\"${HOST_PORT}:${CONTAINER_PORT}/udp\"")
        let port = try Service.Port(
            node!,
            envs: ["HOST_PORT": "8080", "CONTAINER_PORT": "80"]
        )
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.protocol == Service.PortProtocol.udp)
    }

    @Test(
        "Short - invalid forms throw",
        arguments: [
            "\"8080:80/badproto\"",
            "\"[::1]8080:80\"",
            "\"a:b:c:d\"",
        ]
    )
    func short_invalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            _ = try Service.Port(node!, envs: [:])
        }
    }

    // Long syntax

    @Test("Long - minimal (target only string)")
    func long_minimalString() throws {
        let node = try Yams.compose(yaml: "target: \"80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == nil as String?)
        #expect(port.host_ip == nil as String?)
        #expect(port.protocol == nil as Service.PortProtocol?)
        #expect(port.app_protocol == nil as String?)
        #expect(port.mode == nil as Service.Mode?)
        #expect(port.name == nil as String?)
    }

    @Test("Long - minimal (target only int)")
    func long_minimalInt() throws {
        let node = try Yams.compose(yaml: "target: 8080")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "8080")
        #expect(port.published == nil as String?)
    }

    @Test("Long - full mapping")
    func long_full() throws {
        let yaml = """
        target: "80"
        published: "8080"
        host_ip: "127.0.0.1"
        protocol: udp
        app_protocol: http
        mode: host
        name: web-udp
        """
        let node = try Yams.compose(yaml: yaml)
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "127.0.0.1")
        #expect(port.protocol == Service.PortProtocol.udp)
        #expect(port.app_protocol == "http")
        #expect(port.mode == Service.Mode.host)
        #expect(port.name == "web-udp")
    }

    @Test("Long - published as int")
    func long_publishedInt() throws {
        let yaml = """
        target: "80"
        published: 8080
        """
        let node = try Yams.compose(yaml: yaml)
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
    }

    @Test("Long - ranges")
    func long_ranges() throws {
        let yaml = """
        target: "80-83"
        published: "8000-8003"
        protocol: tcp
        """
        let node = try Yams.compose(yaml: yaml)
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80-83")
        #expect(port.published == "8000-8003")
        #expect(port.protocol == Service.PortProtocol.tcp)
    }

    @Test("Long - IPv6 host_ip")
    func long_ipv6HostIp() throws {
        let yaml = """
        target: "80"
        published: "8080"
        host_ip: "::1"
        """
        let node = try Yams.compose(yaml: yaml)
        let port = try Service.Port(node!, envs: [:])
        #expect(port.host_ip == "::1")
    }

    @Test("Long - env interpolation")
    func long_envInterpolation() throws {
        let yaml = """
        target: "${TARGET}"
        published: "${PUBLISHED}"
        host_ip: "${HOST_IP}"
        protocol: ${PROTO}
        app_protocol: "${APP_PROTO}"
        mode: ${MODE}
        name: "${NAME}"
        """
        let node = try Yams.compose(yaml: yaml)
        let port = try Service.Port(
            node!,
            envs: [
                "TARGET": "80",
                "PUBLISHED": "8080",
                "HOST_IP": "127.0.0.1",
                "PROTO": "udp",
                "APP_PROTO": "http",
                "MODE": "ingress",
                "NAME": "web"
            ]
        )
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "127.0.0.1")
        #expect(port.protocol == Service.PortProtocol.udp)
        #expect(port.app_protocol == "http")
        #expect(port.mode == Service.Mode.ingress)
        #expect(port.name == "web")
    }

    @Test("Long - missing target throws")
    func long_missingTarget() throws {
        let node = try Yams.compose(yaml: "{}")
        #expect(throws: (any Error).self) {
            _ = try Service.Port(node!, envs: [:])
        }
    }

    @Test(
        "Long - invalid inputs throw",
        arguments: [
            "[a, b, c]",        // sequence
            "\"a:b:c:d\"",      // malformed short string
            "\"8080:80/badproto\"",
        ]
    )
    func long_invalidTop(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            _ = try Service.Port(node!, envs: [:])
        }
    }
}
