//
//  CredentialSpecTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



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
