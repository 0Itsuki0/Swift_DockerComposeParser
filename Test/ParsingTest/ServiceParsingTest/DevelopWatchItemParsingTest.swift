//
//  DevelopWatchItemTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



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
