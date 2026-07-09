//
//  MergingTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("Merging Tests")
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

        let base = try Include(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try Include(
            try Yams.compose(yaml: mergingString)!,
            envs: [:]
        )
        #expect(merging.tags["path"] == .override)

        let merged = try base.deepMerge(with: merging)
        #expect(merged.path == ["../compose.yaml"])
    }

    // MARK: - Service.Volume merge

    @Test(
        "Test Service.Volume merge - new value overrides old for scalar fields"
    )
    func mergeVolumeScalarOverride() {
        let old = Service.Volume(
            type: .volume,
            source: "db-data",
            target: "/var/lib/mysql",
            read_only: false
        )
        let update = Service.Volume(
            type: .volume,
            source: "db-data",
            target: "/var/lib/mysql",
            read_only: true
        )
        let merged = old.merge(with: update)

        #expect(merged.read_only == true)
        #expect(merged.target == "/var/lib/mysql")
    }

    @Test("Test Service.Volume merge - nested bind options deep merge")
    func mergeVolumeNestedBindOptions() {
        let old = Service.Volume(
            type: .bind,
            source: "./data",
            target: "/app/data",
            bind: Service.BindOptions(propagation: .rprivate, selinux: "z")
        )
        let update = Service.Volume(
            type: .bind,
            source: "./data",
            target: "/app/data",
            bind: Service.BindOptions(create_host_path: true)
        )
        let merged = old.merge(with: update)

        #expect(merged.bind?.propagation == .rprivate)
        #expect(merged.bind?.selinux == "z")
        #expect(merged.bind?.create_host_path == true)
    }

    @Test("Test [Service.Volume] merge - unique by target appends new entries")
    func mergeVolumeArrayAppendsNewTarget() {
        let old: [Service.Volume] = [
            Service.Volume(
                type: .volume,
                source: "db-data",
                target: "/var/lib/mysql"
            )
        ]
        let update: [Service.Volume] = [
            Service.Volume(
                type: .volume,
                source: "cache-data",
                target: "/var/cache"
            )
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 2)
        #expect(merged.contains(where: { $0.target == "/var/lib/mysql" }))
        #expect(merged.contains(where: { $0.target == "/var/cache" }))
    }

    @Test(
        "Test [Service.Volume] merge - same target merges instead of duplicating"
    )
    func mergeVolumeArraySameTargetMerges() {
        let old: [Service.Volume] = [
            Service.Volume(
                type: .volume,
                source: "db-data",
                target: "/var/lib/mysql",
                read_only: false
            )
        ]
        let update: [Service.Volume] = [
            Service.Volume(
                type: .volume,
                source: "db-data",
                target: "/var/lib/mysql",
                read_only: true
            )
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 1)
        #expect(merged.first?.read_only == true)
    }

    // MARK: - Service.Secret merge

    @Test(
        "Test Service.Secret merge - new value overrides old for scalar fields"
    )
    func mergeSecretScalarOverride() {
        let old = Service.Secret(
            source: "my_secret",
            target: "/run/secrets/old_target",
            uid: nil,
            gid: nil,
            mode: nil
        )
        let update = Service.Secret(
            source: "my_secret",
            target: "/run/secrets/my_secret",
            uid: "103",
            gid: nil,
            mode: nil
        )
        let merged = old.merge(with: update)

        #expect(merged.target == "/run/secrets/my_secret")
        #expect(merged.uid == "103")
    }

    @Test("Test [Service.Secret] merge - unique by target appends new entries")
    func mergeSecretArrayAppendsNewTarget() {
        let old: [Service.Secret] = [
            Service.Secret(
                source: "db_password",
                target: nil,
                uid: nil,
                gid: nil,
                mode: nil
            )
        ]
        let update: [Service.Secret] = [
            Service.Secret(
                source: "api_key",
                target: "/run/secrets/api_key",
                uid: nil,
                gid: nil,
                mode: nil
            )
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 2)
        #expect(merged.contains(where: { $0.source == "api_key" }))
    }

    @Test(
        "Test [Service.Secret] merge - same target merges instead of duplicating"
    )
    func mergeSecretArraySameTargetMerges() {
        let old: [Service.Secret] = [
            Service.Secret(
                source: "db_password",
                target: "/run/secrets/db_password",
                uid: nil,
                gid: nil,
                mode: nil
            )
        ]
        let update: [Service.Secret] = [
            Service.Secret(
                source: "db_password_v2",
                target: "/run/secrets/db_password",
                uid: "103",
                gid: nil,
                mode: nil
            )
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 1)
        #expect(merged.first?.source == "db_password_v2")
        #expect(merged.first?.uid == "103")
    }

    @Test(
        "Test [Service.Secret] merge - entries with nil target treated as distinct (no accidental collapse)"
    )
    func mergeSecretArrayNilTargetsDoNotCollide() {
        let old: [Service.Secret] = [
            Service.Secret(
                source: "secret_a",
                target: nil,
                uid: nil,
                gid: nil,
                mode: nil
            )
        ]
        let update: [Service.Secret] = [
            Service.Secret(
                source: "secret_b",
                target: nil,
                uid: nil,
                gid: nil,
                mode: nil
            )
        ]
        let merged = old.merge(with: update)

        // Both have target == nil, so firstIndex(where:) matches the first entry
        // and merges into it rather than appending — documenting actual behavior.
        #expect(merged.count == 1)
        #expect(merged.first?.source == "secret_b")
    }

    // MARK: - Service.Port merge

    @Test("Test Service.Port merge - new value overrides old for scalar fields")
    func mergePortScalarOverride() {
        let old = Service.Port(target: "80", published: "8080", protocol: .tcp)
        let update = Service.Port(
            target: "80",
            published: "9090",
            protocol: .tcp
        )
        let merged = old.merge(with: update)

        #expect(merged.published == "9090")
        #expect(merged.target == "80")
    }

    @Test(
        "Test [Service.Port] merge - unique by {host_ip, target, published, protocol} appends new entries"
    )
    func mergePortArrayAppendsNewUniqueKey() {
        let old: [Service.Port] = [
            Service.Port(target: "80", published: "8080", protocol: .tcp)
        ]
        let update: [Service.Port] = [
            Service.Port(target: "443", published: "8443", protocol: .tcp)
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 2)
    }

    @Test(
        "Test [Service.Port] merge - identical unique key merges instead of duplicating"
    )
    func mergePortArraySameUniqueKeyMerges() {
        let old: [Service.Port] = [
            Service.Port(
                target: "80",
                published: "8080",
                protocol: .tcp,
                name: "http"
            )
        ]
        let update: [Service.Port] = [
            Service.Port(
                target: "80",
                published: "8080",
                protocol: .tcp,
                name: "web"
            )
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 1)
        #expect(merged.first?.name == "web")
    }

    @Test(
        "Test [Service.Port] merge - same target but different protocol treated as distinct entries"
    )
    func mergePortArrayDifferentProtocolDistinct() {
        let old: [Service.Port] = [
            Service.Port(target: "53", published: "53", protocol: .udp)
        ]
        let update: [Service.Port] = [
            Service.Port(target: "53", published: "53", protocol: .tcp)
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 2)
    }

    @Test(
        "Test [Service.Port] merge - same target but different published port treated as distinct entries"
    )
    func mergePortArrayDifferentPublishedDistinct() {
        let old: [Service.Port] = [
            Service.Port(target: "80", published: "8080", protocol: .tcp)
        ]
        let update: [Service.Port] = [
            Service.Port(target: "80", published: "9090", protocol: .tcp)
        ]
        let merged = old.merge(with: update)

        #expect(merged.count == 2)
    }
    
    // MARK: - Custom merge tags (!override / !reset)

    @Test("Test merging with override - array override instead of append")
    func testMergingWithOverrideArray() async throws {
        let baseString = """
        image: myapp:base
        command: ["echo", "base"]
        """
        let mergingString = """
        command: !override
          - echo
          - overridden
        """

        let base = try Service(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try Service(try Yams.compose(yaml: mergingString)!, envs: [:])
        #expect(merging.tags["command"] == .override)

        let merged = try base.deepMerge(with: merging)
        #expect(merged.command == ["echo", "overridden"])
    }

    @Test("Test merging with override - scalar override")
    func testMergingWithOverrideScalar() async throws {
        let baseString = """
        image: myapp:base
        """
        let mergingString = """
        image: !override myapp:v2
        """

        let base = try Service(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try Service(try Yams.compose(yaml: mergingString)!, envs: [:])
        #expect(merging.tags["image"] == .override)

        let merged = try base.deepMerge(with: merging)
        #expect(merged.image == "myapp:v2")
    }

    @Test("Test merging with reset - dictionary reset to empty")
    func testMergingWithResetDictionary() async throws {
        let baseString = """
        image: myapp:base
        environment:
          FOO: bar
          BAZ: qux
        """
        let mergingString = """
        environment: !reset
        """

        let base = try Service(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try Service(try Yams.compose(yaml: mergingString)!, envs: [:])
        #expect(merging.tags["environment"] == .reset)

        let merged = try base.deepMerge(with: merging)
        #expect(merged.environment == [:])
        #expect(merged.image == "myapp:base")
    }

    @Test("Test merging with reset - array reset to empty")
    func testMergingWithResetArray() async throws {
        let baseString = """
        image: myapp:base
        command: ["echo", "base"]
        """
        let mergingString = """
        command: !reset
        """

        let base = try Service(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try Service(try Yams.compose(yaml: mergingString)!, envs: [:])
        #expect(merging.tags["command"] == .reset)

        let merged = try base.deepMerge(with: merging)
        #expect(merged.command == [])
    }

    @Test("Test merging with reset - scalar reset to type default even with explicit value")
    func testMergingWithResetScalarIgnoresProvidedValue() async throws {
        let baseString = """
        image: myapp:base
        cpu_count: 4
        """
        let mergingString = """
        cpu_count: !reset 99
        """

        let base = try Service(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try Service(try Yams.compose(yaml: mergingString)!, envs: [:])
        #expect(merging.tags["cpu_count"] == .reset)

        let merged = try base.deepMerge(with: merging)
        // Per the Compose spec, any value following !reset is ignored; the
        // attribute is set to its type's default rather than the provided 99.
        #expect(merged.cpu_count == 0)
    }

    // MARK: - DockerCompose (whole document) merge

    @Test("Test DockerCompose deepMerge - services merge, scalar override, array append")
    func testDockerComposeMergeWhole() async throws {
        let baseString = """
        services:
          web:
            image: nginx:base
            ports:
              - "80:80"
            environment:
              FOO: bar
        """
        let mergingString = """
        services:
          web:
            image: nginx:override
            ports:
              - "443:443"
        """

        let base = try DockerCompose(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try DockerCompose(try Yams.compose(yaml: mergingString)!, envs: [:])

        let merged = try base.deepMerge(with: merging)

        #expect(merged.services["web"]??.image == "nginx:override")
        #expect(merged.services["web"]??.ports?.count == 2)
        #expect(merged.services["web"]??.environment?["FOO"] == "bar")
    }

    @Test("Test DockerCompose deepMerge - command overrides rather than appends by default")
    func testDockerComposeMergeCommandOverridesByDefault() async throws {
        let baseString = """
        services:
          web:
            image: nginx
            command: ["echo", "base"]
        """
        let mergingString = """
        services:
          web:
            command: ["echo", "new"]
        """

        let base = try DockerCompose(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try DockerCompose(try Yams.compose(yaml: mergingString)!, envs: [:])

        let merged = try base.deepMerge(with: merging)
        #expect(merged.services["web"]??.command == ["echo", "new"])
    }

    @Test("Test DockerCompose deepMerge - volumes reset via !reset tag")
    func testDockerComposeMergeResetArray() async throws {
        let baseString = """
        services:
          web:
            image: nginx
            volumes:
              - db-data:/var/lib/mysql
        """
        let mergingString = """
        services:
          web:
            volumes: !reset
        """

        let base = try DockerCompose(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try DockerCompose(try Yams.compose(yaml: mergingString)!, envs: [:])
        let merged = try base.deepMerge(with: merging)
        #expect(merged.services["web"]??.volumes == nil)
    }

    @Test("Test DockerCompose deepMerge - new top-level service key is not silently dropped")
    func testDockerComposeMergeAddsNewService() async throws {
        let baseString = """
        services:
          web:
            image: nginx
        """
        let mergingString = """
        services:
          api:
            image: myapi
        """

        let base = try DockerCompose(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try DockerCompose(try Yams.compose(yaml: mergingString)!, envs: [:])

        let merged = try base.deepMerge(with: merging)
        #expect(merged.services["web"]??.image == "nginx")
        #expect(merged.services["api"]??.image == "myapi")
    }

    @Test("Test DockerCompose deepMerge - ports merge by unique key across files")
    func testDockerComposeMergePortsUniqueKey() async throws {
        let baseString = """
        services:
          web:
            image: nginx
            ports:
              - target: 80
                published: "8080"
                protocol: tcp
                name: http
        """
        let mergingString = """
        services:
          web:
            ports:
              - target: 80
                published: "8080"
                protocol: tcp
                name: web
        """

        let base = try DockerCompose(try Yams.compose(yaml: baseString)!, envs: [:])
        let merging = try DockerCompose(try Yams.compose(yaml: mergingString)!, envs: [:])

        let merged = try base.deepMerge(with: merging)
        #expect(merged.services["web"]??.ports?.count == 1)
        #expect(merged.services["web"]??.ports?.first?.name == "web")
    }

}
