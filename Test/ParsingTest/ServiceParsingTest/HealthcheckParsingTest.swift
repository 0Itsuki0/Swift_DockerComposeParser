//
//  HealthcheckTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams




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
