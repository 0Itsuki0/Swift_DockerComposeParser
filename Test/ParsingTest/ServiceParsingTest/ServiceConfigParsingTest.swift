//
//  ServiceConfigTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams



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
    
    @Test("Test Dependency parsing - bool with env")
    func parseWithEnv() throws {
        let yaml = """
            condition: service_healthy
            restart: ${VAR}
            required: false
            """
        let node = try Yams.compose(yaml: yaml)
        let dep = try Service.Dependency(node!, envs: ["VAR": "true"])
        #expect(dep.condition == .service_healthy)
        #expect(dep.restart == true)
        #expect(dep.required == false)
    }

    @Test("Test Dependency parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let dep = try Service.Dependency(node!, envs: [:])
        #expect(dep.condition == .default)
        #expect(dep.restart == nil)
        #expect(dep.required == true)
    }

    @Test(
        "Test Dependency parsing - invalid condition value throws"
    )
    func parseInvalidCondition() throws {
        let yaml = "condition: not_a_real_condition"
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Dependency(node!, envs: [:])
        }
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
