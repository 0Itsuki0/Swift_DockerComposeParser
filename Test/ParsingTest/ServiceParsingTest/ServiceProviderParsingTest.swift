//
//  ServiceProviderTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//


//
//  ServiceProviderTests.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

@testable import DockerComposeParser
import Testing
import Yams

@Suite("Service.Provider Parsing Tests")
struct ServiceProviderTestSuite {

    @Test("Minimal mapping - type only")
    func minimal() throws {
        let node = try Yams.compose(yaml: "type: my-provider")
        let provider = try Service.Provider(node!, envs: [:])
        #expect(provider.type == "my-provider")
        #expect(provider.options == nil as [String: String]?)
    }

    @Test("Full mapping - with options")
    func full() throws {
        let yaml = """
        type: my-provider
        options:
          key: value
          another: opt
        """
        let node = try Yams.compose(yaml: yaml)
        let provider = try Service.Provider(node!, envs: [:])
        #expect(provider.type == "my-provider")
        #expect(provider.options?["key"] == "value")
        #expect(provider.options?["another"] == "opt")
    }

    @Test("Env interpolation")
    func envInterpolation() throws {
        let yaml = """
        type: ${TYPE}
        options:
          region: ${REGION}
        """
        let node = try Yams.compose(yaml: yaml)
        let provider = try Service.Provider(node!, envs: ["TYPE": "aws", "REGION": "us-east-1"])
        #expect(provider.type == "aws")
        #expect(provider.options?["region"] == "us-east-1")
    }

    @Test("Invalid - non-mapping throws")
    func invalidNonMapping() throws {
        let node = try Yams.compose(yaml: "\"string\"")
        #expect(throws: (any Error).self) {
            _ = try Service.Provider(node!, envs: [:])
        }
    }

    @Test("Invalid - missing type throws")
    func invalidMissingType() throws {
        let node = try Yams.compose(yaml: "{}")
        #expect(throws: (any Error).self) {
            _ = try Service.Provider(node!, envs: [:])
        }
    }
}
