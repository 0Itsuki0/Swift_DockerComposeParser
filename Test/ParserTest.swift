//
//  DockerComposeParserTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

@testable import DockerComposeParser
import Testing
import Yams

@Suite("Include Parsing Tests")
struct IncludeTestSuite {

    @Test(
        "Test Include object parsing",
        arguments: [
            """
            path: ../commons/compose2.yaml
            project_directory: ..
            env_file: ../another/.env
            """
        ]
    )
    func testIncludeFullObjectParsing(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        let include = try Include(node!, envs: [:])
        #expect(include.path == ["../commons/compose2.yaml"])
        #expect(include.project_directory == "..")
        #expect(include.env_file == ["../another/.env"])
    }

    @Test(
        "Test Include array parsing",
        arguments: [
            """
            - ../commons/compose.yaml
            - ../another_domain/compose.yaml
            """
        ]
    )
    func testIncludeArrayParsing(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        let envs = ["BASE": "../commons"]
        #expect(node != nil)
        let include = try Include(node!, envs: envs)
        #expect(include.path.count == 2)
    }

    @Test(
        "Test array path parsing",
        arguments: [
            """
            path:
               - ${BASE}/compose.yaml
               - ./commons-override.yaml
            """
        ]
    )
    func parseArrayPath(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        let envs = ["BASE": "../commons"]

        #expect(node != nil)

        let include = try Include(node!, envs: envs)
        #expect(include.path.count == 2)
        #expect(include.path.contains("../commons/compose.yaml"))
    }

    @Test(
        "Test single path parsing",
        arguments: [
            """
            path: ../commons/compose.yaml
            """
        ]
    )
    func parseSinglePath(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        let envs = ["BASE": "../commons"]

        #expect(node != nil)

        let include = try Include(node!, envs: envs)
        #expect(include.path.count == 1)
    }
}

@Suite("Secret Parsing Tests")
struct SecretTestSuite {

    @Test(
        "Test Secret parsing - valid cases",
        arguments: [
            // Both fields present.
            """
            file: ./secrets/db_password.txt
            environment: DB_PASSWORD
            """,
            // Only `file` present.
            """
            file: ./secrets/db_password.txt
            """,
            // Only `environment` present.
            """
            environment: DB_PASSWORD
            """,
            // Empty mapping - both fields nil.
            "{}",
        ]
    )
    func parseSecretValid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        let secret = try Secret(node!, envs: [:])
        #expect(secret.file != nil || secret.environment != nil || yaml == "{}")
    }

    @Test("Test Secret parsing - field values are correct")
    func parseSecretFieldValues() throws {
        let yaml = """
            file: ./secrets/db_password.txt
            environment: DB_PASSWORD
            """
        let node = try Yams.compose(yaml: yaml)
        let secret = try Secret(node!, envs: [:])
        #expect(secret.file == "./secrets/db_password.txt")
        #expect(secret.environment == "DB_PASSWORD")
    }

    @Test("Test Secret parsing - empty mapping yields nil fields")
    func parseSecretEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let secret = try Secret(node!, envs: [:])
        #expect(secret.file == nil)
        #expect(secret.environment == nil)
    }

    @Test(
        "Test Secret parsing - environment variable interpolation in file path"
    )
    func parseSecretWithEnvInterpolation() throws {
        let yaml = """
            file: ${SECRET_DIR}/db_password.txt
            environment: DB_PASSWORD
            """
        let node = try Yams.compose(yaml: yaml)
        let secret = try Secret(node!, envs: ["SECRET_DIR": "/run/secrets"])
        #expect(secret.file == "/run/secrets/db_password.txt")
    }

    @Test(
        "Test Secret parsing - invalid cases throw",
        arguments: [
            // Bare scalar string instead of a mapping - Secret has no short syntax.
            "just_a_string",
            // Bare sequence instead of a mapping.
            "[a, b, c]",
        ]
    )
    func parseSecretInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        #expect(throws: (any Error).self) {
            try Secret(node!, envs: [:])
        }
    }

}

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

@Suite("CredentialSpec Parsing Tests")
struct CredentialSpecTestSuite {

    @Test("Test CredentialSpec parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            file: my_credential_spec.json
            registry: my-registry
            config: my_config
            """
        let node = try Yams.compose(yaml: yaml)
        let spec = try Service.CredentialSpec(node!, envs: [:])
        #expect(spec.file == "my_credential_spec.json")
        #expect(spec.registry == "my-registry")
        #expect(spec.config == "my_config")
    }

    @Test("Test CredentialSpec parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let spec = try Service.CredentialSpec(node!, envs: [:])
        #expect(spec.file == nil)
        #expect(spec.registry == nil)
        #expect(spec.config == nil)
    }

    @Test("Test CredentialSpec parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "file: ${CRED_DIR}/spec.json"
        let node = try Yams.compose(yaml: yaml)
        let spec = try Service.CredentialSpec(
            node!,
            envs: ["CRED_DIR": "/run/secrets"]
        )
        #expect(spec.file == "/run/secrets/spec.json")
    }

    @Test(
        "Test CredentialSpec parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.CredentialSpec(node!, envs: [:])
        }
    }
}

@Suite("Deploy Parsing Tests")
struct DeployTestSuite {

    @Test("Test Deploy parsing - full nested structure")
    func parseFullDeploy() throws {
        let yaml = """
            mode: replicated
            replicas: 3
            resources:
              limits:
                cpus: "0.5"
                memory: 512M
              reservations:
                cpus: "0.25"
                memory: 256M
                devices:
                  - capabilities: ["gpu"]
                    driver: nvidia
                    count: "1"
                    device_ids: ["0", "1"]
            restart_policy:
              condition: on-failure
              delay: 5s
              max_attempts: 3
              window: 120s
            """
        let node = try Yams.compose(yaml: yaml)
        let deploy = try Service.Deploy(node!, envs: [:])

        #expect(deploy.mode == "replicated")
        #expect(deploy.replicas == 3)
        #expect(deploy.resources?.limits?.cpus == "0.5")
        #expect(deploy.resources?.limits?.memory == "512M")
        #expect(deploy.resources?.reservations?.cpus == "0.25")
        #expect(deploy.resources?.reservations?.memory == "256M")
        #expect(
            deploy.resources?.reservations?.devices?.first?.capabilities == [
                "gpu"
            ]
        )
        #expect(
            deploy.resources?.reservations?.devices?.first?.driver == "nvidia"
        )
        #expect(deploy.resources?.reservations?.devices?.first?.count == "1")
        #expect(
            deploy.resources?.reservations?.devices?.first?.device_ids == [
                "0", "1",
            ]
        )
        #expect(deploy.restart_policy?.condition == "on-failure")
        #expect(deploy.restart_policy?.delay == "5s")
        #expect(deploy.restart_policy?.max_attempts == 3)
        #expect(deploy.restart_policy?.window == "120s")
    }

    @Test("Test Deploy parsing - empty mapping yields all nil")
    func parseEmptyDeploy() throws {
        let node = try Yams.compose(yaml: "{}")
        let deploy = try Service.Deploy(node!, envs: [:])
        #expect(deploy.mode == nil)
        #expect(deploy.replicas == nil)
        #expect(deploy.resources == nil)
        #expect(deploy.restart_policy == nil)
    }

    @Test("Test Deploy parsing - partial resources (limits only)")
    func parsePartialResources() throws {
        let yaml = """
            resources:
              limits:
                memory: 1G
            """
        let node = try Yams.compose(yaml: yaml)
        let deploy = try Service.Deploy(node!, envs: [:])
        #expect(deploy.resources?.limits?.memory == "1G")
        #expect(deploy.resources?.limits?.cpus == nil)
        #expect(deploy.resources?.reservations == nil)
    }

    @Test("Test Deploy parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            mode: ${DEPLOY_MODE}
            resources:
              limits:
                memory: ${MEMORY_LIMIT}
            """
        let node = try Yams.compose(yaml: yaml)
        let deploy = try Service.Deploy(
            node!,
            envs: ["DEPLOY_MODE": "global", "MEMORY_LIMIT": "1G"]
        )
        #expect(deploy.mode == "global")
        #expect(deploy.resources?.limits?.memory == "1G")
    }

