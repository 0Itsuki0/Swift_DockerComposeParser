//
//  DevelopTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



@Suite("Develop Parsing Tests")
struct DevelopTestSuite {

    @Test("Test Develop parsing - watch list present")
    func parseWatchList() throws {
        let yaml = """
            watch:
              - path: ./src
                action: sync
                target: /app/src
                ignore:
                  - node_modules/
              - path: ./package.json
                action: rebuild
            """
        let node = try Yams.compose(yaml: yaml)
        let develop = try Service.Develop(node!, envs: [:])

        #expect(develop.watch?.count == 2)
        #expect(develop.watch?[0].path == "./src")
        #expect(develop.watch?[0].action == "sync")
        #expect(develop.watch?[0].target == "/app/src")
        #expect(develop.watch?[0].ignore == ["node_modules/"])
        #expect(develop.watch?[1].path == "./package.json")
        #expect(develop.watch?[1].action == "rebuild")
        #expect(develop.watch?[1].target == nil)
        #expect(develop.watch?[1].ignore == nil)
    }

    @Test("Test Develop parsing - empty mapping yields nil watch")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let develop = try Service.Develop(node!, envs: [:])
        #expect(develop.watch == nil)
    }

    @Test(
        "Test Develop parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Develop(node!, envs: [:])
        }
    }
}
