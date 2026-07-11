//
//  IncludeTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams


@Suite("Include Parsing Tests")
struct IncludeTestSuite {

    @Test(
        "Test Include object parsing",
        arguments: [
            """
            path: ../commons/compose2.yaml
            project_directory: ..
            env_file: ../another/.env
            """
        ]
    )
    func testIncludeFullObjectParsing(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        let include = try Include(node!, envs: [:])
        #expect(include.path == ["../commons/compose2.yaml"])
        #expect(include.project_directory == "..")
        #expect(include.env_file == ["../another/.env"])
    }

    @Test(
        "Test Include array parsing",
        arguments: [
            """
            - ../commons/compose.yaml
            - ../another_domain/compose.yaml
            """
        ]
    )
    func testIncludeArrayParsing(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        let envs = ["BASE": "../commons"]
        #expect(node != nil)
        let include = try Include(node!, envs: envs)
        #expect(include.path.count == 2)
    }

    @Test(
        "Test array path parsing",
        arguments: [
            """
            path:
               - ${BASE}/compose.yaml
               - ./commons-override.yaml
            """
        ]
    )
    func parseArrayPath(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        let envs = ["BASE": "../commons"]

        #expect(node != nil)

        let include = try Include(node!, envs: envs)
        #expect(include.path.count == 2)
        #expect(include.path.contains("../commons/compose.yaml"))
    }

    @Test(
        "Test single path parsing",
        arguments: [
            """
            path: ../commons/compose.yaml
            """
        ]
    )
    func parseSinglePath(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        let envs = ["BASE": "../commons"]

        #expect(node != nil)

        let include = try Include(node!, envs: envs)
        #expect(include.path.count == 1)
    }
}
