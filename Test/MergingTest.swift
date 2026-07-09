//
//  MergingTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//



import DockerComposeParser
import Testing
import Yams

@Suite("Megin Tests")
struct MergingTestSuite {
    
    @Test("Test merging with override")
    func testMergingWithOverride() async throws {
        let baseString = """
        path: ../commons/compose2.yaml      
        """
        let mergingString = """
        path: !override
            - ../compose.yaml
        """

        let base = try Include(try Yams.compose(yaml: baseString)!, envs:[:])
        let merging = try Include(try Yams.compose(yaml: mergingString)!, envs:[:])
        #expect(merging.tags["path"] == .override)

        let merged = try base.deepMerge(with: merging)
        #expect(merged.path == ["../compose.yaml"])
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