    @Test(
        "Test Deploy parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalidDeploy(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Deploy(node!, envs: [:])
        }
    }

    @Test("Test DeviceReservation parsing - empty mapping yields all nil")
    func parseDeviceReservationEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let reservation = try Service.DeviceReservation(node!, envs: [:])
        #expect(reservation.capabilities == nil)
        #expect(reservation.driver == nil)
        #expect(reservation.count == nil)
        #expect(reservation.device_ids == nil)
    }
}

@Suite("Develop Parsing Tests")
struct DevelopTestSuite {

    @Test("Test Develop parsing - watch list present")
    func parseWatchList() throws {
        let yaml = """
            watch:
              - path: ./src
                action: sync
                target: /app/src
                ignore:
                  - node_modules/
              - path: ./package.json
                action: rebuild
            """
        let node = try Yams.compose(yaml: yaml)
        let develop = try Service.Develop(node!, envs: [:])

        #expect(develop.watch?.count == 2)
        #expect(develop.watch?[0].path == "./src")
        #expect(develop.watch?[0].action == "sync")
        #expect(develop.watch?[0].target == "/app/src")
        #expect(develop.watch?[0].ignore == ["node_modules/"])
        #expect(develop.watch?[1].path == "./package.json")
        #expect(develop.watch?[1].action == "rebuild")
        #expect(develop.watch?[1].target == nil)
        #expect(develop.watch?[1].ignore == nil)
    }

    @Test("Test Develop parsing - empty mapping yields nil watch")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let develop = try Service.Develop(node!, envs: [:])
        #expect(develop.watch == nil)
    }

    @Test(
        "Test Develop parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Develop(node!, envs: [:])
        }
    }
}

@Suite("DevelopWatchItem Parsing Tests")
struct DevelopWatchItemTestSuite {

    @Test("Test DevelopWatchItem parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            path: ./src
            action: sync
            target: /app/src
            ignore:
              - node_modules/
              - "*.log"
            """
        let node = try Yams.compose(yaml: yaml)
        let item = try Service.DevelopWatchItem(node!, envs: [:])

        #expect(item.path == "./src")
        #expect(item.action == "sync")
        #expect(item.target == "/app/src")
        #expect(item.ignore == ["node_modules/", "*.log"])
    }

    @Test("Test DevelopWatchItem parsing - only required fields")
    func parseRequiredOnly() throws {
        let yaml = """
            path: ./src
            action: rebuild
            """
        let node = try Yams.compose(yaml: yaml)
        let item = try Service.DevelopWatchItem(node!, envs: [:])
        #expect(item.path == "./src")
        #expect(item.action == "rebuild")
        #expect(item.target == nil)
        #expect(item.ignore == nil)
    }

    @Test("Test DevelopWatchItem parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            path: ${SRC_DIR}
            action: sync
            target: ${TARGET_DIR}
            """
        let node = try Yams.compose(yaml: yaml)
        let item = try Service.DevelopWatchItem(
            node!,
            envs: ["SRC_DIR": "./src", "TARGET_DIR": "/app/src"]
        )
        #expect(item.path == "./src")
        #expect(item.target == "/app/src")
    }

    @Test("Test DevelopWatchItem parsing - missing path throws")
    func parseMissingPath() throws {
        let node = try Yams.compose(yaml: "action: sync")
        #expect(throws: (any Error).self) {
            try Service.DevelopWatchItem(node!, envs: [:])
        }
    }

    @Test("Test DevelopWatchItem parsing - missing action throws")
    func parseMissingAction() throws {
        let node = try Yams.compose(yaml: "path: ./src")
        #expect(throws: (any Error).self) {
            try Service.DevelopWatchItem(node!, envs: [:])
        }
    }

    @Test("Test DevelopWatchItem parsing - non-mapping node throws")
    func parseNonMapping() throws {
        let node = try Yams.compose(yaml: "just_a_string")
        #expect(throws: (any Error).self) {
            try Service.DevelopWatchItem(node!, envs: [:])
        }
    }
}

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

@Suite("Healthcheck Parsing Tests")
struct HealthcheckTestSuite {

    @Test("Test Healthcheck parsing - test as array")
    func parseTestArray() throws {
        let yaml = """
            test: ["CMD", "curl", "-f", "http://localhost"]
            interval: 30s
            timeout: 10s
            retries: 3
            start_period: 40s
            """
        let node = try Yams.compose(yaml: yaml)
        let hc = try Service.Healthcheck(node!, envs: [:])

        #expect(hc.test == ["CMD", "curl", "-f", "http://localhost"])
        #expect(hc.interval == "30s")
        #expect(hc.timeout == "10s")
        #expect(hc.retries == 3)
        #expect(hc.start_period == "40s")
    }

    @Test(
        "Test Healthcheck parsing - test as single string wrapped as CMD-SHELL"
    )
    func parseTestString() throws {
        let yaml = """
            test: curl -f http://localhost || exit 1
            """
        let node = try Yams.compose(yaml: yaml)
        let hc = try Service.Healthcheck(node!, envs: [:])
        #expect(hc.test == ["CMD-SHELL", "curl -f http://localhost || exit 1"])
    }

    @Test("Test Healthcheck parsing - test: [NONE] disables check")
    func parseTestNoneArray() throws {
        let yaml = "test: [\"NONE\"]"
        let node = try Yams.compose(yaml: yaml)
        let hc = try Service.Healthcheck(node!, envs: [:])
        #expect(hc.test == ["NONE"])
        #expect(hc.isDisabled == true)
    }

