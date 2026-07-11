//
//  ServiceHookTestSuite 2.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams




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
