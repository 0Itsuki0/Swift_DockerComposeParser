//
//  SecretTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams



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