    @Test(
        "Test Healthcheck parsing - bare string 'NONE' is wrapped, not disabled"
    )
    func parseTestNoneBareString() throws {
        let yaml = "test: NONE"
        let node = try Yams.compose(yaml: yaml)
        let hc = try Service.Healthcheck(node!, envs: [:])
        #expect(hc.test == ["CMD-SHELL", "NONE"])
        #expect(hc.isDisabled == false)
    }

    @Test("Test Healthcheck parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let hc = try Service.Healthcheck(node!, envs: [:])
        #expect(hc.test == nil)
        #expect(hc.start_period == nil)
        #expect(hc.interval == nil)
        #expect(hc.retries == nil)
        #expect(hc.timeout == nil)
    }

    @Test("Test Healthcheck parsing - execArguments for CMD")
    func parseExecArgumentsCmd() throws {
        let yaml = """
            test: ["CMD", "curl", "-f", "http://localhost"]
            """
        let node = try Yams.compose(yaml: yaml)
        let hc = try Service.Healthcheck(node!, envs: [:])
        #expect(hc.execArguments == ["curl", "-f", "http://localhost"])
    }

    @Test("Test Healthcheck parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            test: ${HEALTHCHECK_CMD}
            interval: ${INTERVAL}
            """
        let node = try Yams.compose(yaml: yaml)
        let hc = try Service.Healthcheck(
            node!,
            envs: [
                "HEALTHCHECK_CMD": "curl -f http://localhost",
                "INTERVAL": "30s",
            ]
        )
        #expect(hc.test == ["CMD-SHELL", "curl -f http://localhost"])
        #expect(hc.interval == "30s")
    }

    @Test(
        "Test Healthcheck parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Healthcheck(node!, envs: [:])
        }
    }
}

@Suite("ServiceBuild Parsing Tests")
struct ServiceBuildTestSuite {

    @Test("Test Build parsing - short syntax (bare string)")
    func parseShortSyntax() throws {
        let node = try Yams.compose(yaml: ".")
        let build = try Service.Build(node!, envs: [:])
        #expect(build.context == ".")
        #expect(build.dockerfile == nil)
        #expect(build.args == nil)
    }

    @Test("Test Build parsing - long syntax with all fields")
    func parseLongSyntaxAllFields() throws {
        let yaml = """
            context: ./backend
            dockerfile: Dockerfile.prod
            args:
              NODE_ENV: production
            """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.context == "./backend")
        #expect(build.dockerfile == "Dockerfile.prod")
        #expect(build.args?["NODE_ENV"] == "production")
    }
    
    @Test("Test Build parsing - long syntax with cache_from and cache_to")
    func parseLongSyntaxWithCache() throws {
        let yaml = """
        context: ./backend
        cache_from:
          - user/app:cache
          - type=local,src=path/to/cache
        cache_to:
          - type=registry,ref=myregistry/myapp:cache
        """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])

        #expect(build.context == "./backend")
        #expect(build.cache_from?.count == 2)
        #expect(build.cache_from?[0].type == "registry")
        #expect(build.cache_from?[0].options == ["ref": "user/app:cache"])
        #expect(build.cache_from?[1].type == "local")
        #expect(build.cache_from?[1].options["src"] == "path/to/cache")
        #expect(build.cache_to?.count == 1)
        #expect(build.cache_to?[0].type == "registry")
        #expect(build.cache_to?[0].options["ref"] == "myregistry/myapp:cache")
    }

    @Test("Test Build parsing - no cache_from/cache_to yields nil")
    func parseNoCacheFields() throws {
        let yaml = "context: ./backend"
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.cache_from == nil)
        #expect(build.cache_to == nil)
    }

    @Test("Test Build parsing - env var interpolation in cache_from")
    func parseCacheFromEnvInterpolation() throws {
        let yaml = """
        context: .
        cache_from:
          - ${REGISTRY}/myapp:cache
        """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: ["REGISTRY": "myregistry"])
        #expect(build.cache_from?.first?.options["ref"] == "myregistry/myapp:cache")
    }


    @Test("Test Build parsing - long syntax with only context")
    func parseLongSyntaxContextOnly() throws {
        let yaml = "context: ./backend"
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.context == "./backend")
        #expect(build.dockerfile == nil)
        #expect(build.args == nil)
    }

    @Test("Test Build parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "context: ${BUILD_CONTEXT}"
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(
            node!,
            envs: ["BUILD_CONTEXT": "./backend"]
        )
        #expect(build.context == "./backend")
    }

    @Test("Test Build parsing - missing context in long syntax throws")
    func parseMissingContext() throws {
        let node = try Yams.compose(yaml: "dockerfile: Dockerfile.prod")
        #expect(throws: (any Error).self) {
            try Service.Build(node!, envs: [:])
        }
    }

    @Test("Test Build parsing - invalid sequence node throws")
    func parseInvalidSequence() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            try Service.Build(node!, envs: [:])
        }
    }
}

@Suite("ServiceConfig Parsing Tests")
struct ServiceConfigTestSuite {

    @Test("Test Config parsing - short syntax (bare string)")
    func parseShortSyntax() throws {
        let node = try Yams.compose(yaml: "my_config")
        let config = try Service.Config(node!, envs: [:])
        #expect(config.source == "my_config")
        #expect(config.target == nil)
        #expect(config.uid == nil)
        #expect(config.gid == nil)
        #expect(config.mode == nil)
    }

    @Test("Test Config parsing - long syntax with all fields")
    func parseLongSyntaxAllFields() throws {
        let yaml = """
            source: my_config
            target: /etc/my_config
            uid: "103"
            gid: "103"
            mode: 0440
            """
        let node = try Yams.compose(yaml: yaml)
        let config = try Service.Config(node!, envs: [:])
        #expect(config.source == "my_config")
        #expect(config.target == "/etc/my_config")
        #expect(config.uid == "103")
        #expect(config.gid == "103")
        #expect(config.mode != nil)
    }

    @Test("Test Config parsing - long syntax with only source")
    func parseLongSyntaxSourceOnly() throws {
        let yaml = "source: my_config"
        let node = try Yams.compose(yaml: yaml)
        let config = try Service.Config(node!, envs: [:])
        #expect(config.source == "my_config")
        #expect(config.target == nil)
    }

    @Test("Test Config parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "source: ${CONFIG_NAME}"
        let node = try Yams.compose(yaml: yaml)
        let config = try Service.Config(
            node!,
            envs: ["CONFIG_NAME": "my_config"]
        )
        #expect(config.source == "my_config")
    }

    @Test("Test Config parsing - missing source in long syntax throws")
    func parseMissingSource() throws {
        let node = try Yams.compose(yaml: "target: /etc/my_config")
        #expect(throws: (any Error).self) {
            try Service.Config(node!, envs: [:])
        }
    }

    @Test("Test Config parsing - invalid sequence node throws")
    func parseInvalidSequence() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            try Service.Config(node!, envs: [:])
        }
    }
}

@Suite("ServiceDependency Parsing Tests")
struct ServiceDependencyTestSuite {

    @Test("Test Dependency parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            condition: service_healthy
            restart: true
            required: false
            """
        let node = try Yams.compose(yaml: yaml)
        let dep = try Service.Dependency(node!, envs: [:])
        #expect(dep.condition == .service_healthy)
        #expect(dep.restart == true)
        #expect(dep.required == false)
    }

