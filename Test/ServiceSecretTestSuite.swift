//
//  ServiceSecretTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//


//
//  ServiceSecretTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

import DockerComposeParser
import Testing
import Yams

@Suite("Service.Secret Parsing Tests")
struct ServiceSecretTestSuite {

    @Test("Short - bare string source")
    func shortSyntax() throws {
        let node = try Yams.compose(yaml: "my_secret")
        let secret = try Service.Secret(node!, envs: [:])
        #expect(secret.source == "my_secret")
        #expect(secret.target == nil as String?)
        #expect(secret.uid == nil as String?)
        #expect(secret.gid == nil as String?)
        #expect(secret.mode == nil as Int?)
    }

    @Test("Long - full mapping")
    func longFull() throws {
        let yaml = """
        source: my_secret
        target: /run/secrets/db_password
        uid: "103"
        gid: "103"
        mode: 0440
        """
        let node = try Yams.compose(yaml: yaml)
        let secret = try Service.Secret(node!, envs: [:])
        #expect(secret.source == "my_secret")
        #expect(secret.target == "/run/secrets/db_password")
        #expect(secret.uid == "103")
        #expect(secret.gid == "103")
        #expect(secret.mode != nil)
    }

    @Test("Long - only source")
    func longOnlySource() throws {
        let node = try Yams.compose(yaml: "source: my_secret")
        let secret = try Service.Secret(node!, envs: [:])
        #expect(secret.source == "my_secret")
        #expect(secret.target == nil as String?)
    }

    @Test("Env interpolation")
    func envInterpolation() throws {
        let node = try Yams.compose(yaml: "source: ${SEC_NAME}")
        let secret = try Service.Secret(node!, envs: ["SEC_NAME": "my_secret"])
        #expect(secret.source == "my_secret")
    }

    @Test("Invalid - non-mapping non-string throws")
    func invalidNonMapping() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            _ = try Service.Secret(node!, envs: [:])
        }
    }

    @Test("Invalid - mapping without source throws")
    func invalidMissingSource() throws {
        let node = try Yams.compose(yaml: "{}")
        #expect(throws: (any Error).self) {
            _ = try Service.Secret(node!, envs: [:])
        }
    }
}