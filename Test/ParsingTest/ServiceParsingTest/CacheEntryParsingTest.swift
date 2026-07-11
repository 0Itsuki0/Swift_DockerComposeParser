//
//  CacheEntryTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("CacheEntry Parsing Tests")
struct CacheEntryTestSuite {

    @Test("Test CacheEntry parsing - bare name shorthand")
    func parseBareName() throws {
        let node = try Yams.compose(yaml: "myregistry/myapp:buildcache")
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "registry")
        #expect(entry.options == ["ref": "myregistry/myapp:buildcache"])
    }

    @Test("Test CacheEntry parsing - type=registry with ref")
    func parseTypeRegistry() throws {
        let node = try Yams.compose(
            yaml: "type=registry,ref=myregistry/myapp:buildcache"
        )
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "registry")
        #expect(entry.options == ["ref": "myregistry/myapp:buildcache"])
    }

    @Test("Test CacheEntry parsing - type=local with multiple options")
    func parseTypeLocalMultipleOptions() throws {
        let node = try Yams.compose(
            yaml: "type=local,src=path/to/cache,mode=max"
        )
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "local")
        #expect(entry.options["src"] == "path/to/cache")
        #expect(entry.options["mode"] == "max")
    }

    @Test("Test CacheEntry parsing - type=gha with no extra options")
    func parseTypeGhaNoOptions() throws {
        let node = try Yams.compose(yaml: "type=gha")
        let entry = try Service.Build.CacheEntry(node!, envs: [:])
        #expect(entry.type == "gha")
        #expect(entry.options.isEmpty)
    }

    @Test("Test CacheEntry parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let node = try Yams.compose(
            yaml: "type=registry,ref=${REGISTRY}/myapp:cache"
        )
        let entry = try Service.Build.CacheEntry(
            node!,
            envs: ["REGISTRY": "myregistry"]
        )
        #expect(entry.options["ref"] == "myregistry/myapp:cache")
    }

    @Test("Test CacheEntry parsing - missing type throws")
    func parseMissingType() throws {
        let node = try Yams.compose(yaml: "type=,ref=foo")
        #expect(throws: (any Error).self) {
            try Service.Build.CacheEntry(node!, envs: [:])
        }
    }

    @Test("Test CacheEntry parsing - malformed component throws")
    func parseMalformedComponent() throws {
        let node = try Yams.compose(yaml: "type=local,badcomponent")
        #expect(throws: (any Error).self) {
            try Service.Build.CacheEntry(node!, envs: [:])
        }
    }

    @Test("Test CacheEntry parsing - non-string node throws")
    func parseNonString() throws {
        let node = try Yams.compose(yaml: "[a, b, c]")
        #expect(throws: (any Error).self) {
            try Service.Build.CacheEntry(node!, envs: [:])
        }
    }
}