    @Test("Test Dependency parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let dep = try Service.Dependency(node!, envs: [:])
        #expect(dep.condition == nil)
        #expect(dep.restart == nil)
        #expect(dep.required == nil)
    }

    @Test(
        "Test Dependency parsing - invalid condition value yields nil condition"
    )
    func parseInvalidCondition() throws {
        let yaml = "condition: not_a_real_condition"
        let node = try Yams.compose(yaml: yaml)
        let dep = try Service.Dependency(node!, envs: [:])
        #expect(dep.condition == nil)
    }

    @Test(
        "Test Dependency parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Dependency(node!, envs: [:])
        }
    }
}

@Suite("ServiceExtends Parsing Tests")
struct ServiceExtendsTestSuite {

    @Test("Test ServiceExtends parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            service: base_service
            file: common-services.yaml
            """
        let node = try Yams.compose(yaml: yaml)
        let extends = try Service.Extends(node!, envs: [:])
        #expect(extends.service == "base_service")
        #expect(extends.file == "common-services.yaml")
    }

    @Test("Test ServiceExtends parsing - only service present")
    func parseServiceOnly() throws {
        let yaml = "service: base_service"
        let node = try Yams.compose(yaml: yaml)
        let extends = try Service.Extends(node!, envs: [:])
        #expect(extends.service == "base_service")
        #expect(extends.file == nil)
    }

    @Test("Test ServiceExtends parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "service: ${BASE_SERVICE}"
        let node = try Yams.compose(yaml: yaml)
        let extends = try Service.Extends(
            node!,
            envs: ["BASE_SERVICE": "base_service"]
        )
        #expect(extends.service == "base_service")
    }

    @Test("Test ServiceExtends parsing - missing service throws")
    func parseMissingService() throws {
        let node = try Yams.compose(yaml: "file: common-services.yaml")
        #expect(throws: (any Error).self) {
            try Service.Extends(node!, envs: [:])
        }
    }

    @Test("Test ServiceExtends parsing - non-mapping node throws")
    func parseNonMapping() throws {
        let node = try Yams.compose(yaml: "just_a_string")
        #expect(throws: (any Error).self) {
            try Service.Extends(node!, envs: [:])
        }
    }
}

@Suite("ServiceGpus Parsing Tests")
struct ServiceGpusTestSuite {

    @Test("Test GPU parsing - 'all' string")
    func parseAllString() throws {
        let node = try Yams.compose(yaml: "all")
        let gpu = try Service.GPU(node!, envs: [:])
        #expect(gpu.all == true)
        #expect(gpu.devices == nil)
    }

    @Test("Test GPU parsing - list of device requests")
    func parseDeviceList() throws {
        let yaml = """
            - driver: nvidia
              count: 1
              capabilities: ["gpu"]
            - driver: nvidia
              device_ids: ["0"]
            """
        let node = try Yams.compose(yaml: yaml)
        let gpu = try Service.GPU(node!, envs: [:])
        #expect(gpu.all == false)
        #expect(gpu.devices?.count == 2)
        #expect(gpu.devices?[0].driver == "nvidia")
        #expect(gpu.devices?[0].count == 1)
        #expect(gpu.devices?[1].device_ids == ["0"])
    }

    @Test("Test GPU parsing - single device request (non-array node)")
    func parseSingleDevice() throws {
        let yaml = """
            driver: nvidia
            count: 1
            """
        let node = try Yams.compose(yaml: yaml)
        let gpu = try Service.GPU(node!, envs: [:])
        #expect(gpu.all == false)
        #expect(gpu.devices?.count == 1)
        #expect(gpu.devices?.first?.driver == "nvidia")
    }

    @Test(
        "Test GPU parsing - string other than 'all' is treated as device list, throws"
    )
    func parseNonAllString() throws {
        let node = try Yams.compose(yaml: "none")
        #expect(throws: (any Error).self) {
            try Service.GPU(node!, envs: [:])
        }
    }
}

@Suite("ServiceHook Parsing Tests")
struct ServiceHookTestSuite {

    @Test("Test Hook parsing - command as array, environment as map")
    func parseCommandArrayEnvironmentMap() throws {
        let yaml = """
            command: ["echo", "hello"]
            user: root
            privileged: true
            environment:
              FOO: bar
            """
        let node = try Yams.compose(yaml: yaml)
        let hook = try Service.Hook(node!, envs: [:])

        #expect(hook.command == ["echo", "hello"])
        #expect(hook.user == "root")
        #expect(hook.privileged == true)
        #expect(hook.environment?["FOO"] == "bar")
    }

    @Test("Test Hook parsing - command as single string")
    func parseCommandString() throws {
        let yaml = "command: echo hello"
        let node = try Yams.compose(yaml: yaml)
        let hook = try Service.Hook(node!, envs: [:])
        #expect(hook.command == ["echo hello"])
    }

    @Test("Test Hook parsing - environment as KEY=VALUE list")
    func parseEnvironmentList() throws {
        let yaml = """
            environment:
              - FOO=bar
              - BAZ=qux
            """
        let node = try Yams.compose(yaml: yaml)
        let hook = try Service.Hook(node!, envs: [:])
        #expect(hook.environment?["FOO"] == "bar")
        #expect(hook.environment?["BAZ"] == "qux")
    }

    @Test("Test Hook parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let hook = try Service.Hook(node!, envs: [:])
        #expect(hook.command == nil)
        #expect(hook.user == nil)
        #expect(hook.privileged == nil)
        #expect(hook.environment == nil)
    }

    @Test("Test Hook parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            command: ${HOOK_COMMAND}
            environment:
              FOO: ${FOO_VALUE}
            """
        let node = try Yams.compose(yaml: yaml)
        let hook = try Service.Hook(
            node!,
            envs: ["HOOK_COMMAND": "echo hello", "FOO_VALUE": "bar"]
        )
        #expect(hook.command == ["echo hello"])
        #expect(hook.environment?["FOO"] == "bar")
    }

    @Test(
        "Test Hook parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Hook(node!, envs: [:])
        }
    }
}

@Suite("ServiceLogging Parsing Tests")
struct ServiceLoggingTestSuite {

    @Test("Test Logging parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            driver: json-file
            options:
              max-size: "10m"
              max-file: "3"
            """
        let node = try Yams.compose(yaml: yaml)
        let logging = try Service.Logging(node!, envs: [:])
        #expect(logging.driver == "json-file")
        #expect(logging.options?["max-size"] == "10m")
        #expect(logging.options?["max-file"] == "3")
    }

    @Test("Test Logging parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let logging = try Service.Logging(node!, envs: [:])
        #expect(logging.driver == nil)
        #expect(logging.options == nil)
    }

    @Test("Test Logging parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            driver: ${LOG_DRIVER}
            options:
              max-size: ${MAX_SIZE}
            """
        let node = try Yams.compose(yaml: yaml)
        let logging = try Service.Logging(
            node!,
            envs: ["LOG_DRIVER": "json-file", "MAX_SIZE": "10m"]
        )
        #expect(logging.driver == "json-file")
        #expect(logging.options?["max-size"] == "10m")
    }

