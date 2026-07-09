//
//  MergingTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//



@testable import DockerComposeParser
import Testing
import Yams

@Suite("Merging Tests")
struct MergingTestSuite {
    
    // Unique resources
    // Applies to the ports, volumes, secrets and configs services attributes.
    // While these types are modeled in a Compose file as a sequence, they have special uniqueness requirements:
    // https://docs.docker.com/reference/compose-file/merge/#unique-resources
    @Test("Test volume merging with same target")
    func testVolumeMerging() async throws {
        let baseString = """
        foo:/work
        """
        let mergingString = """
        bar:/work
        """

        let base = try Service.Volume(try Yams.compose(yaml: baseString)!, envs:[:])
        let merging = try Service.Volume(try Yams.compose(yaml: mergingString)!, envs:[:])
        let merged = try base.deepMerge(with: merging)
        #expect(merged.source == "bar")
        #expect(merged.target == "/work")
    }

    
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
 
    
}
