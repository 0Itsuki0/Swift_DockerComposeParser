//
//  EnvFileEntryTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



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