    @Test(
        "Test Logging parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Logging(node!, envs: [:])
        }
    }
}

@Suite("ServiceModel Parsing Tests")
struct ServiceModelTestSuite {

    @Test("Test Model parsing - endpoint_var present")
    func parseEndpointVar() throws {
        let yaml = "endpoint_var: MY_MODEL_URL"
        let node = try Yams.compose(yaml: yaml)
        let model = try Service.Model(node!, envs: [:])
        #expect(model.endpoint_var == "MY_MODEL_URL")
    }

    @Test("Test Model parsing - empty mapping yields nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let model = try Service.Model(node!, envs: [:])
        #expect(model.endpoint_var == nil)
    }

    @Test("Test Model parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "endpoint_var: ${ENDPOINT_VAR_NAME}"
        let node = try Yams.compose(yaml: yaml)
        let model = try Service.Model(
            node!,
            envs: ["ENDPOINT_VAR_NAME": "MY_MODEL_URL"]
        )
        #expect(model.endpoint_var == "MY_MODEL_URL")
    }

    @Test(
        "Test Model parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Model(node!, envs: [:])
        }
    }
}

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

// TODO: - Test pending
// starting from Service.Port
//
//  ServicePortParsingTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

@Suite("Service.Port Parsing Tests")
struct ServicePortTestSuite {

    // Short syntax

    @Test("Short syntax - container-only port as string")
    func short_containerOnlyString() throws {
        let node = try Yams.compose(yaml: "\"80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == nil)
        #expect(port.host_ip == nil)
        #expect(port.protocol == nil)
    }

    @Test("Short syntax - container-only port as bare int")
    func short_containerOnlyInt() throws {
        let node = try Yams.compose(yaml: "3000")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "3000")
        #expect(port.published == nil)
        #expect(port.host_ip == nil)
        #expect(port.protocol == nil)
    }

    @Test("Short syntax - host:container")
    func short_hostContainer() throws {
        let node = try Yams.compose(yaml: "\"8080:80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == nil)
        #expect(port.protocol == nil)
    }

    @Test("Short syntax - host_ip:host:container (IPv4)")
    func short_ipv4HostIp() throws {
        let node = try Yams.compose(yaml: "\"127.0.0.1:8080:80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "127.0.0.1")
        #expect(port.protocol == nil)
    }

    @Test("Short syntax - IPv6 bracketed host_ip:host:container")
    func short_ipv6BracketedHostIp() throws {
        let node = try Yams.compose(yaml: "\"[::1]:8080:80\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "::1")
        #expect(port.protocol == nil)
    }

    @Test("Short syntax - with protocol suffix '/udp'")
    func short_protocolUdp() throws {
        let node = try Yams.compose(yaml: "\"8080:80/udp\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.protocol == .udp)
    }

    @Test("Short syntax - container-only with protocol suffix '/tcp'")
    func short_protocolTcpContainerOnly() throws {
        let node = try Yams.compose(yaml: "\"80/tcp\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == nil)
        #expect(port.protocol == .tcp)
    }

    @Test("Short syntax - ranges host and container")
    func short_ranges() throws {
        let node = try Yams.compose(yaml: "\"8000-8003:80-83\"")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80-83")
        #expect(port.published == "8000-8003")
        #expect(port.protocol == nil)
    }

    @Test("Short syntax - env interpolation")
    func short_envInterpolation() throws {
        let node = try Yams.compose(
            yaml: "\"${HOST_PORT}:${CONTAINER_PORT}/udp\""
        )
        let port = try Service.Port(
            node!,
            envs: ["HOST_PORT": "8080", "CONTAINER_PORT": "80"]
        )
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.protocol == .udp)
    }

    @Test(
        "Short syntax - invalid forms throw",
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

    @Test("Long syntax - minimal (target only as string)")
    func long_minimalTargetString() throws {
        let yaml = """
            target: "80"
            """
        let node = try Yams.compose(yaml: yaml)
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "80")
        #expect(port.published == nil)
        #expect(port.host_ip == nil)
        #expect(port.protocol == nil)
        #expect(port.app_protocol == nil)
        #expect(port.mode == nil)
        #expect(port.name == nil)
    }

    @Test("Long syntax - minimal (target only as int)")
    func long_minimalTargetInt() throws {
        let node = try Yams.compose(yaml: "target: 8080")
        let port = try Service.Port(node!, envs: [:])
        #expect(port.target == "8080")
        #expect(port.published == nil)
    }

    @Test("Long syntax - full mapping with all fields")
    func long_fullMapping() throws {
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
        #expect(port.protocol == .udp)
        #expect(port.app_protocol == "http")
        #expect(port.mode == .host)
        #expect(port.name == "web-udp")
    }

    @Test("Long syntax - published as int")
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

    @Test("Long syntax - ranges")
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
        #expect(port.protocol == .tcp)
    }

    @Test("Long syntax - IPv6 host_ip")
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

    @Test("Long syntax - env interpolation")
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
                "NAME": "web",
            ]
        )
        #expect(port.target == "80")
        #expect(port.published == "8080")
        #expect(port.host_ip == "127.0.0.1")
        #expect(port.protocol == .udp)
        #expect(port.app_protocol == "http")
        #expect(port.mode == .ingress)
        #expect(port.name == "web")
    }

    @Test("Long syntax - missing target throws")
    func long_missingTarget() throws {
        let node = try Yams.compose(yaml: "{}")
        #expect(throws: (any Error).self) {
            _ = try Service.Port(node!, envs: [:])
        }
    }

    @Test(
        "Long syntax - invalid top-level node throws",
        arguments: [
            // Sequence instead of mapping
            "[a, b, c]",
            // Malformed short-syntax strings that will be rejected by short parser
            "\"a:b:c:d\"",
            "\"8080:80/badproto\"",
        ]
    )
    func long_invalidTopLevel(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            _ = try Service.Port(node!, envs: [:])
        }
    }
}

@Suite("EnvFileEntry Parsing Tests")
struct EnvFileEntryTestSuite {

    @Test("Test EnvFileEntry parsing - short syntax (bare string)")
    func parseShortSyntax() throws {
        let node = try Yams.compose(yaml: "config.env")
        let entry = try Service.EnvFileEntry(node!, envs: [:])
        #expect(entry.path == "config.env")
        #expect(entry.required == true)
    }

    @Test("Test EnvFileEntry parsing - long syntax with required true")
    func parseLongSyntaxRequiredTrue() throws {
        let yaml = """
            path: config.env
            required: true
            """
        let node = try Yams.compose(yaml: yaml)
        let entry = try Service.EnvFileEntry(node!, envs: [:])
        #expect(entry.path == "config.env")
        #expect(entry.required == true)
    }

