//
//  TagParsingTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//


import DockerComposeParser
import Testing
import Yams

@Suite("Tag Parsing Tests")
struct TagParsingTestSuite {
    
    @Test(
        "Test reset parsing",
        arguments: [
            """
            path: !reset []
            """
        ]
    )
    func testResetParsing(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        let include = try Include(node!, envs:[:])
        #expect(include.path.count == 0)
        #expect(include.tags["path"] == .reset)
    }
    
    @Test(
        "Test reset parsing with no default",
        arguments: [
            """
            path: !reset
            """
        ]
    )
    func testResetParsingWithNoDefault(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        let include = try Include(node!, envs:[:])
        #expect(include.path == [""])
        #expect(include.tags["path"] == .reset)

    }
    
    
    @Test(
        "Test override",
        arguments: [
            """
            path: !override
                - "../commons/compose2.yaml" 
            project_directory: ..
            env_file: ../another/.env
            """
        ]
    )
    func testOverrideParsing(_ yaml: String) async throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(node != nil)
        let include = try Include(node!, envs:[:])
        #expect(include.path == ["../commons/compose2.yaml"])
        #expect(include.tags["path"] == .override)
    }

}
