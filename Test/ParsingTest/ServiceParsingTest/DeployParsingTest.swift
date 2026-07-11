//
//  DeployTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams



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
