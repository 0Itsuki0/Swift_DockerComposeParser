//
//  ServiceBuildTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



@Suite("ServiceBuild Parsing Tests")
struct ServiceBuildTestSuite {

    @Test("Test Build parsing - short syntax (bare string)")
    func parseShortSyntax() throws {
        let node = try Yams.compose(yaml: ".")
        let build = try Service.Build(node!, envs: [:])
        #expect(build.context == ".")
        #expect(build.dockerfile == nil)
        #expect(build.args == nil)
    }

    @Test("Test Build parsing - long syntax with all fields")
    func parseLongSyntaxAllFields() throws {
        let yaml = """
            context: ./backend
            dockerfile: Dockerfile.prod
            args:
              NODE_ENV: production
            """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.context == "./backend")
        #expect(build.dockerfile == "Dockerfile.prod")
        #expect(build.args?["NODE_ENV"] == "production")
    }
    
    @Test("Test Build parsing - long syntax with cache_from and cache_to")
    func parseLongSyntaxWithCache() throws {
        let yaml = """
        context: ./backend
        cache_from:
          - user/app:cache
          - type=local,src=path/to/cache
        cache_to:
          - type=registry,ref=myregistry/myapp:cache
        """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])

        #expect(build.context == "./backend")
        #expect(build.cache_from?.count == 2)
        #expect(build.cache_from?[0].type == "registry")
        #expect(build.cache_from?[0].options == ["ref": "user/app:cache"])
        #expect(build.cache_from?[1].type == "local")
        #expect(build.cache_from?[1].options["src"] == "path/to/cache")
        #expect(build.cache_to?.count == 1)
        #expect(build.cache_to?[0].type == "registry")
        #expect(build.cache_to?[0].options["ref"] == "myregistry/myapp:cache")
    }

    @Test("Test Build parsing - no cache_from/cache_to yields nil")
    func parseNoCacheFields() throws {
        let yaml = "context: ./backend"
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.cache_from == nil)
        #expect(build.cache_to == nil)
    }

    @Test("Test Build parsing - env var interpolation in cache_from")
    func parseCacheFromEnvInterpolation() throws {
        let yaml = """
        context: .
        cache_from:
          - ${REGISTRY}/myapp:cache
        """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: ["REGISTRY": "myregistry"])
        #expect(build.cache_from?.first?.options["ref"] == "myregistry/myapp:cache")
    }
    
    @Test("Test Build parsing - platforms")
    func parsePlatforms() throws {
        let yaml = """
          context: "."
          platforms:
            - "linux/amd64"
            - "linux/arm64"        
        """
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.platforms?.count == 2)
        #expect(build.platforms == [.init(os: "linux", arch: "amd64"), .init(os: "linux", arch: "arm64")])
    }


    @Test("Test Build parsing - long syntax with only context")
    func parseLongSyntaxContextOnly() throws {
        let yaml = "context: ./backend"
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(node!, envs: [:])
        #expect(build.context == "./backend")
        #expect(build.dockerfile == nil)
        #expect(build.args == nil)
    }

    @Test("Test Build parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = "context: ${BUILD_CONTEXT}"
        let node = try Yams.compose(yaml: yaml)
        let build = try Service.Build(
            node!,
            envs: ["BUILD_CONTEXT": "./backend"]
        )
        #expect(build.context == "./backend")
    }

    @Test("Test Build parsing - missing context in long syntax throws")
    func parseMissingContext() throws {
        let node = try Yams.compose(yaml: "dockerfile: Dockerfile.prod")
        #expect(throws: (any Error).self) {
            try Service.Build(node!, envs: [:])
        }
    }

    @Test("Test Build parsing - invalid sequence node throws")
    func parseInvalidSequence() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            try Service.Build(node!, envs: [:])
        }
    }
}