    @Test("Test EnvFileEntry parsing - long syntax with required false")
    func parseLongSyntaxRequiredFalse() throws {
        let yaml = """
            path: optional.env
            required: false
            """
        let node = try Yams.compose(yaml: yaml)
        let entry = try Service.EnvFileEntry(node!, envs: [:])
        #expect(entry.path == "optional.env")
        #expect(entry.required == false)
    }

    @Test("Test EnvFileEntry parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "path: ${ENV_DIR}/config.env"
        let node = try Yams.compose(yaml: yaml)
        let entry = try Service.EnvFileEntry(
            node!,
            envs: ["ENV_DIR": "./config"]
        )
        #expect(entry.path == "./config/config.env")
    }

    @Test("Test EnvFileEntry parsing - missing path throws")
    func parseMissingPath() throws {
        let node = try Yams.compose(yaml: "required: true")
        #expect(throws: (any Error).self) {
            try Service.EnvFileEntry(node!, envs: [:])
        }
    }

    @Test("Test EnvFileEntry parsing - required default to true.")
    func parseMissingRequired() throws {
        let node = try Yams.compose(yaml: "path: config.env")
        let parsed = try Service.EnvFileEntry(node!, envs: [:])
        #expect(parsed.required == true)
    }

    @Test("Test EnvFileEntry parsing - invalid sequence node throws")
    func parseInvalidSequence() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            try Service.EnvFileEntry(node!, envs: [:])
        }
    }
}

@Suite("Service Parsing Tests")
struct ServiceTestSuite {

