//
//  ServiceModelTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams



@Suite("ServiceModel Parsing Tests")
struct ServiceModelTestSuite {

    @Test("Test Model parsing - endpoint_var present")
    func parseEndpointVar() throws {
        let yaml = "endpoint_var: MY_MODEL_URL"
        let node = try Yams.compose(yaml: yaml)
        let model = try Service.Model(node!, envs: [:])
        #expect(model.endpoint_var == "MY_MODEL_URL")
    }

    @Test("Test Model parsing - empty mapping yields nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let model = try Service.Model(node!, envs: [:])
        #expect(model.endpoint_var == nil)
    }

    @Test("Test Model parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "endpoint_var: ${ENDPOINT_VAR_NAME}"
        let node = try Yams.compose(yaml: yaml)
        let model = try Service.Model(
            node!,
            envs: ["ENDPOINT_VAR_NAME": "MY_MODEL_URL"]
        )
        #expect(model.endpoint_var == "MY_MODEL_URL")
    }

    @Test(
        "Test Model parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service.Model(node!, envs: [:])
        }
    }
}
