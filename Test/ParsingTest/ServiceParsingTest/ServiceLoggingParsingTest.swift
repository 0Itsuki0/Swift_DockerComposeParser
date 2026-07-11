//
//  ServiceLoggingTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



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