    @Test("Test Service parsing - minimal service with just an image")
    func parseMinimal() throws {
        let yaml = "image: nginx:latest"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.image == "nginx:latest")
        #expect(service.build == nil)
        #expect(service.ports == nil)
    }

    @Test("Test Service parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let service = try Service(node!, envs: [:])
        #expect(service.image == nil)
        #expect(service.build == nil)
        #expect(service.deploy == nil)
        #expect(service.environment == nil)
        #expect(service.depends_on == nil)
        #expect(service.networks == nil)
    }

    @Test("Test Service parsing - build as short syntax string")
    func parseBuildShortSyntax() throws {
        let yaml = """
            image: myapp
            build: .
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.build?.context == ".")
    }

    @Test("Test Service parsing - build as long syntax object")
    func parseBuildLongSyntax() throws {
        let yaml = """
            build:
              context: ./backend
              dockerfile: Dockerfile.prod
              args:
                NODE_ENV: production
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.build?.context == "./backend")
        #expect(service.build?.dockerfile == "Dockerfile.prod")
        #expect(service.build?.args?["NODE_ENV"] == "production")
    }

    @Test("Test Service parsing - environment as map")
    func parseEnvironmentMap() throws {
        let yaml = """
            environment:
              FOO: bar
              BAZ: qux
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.environment?["FOO"] == "bar")
        #expect(service.environment?["BAZ"] == "qux")
    }

    @Test("Test Service parsing - environment as KEY=VALUE list")
    func parseEnvironmentList() throws {
        let yaml = """
            environment:
              - FOO=bar
              - BAZ=qux
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.environment?["FOO"] == "bar")
        #expect(service.environment?["BAZ"] == "qux")
    }

    @Test("Test Service parsing - env_file as single string")
    func parseEnvFileSingleString() throws {
        let yaml = "env_file: config.env"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.env_file?.count == 1)
        #expect(service.env_file?.first?.path == "config.env")
        #expect(service.env_file?.first?.required == true)
    }

    @Test("Test Service parsing - env_file as mixed list")
    func parseEnvFileMixedList() throws {
        let yaml = """
            env_file:
              - config.env
              - path: optional.env
                required: false
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.env_file?.count == 2)
        #expect(service.env_file?[0].path == "config.env")
        #expect(service.env_file?[0].required == true)
        #expect(service.env_file?[1].path == "optional.env")
        #expect(service.env_file?[1].required == false)
    }

    @Test("Test Service parsing - command as single string")
    func parseCommandString() throws {
        let yaml = "command: echo hello"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.command == ["echo hello"])
    }

    @Test("Test Service parsing - command as array")
    func parseCommandArray() throws {
        let yaml = """
            command: ["echo", "hello"]
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.command == ["echo", "hello"])
    }

    @Test("Test Service parsing - depends_on as single string")
    func parseDependsOnString() throws {
        let yaml = "depends_on: db"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.depends_on?.map(\.key) == ["db"])
        #expect(service.depends_on?["db"] != nil)
    }

    @Test("Test Service parsing - depends_on as array")
    func parseDependsOnArray() throws {
        let yaml = """
            depends_on:
              - db
              - cache
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.depends_on?.map(\.key) ?? []) == Set(["db", "cache"])
        )
        #expect(service.depends_on?["db"] != nil)
        #expect(service.depends_on?["cache"] != nil)
    }

    @Test("Test Service parsing - depends_on as map with conditions")
    func parseDependsOnMap() throws {
        let yaml = """
            depends_on:
              db:
                condition: service_healthy
                restart: true
              cache:
                condition: service_started
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.depends_on?.map(\.key) ?? []) == Set(["db", "cache"])
        )
        #expect(service.depends_on?["db"]??.condition == .service_healthy)
        #expect(service.depends_on?["db"]??.restart == true)
        #expect(service.depends_on?["cache"]??.condition == .service_started)
    }

    @Test("Test Service parsing - depends_on map with null value uses defaults")
    func parseDependsOnMapNullValue() throws {
        let yaml = """
            depends_on:
              db:
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.depends_on?.map(\.key) == ["db"])
        #expect(service.depends_on?["db"] != nil)
    }

    @Test("Test Service parsing - networks as array")
    func parseNetworksArray() throws {
        let yaml = """
            networks:
              - frontend
              - backend
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.networks?.map(\.key) ?? [])
                == Set(["frontend", "backend"])
        )
    }

    @Test("Test Service parsing - networks as map with options")
    func parseNetworksMap() throws {
        let yaml = """
            networks:
              frontend:
                ipv4_address: 172.16.238.10
              backend:
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.networks?.map(\.key) ?? [])
                == Set(["frontend", "backend"])
        )
        #expect(service.networks?["frontend"]??.ipv4_address == "172.16.238.10")
        #expect(service.networks?["backend"] != nil)
    }

    @Test("Test Service parsing - entrypoint as single string")
    func parseEntrypointString() throws {
        let yaml = "entrypoint: /entrypoint.sh"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.entrypoint == ["/entrypoint.sh"])
    }

    @Test("Test Service parsing - extra_hosts as list")
    func parseExtraHostsList() throws {
        let yaml = """
            extra_hosts:
              - "somehost:162.242.195.82"
              - "otherhost:50.31.209.229"
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            service.extra_hosts?.contains("somehost:162.242.195.82") == true
        )
    }

    @Test("Test Service parsing - extra_hosts as map")
    func parseExtraHostsMap() throws {
        let yaml = """
            extra_hosts:
              somehost: 162.242.195.82
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.extra_hosts == ["somehost:162.242.195.82"])
    }

    @Test("Test Service parsing - annotations as map")
    func parseAnnotationsMap() throws {
        let yaml = """
            annotations:
              key: value
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.annotations?["key"] == "value")
    }

    @Test("Test Service parsing - annotations as key=value list")
    func parseAnnotationsList() throws {
        let yaml = """
            annotations:
              - key=value
              - other
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.annotations?["key"] == "value")
        #expect(service.annotations?["other"] == "")
    }

    @Test("Test Service parsing - cpus as double")
    func parseCpusDouble() throws {
        let yaml = "cpus: 0.5"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.cpus == 0.5)
    }

    @Test("Test Service parsing - cpus as string")
    func parseCpusString() throws {
        let yaml = "cpus: \"0.5\""
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.cpus == 0.5)
    }

    @Test("Test Service parsing - expose as bare ints")
    func parseExposeInts() throws {
        let yaml = """
            expose:
              - 3000
              - 8000
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.expose == ["3000", "8000"])
    }

    @Test("Test Service parsing - dns as single string normalized to list")
    func parseDnsSingleString() throws {
        let yaml = "dns: 8.8.8.8"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.dns == ["8.8.8.8"])
    }

    @Test("Test Service parsing - dns as list")
    func parseDnsList() throws {
        let yaml = """
            dns:
              - 8.8.8.8
              - 9.9.9.9
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.dns == ["8.8.8.8", "9.9.9.9"])
    }

    @Test("Test Service parsing - models as array")
    func parseModelsArray() throws {
        let yaml = """
            models:
              - my_model
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.models?.map(\.key) == ["my_model"])
        #expect(service.models?["my_model"] != nil)
    }

    @Test("Test Service parsing - models as map with options")
    func parseModelsMap() throws {
        let yaml = """
            models:
              my_model:
                endpoint_var: MY_MODEL_URL
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.models?.map(\.key) == ["my_model"])
        #expect(service.models?["my_model"]??.endpoint_var == "MY_MODEL_URL")
    }

    @Test("Test Service parsing - ulimits map with int and object forms")
    func parseUlimits() throws {
        let yaml = """
            ulimits:
              nproc: 65535
              nofile:
                soft: 20000
                hard: 40000
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.ulimits?["nproc"]??.soft == 65535)
        #expect(service.ulimits?["nproc"]??.hard == 65535)
        #expect(service.ulimits?["nofile"]??.soft == 20000)
        #expect(service.ulimits?["nofile"]??.hard == 40000)
    }

    @Test("Test Service parsing - ports list mixing short and long syntax")
    func parsePortsMixed() throws {
        let yaml = """
            ports:
              - "8080:80"
              - target: 443
                published: "8443"
                protocol: tcp
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.ports?.count == 2)
        #expect(service.ports?[0].target == "80")
        #expect(service.ports?[0].published == "8080")
        #expect(service.ports?[1].target == "443")
        #expect(service.ports?[1].protocol == .tcp)
    }

    @Test("Test Service parsing - volumes list mixing short and long syntax")
    func parseVolumesMixed() throws {
        let yaml = """
            volumes:
              - db-data:/var/lib/mysql
              - type: bind
                source: ./cache
                target: /app/cache
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.volumes?.count == 2)
        #expect(service.volumes?[0].source == "db-data")
        #expect(service.volumes?[0].target == "/var/lib/mysql")
        #expect(service.volumes?[1].type == .bind)
        #expect(service.volumes?[1].target == "/app/cache")
    }

    @Test("Test Service parsing - secrets and configs short syntax")
    func parseSecretsConfigsShortSyntax() throws {
        let yaml = """
            secrets:
              - my_secret
            configs:
              - my_config
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.secrets?.first?.source == "my_secret")
        #expect(service.configs?.first?.source == "my_config")
    }

    @Test("Test Service parsing - post_start and pre_stop hooks")
    func parseHooks() throws {
        let yaml = """
            post_start:
              - command: ["echo", "started"]
            pre_stop:
              - command: ["echo", "stopping"]
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.post_start?.first?.command == ["echo", "started"])
        #expect(service.pre_stop?.first?.command == ["echo", "stopping"])
    }

    @Test("Test Service parsing - gpus as 'all'")
    func parseGpusAll() throws {
        let yaml = "gpus: all"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.gpus?.all == true)
    }

    @Test("Test Service parsing - deploy nested structure")
    func parseDeploy() throws {
        let yaml = """
            deploy:
              mode: replicated
              replicas: 3
              resources:
                limits:
                  memory: 512M
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.deploy?.mode == "replicated")
        #expect(service.deploy?.replicas == 3)
        #expect(service.deploy?.resources?.limits?.memory == "512M")
    }

    @Test("Test Service parsing - env var interpolation across fields")
    func parseEnvInterpolation() throws {
        let yaml = """
            image: ${IMAGE_NAME}
            container_name: ${CONTAINER_NAME}
            environment:
              FOO: ${FOO_VALUE}
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(
            node!,
            envs: [
                "IMAGE_NAME": "myapp:latest",
                "CONTAINER_NAME": "myapp_container",
                "FOO_VALUE": "bar",
            ]
        )
        #expect(service.image == "myapp:latest")
        #expect(service.container_name == "myapp_container")
        #expect(service.environment?["FOO"] == "bar")
    }

    @Test("Test Service parsing - full realistic service")
    func parseFullService() throws {
        let yaml = """
            image: nginx:latest
            container_name: web
            restart: unless-stopped
            ports:
              - "80:80"
              - "443:443"
            environment:
              - NODE_ENV=production
            volumes:
              - ./html:/usr/share/nginx/html:ro
            networks:
              - frontend
            depends_on:
              - api
            labels:
              com.example.description: "web server"
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])

        #expect(service.image == "nginx:latest")
        #expect(service.container_name == "web")
        #expect(service.restart == "unless-stopped")
        #expect(service.ports?.count == 2)
        #expect(service.environment?["NODE_ENV"] == "production")
        #expect(service.volumes?.first?.read_only == true)
        #expect((service.networks?.map(\.key) ?? []) == ["frontend"])
        #expect((service.depends_on?.map(\.key) ?? []) == ["api"])
        #expect(service.labels?["com.example.description"] == "web server")
    }

    @Test(
        "Test Service parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service(node!, envs: [:])
        }
    }
}

@Suite("DockerCompose Parsing Tests")
struct DockerComposeTestSuite {

    @Test("Test DockerCompose parsing - minimal with just services")
    func parseMinimal() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.version == nil)
        #expect(compose.name == nil)
        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.include == nil)
        #expect(compose.models == nil)
        #expect(compose.volumes == nil)
        #expect(compose.networks == nil)
        #expect(compose.configs == nil)
        #expect(compose.secrets == nil)
    }

    @Test("Test DockerCompose parsing - version and name present")
    func parseVersionAndName() throws {
        let yaml = """
            version: "3.8"
            name: myapp
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.version == "3.8")
        #expect(compose.name == "myapp")
    }

    @Test("Test DockerCompose parsing - services with null value (reset)")
    func parseServiceNullValue() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
              worker:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services.keys.contains("worker"))
        if let workerValue = compose.services["worker"] {
            #expect(workerValue == nil)
        } else {
            Issue.record("Expected 'worker' key to be present in services")
        }
    }

    @Test("Test DockerCompose parsing - include as single bare string")
    func parseIncludeSingleString() throws {
        let yaml = """
            include: ../commons/compose.yaml
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.include?.count == 1)
        #expect(compose.include?.first?.path == ["../commons/compose.yaml"])
    }

    @Test(
        "Test DockerCompose parsing - include as list of short syntax entries"
    )
    func parseIncludeList() throws {
        let yaml = """
            include:
              - ../commons/compose.yaml
              - ../another_domain/compose.yaml
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.include?.count == 2)
        #expect(compose.include?[0].path == ["../commons/compose.yaml"])
        #expect(compose.include?[1].path == ["../another_domain/compose.yaml"])
    }

    @Test("Test DockerCompose parsing - include as list of long syntax entries")
    func parseIncludeLongSyntaxList() throws {
        let yaml = """
            include:
              - path: ../commons/compose.yaml
                project_directory: ..
                env_file: ../another/.env
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.include?.count == 1)
        #expect(compose.include?.first?.path == ["../commons/compose.yaml"])
        #expect(compose.include?.first?.project_directory == "..")
    }

    @Test("Test DockerCompose parsing - top-level models map with options")
    func parseModels() throws {
        let yaml = """
            models:
              my_model:
                model: ai/model
                context_size: 1024
                runtime_flags:
                  - "--a-flag"
                  - "--another-flag=42"
              other_model:
                model: ai/other-model
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.models?["my_model"]??.model == "ai/model")
        #expect(compose.models?["my_model"]??.context_size == 1024)
        #expect(
            compose.models?["my_model"]??.runtime_flags == [
                "--a-flag", "--another-flag=42",
            ]
        )
        #expect(compose.models?["other_model"]??.model == "ai/other-model")
        #expect(compose.models?["other_model"]??.context_size == nil)
    }

    @Test("Test DockerCompose parsing - top-level volumes")
    func parseVolumes() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            volumes:
              db-data:
                driver: local
              cache:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.volumes?["db-data"]??.driver == "local")
        #expect(compose.volumes?.keys.contains("cache") == true)
    }

    @Test("Test DockerCompose parsing - top-level networks")
    func parseNetworks() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            networks:
              frontend:
                driver: bridge
              backend:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.networks?["frontend"]??.driver == "bridge")
        #expect(compose.networks?.keys.contains("backend") == true)
    }

    @Test("Test DockerCompose parsing - top-level secrets")
    func parseSecrets() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            secrets:
              my_secret:
                file: ./secrets/db_password.txt
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(
            compose.secrets?["my_secret"]??.file == "./secrets/db_password.txt"
        )
    }

    @Test("Test DockerCompose parsing - missing services throws")
    func parseMissingServices() throws {
        let yaml = "version: \"3.8\""
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try DockerCompose(node!, envs: [:])
        }
    }

    @Test("Test DockerCompose parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            name: ${PROJECT_NAME}
            services:
              web:
                image: ${IMAGE_NAME}
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(
            node!,
            envs: ["PROJECT_NAME": "myapp", "IMAGE_NAME": "nginx:latest"]
        )

        #expect(compose.name == "myapp")
        #expect(compose.services["web"]??.image == "nginx:latest")
    }

    @Test(
        "Test DockerCompose parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try DockerCompose(node!, envs: [:])
        }
    }

    @Test("Test DockerCompose parsing - full realistic compose file")
    func parseFullCompose() throws {
        let yaml = """
            version: "3.8"
            name: myapp
            services:
              web:
                image: nginx:latest
                ports:
                  - "80:80"
                depends_on:
                  - api
              api:
                build: ./api
                environment:
                  - NODE_ENV=production
            volumes:
              db-data:
            networks:
              frontend:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.version == "3.8")
        #expect(compose.name == "myapp")
        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["api"]??.build?.context == "./api")
        #expect(compose.volumes?.keys.contains("db-data") == true)
        #expect(compose.networks?.keys.contains("frontend") == true)
    }
}

@Suite("CacheEntry Parsing Tests")
struct CacheEntryTestSuite {

    @Test("Test CacheEntry parsing - bare name shorthand")
    func parseBareName() throws {
        let node = try Yams.compose(yaml: "myregistry/myapp:buildcache")
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "registry")
        #expect(entry.options == ["ref": "myregistry/myapp:buildcache"])
    }

    @Test("Test CacheEntry parsing - type=registry with ref")
    func parseTypeRegistry() throws {
        let node = try Yams.compose(yaml: "type=registry,ref=myregistry/myapp:buildcache")
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "registry")
        #expect(entry.options == ["ref": "myregistry/myapp:buildcache"])
    }

    @Test("Test CacheEntry parsing - type=local with multiple options")
    func parseTypeLocalMultipleOptions() throws {
        let node = try Yams.compose(yaml: "type=local,src=path/to/cache,mode=max")
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "local")
        #expect(entry.options["src"] == "path/to/cache")
        #expect(entry.options["mode"] == "max")
    }

    @Test("Test CacheEntry parsing - type=gha with no extra options")
    func parseTypeGhaNoOptions() throws {
        let node = try Yams.compose(yaml: "type=gha")
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "gha")
        #expect(entry.options.isEmpty)
    }

    @Test("Test CacheEntry parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let node = try Yams.compose(yaml: "type=registry,ref=${REGISTRY}/myapp:cache")
        let entry = try Service.Build.CacheEntry(
            node!,
            envs: ["REGISTRY": "myregistry"]
        )
        #expect(entry.options["ref"] == "myregistry/myapp:cache")
    }

    @Test("Test CacheEntry parsing - missing type throws")
    func parseMissingType() throws {
        let node = try Yams.compose(yaml: "type=,ref=foo")
        #expect(throws: (any Error).self) {
            try Service.Build.CacheEntry(node!, envs: [:])
        }
    }

    @Test("Test CacheEntry parsing - malformed component throws")
    func parseMalformedComponent() throws {
        let node = try Yams.compose(yaml: "type=local,badcomponent")
        #expect(throws: (any Error).self) {
            try Service.Build.CacheEntry(node!, envs: [:])
        }
    }

    @Test("Test CacheEntry parsing - non-string node throws")
    func parseNonString() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            try Service.Build.CacheEntry(node!, envs: [:])
        }
    }
}

