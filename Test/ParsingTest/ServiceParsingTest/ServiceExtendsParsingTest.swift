//
//  ServiceExtendsTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



@Suite("ServiceExtends Parsing Tests")
struct ServiceExtendsTestSuite {

    @Test("Test ServiceExtends parsing - all fields present")
    func parseAllFields() throws {
        let yaml = """
            service: base_service
            file: common-services.yaml
            """
        let node = try Yams.compose(yaml: yaml)
        let extends = try Service.Extends(node!, envs: [:])
        #expect(extends.service == "base_service")
        #expect(extends.file == "common-services.yaml")
    }

    @Test("Test ServiceExtends parsing - only service present")
    func parseServiceOnly() throws {
        let yaml = "service: base_service"
        let node = try Yams.compose(yaml: yaml)
        let extends = try Service.Extends(node!, envs: [:])
        #expect(extends.service == "base_service")
        #expect(extends.file == nil)
    }

    @Test("Test ServiceExtends parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "service: ${BASE_SERVICE}"
        let node = try Yams.compose(yaml: yaml)
        let extends = try Service.Extends(
            node!,
            envs: ["BASE_SERVICE": "base_service"]
        )
        #expect(extends.service == "base_service")
    }

    @Test("Test ServiceExtends parsing - missing service throws")
    func parseMissingService() throws {
        let node = try Yams.compose(yaml: "file: common-services.yaml")
        #expect(throws: (any Error).self) {
            try Service.Extends(node!, envs: [:])
        }
    }

    @Test("Test ServiceExtends parsing - non-mapping node throws")
    func parseNonMapping() throws {
        let node = try Yams.compose(yaml: "just_a_string")
        #expect(throws: (any Error).self) {
            try Service.Extends(node!, envs: [:])
        }
    }
}
