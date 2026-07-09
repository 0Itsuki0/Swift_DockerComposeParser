//
//  ResolveLocalPathTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/09.
//

import Foundation
import Testing
import Yams

@testable import DockerComposeParser

@Suite("Local Path Resolution Tests")
struct ResolveLocalPathTestTestSuite {

    // MARK: - isLocalPath
    @Test(
        "Test isLocalPath - local paths return true",
        arguments: [
            ".",
            "..",
            "./app",
            "../shared/app",
            "/absolute/path",
            "~/projects/app",
            "app",
            "my-app_dir",
            "C:\\Users\\me\\project",
            "  ./app  ",  // whitespace should be trimmed, still local
        ]
    )
    func parseLocalPaths(_ path: String) {
        #expect(Utility.isLocalPath(path) == true)
    }

    @Test(
        "Test isLocalPath - git SSH shorthand returns false",
        arguments: [
            "git@github.com:user/repo.git",
            "git@gitlab.com:group/project.git",
        ]
    )
    func parseGitSshShorthand(_ path: String) {
        #expect(Utility.isLocalPath(path) == false)
    }

    @Test(
        "Test isLocalPath - remote URL schemes return false",
        arguments: [
            "http://github.com/user/repo.git",
            "https://github.com/user/repo.git",
            "git://github.com/user/repo.git",
            "ssh://git@github.com/user/repo.git",
        ]
    )
    func parseRemoteURLSchemes(_ path: String) {
        #expect(Utility.isLocalPath(path) == false)
    }

    @Test(
        "Test isLocalPath - case-insensitive scheme matching returns false",
        arguments: [
            "HTTP://github.com/user/repo.git",
            "HTTPS://github.com/user/repo.git",
            "Git://github.com/user/repo.git",
        ]
    )
    func parseCaseInsensitiveSchemes(_ path: String) {
        #expect(Utility.isLocalPath(path) == false)
    }

    @Test(
        "Test isLocalPath - special prefixes return false",
        arguments: [
            "type://some-context",
            "service:my-service",
            "docker-image://myapp:latest",
        ]
    )
    func parseSpecialPrefixes(_ path: String) {
        #expect(Utility.isLocalPath(path) == false)
    }

    @Test("Test isLocalPath - empty string returns true")
    func parseEmptyString() {
        #expect(Utility.isLocalPath("") == true)
    }

    // MARK: - CacheEntry
    @Test(
        "Test CacheEntry resolvePathToAbsolute - type=local resolves src and dest to absolute paths"
    )
    func resolveCacheEntryPathToAbsoluteLocalSrcDest() {
        let entry = Service.Build.CacheEntry(
            type: "local",
            options: ["src": "cache/build", "dest": "cache/out"]
        )
        let projectDirectory = URL(fileURLWithPath: "/Users/me/myproject")
        let resolved = entry.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.type == "local")
        #expect(resolved.options["src"] == "/Users/me/myproject/cache/build")
        #expect(resolved.options["dest"] == "/Users/me/myproject/cache/out")
    }

    @Test(
        "Test CacheEntry resolvePathToAbsolute - type=local leaves already-absolute src/dest unchanged"
    )
    func resolveCacheEntryPathToAbsoluteLocalAlreadyAbsolute() {
        let entry = Service.Build.CacheEntry(
            type: "local",
            options: ["src": "/already/absolute/path"]
        )
        let projectDirectory = URL(fileURLWithPath: "/Users/me/myproject")
        let resolved = entry.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.options["src"] == "/already/absolute/path")
    }

    @Test(
        "Test CacheEntry resolvePathToAbsolute - type=local leaves non-src/dest options untouched"
    )
    func resolveCacheEntryPathToAbsoluteLocalOtherOptionsUntouched() {
        let entry = Service.Build.CacheEntry(
            type: "local",
            options: ["src": "cache/build", "mode": "max"]
        )
        let projectDirectory = URL(fileURLWithPath: "/Users/me/myproject")
        let resolved = entry.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.options["mode"] == "max")
        #expect(resolved.options["src"] == "/Users/me/myproject/cache/build")
    }

    @Test(
        "Test CacheEntry resolvePathToAbsolute - type=local with no src/dest keys leaves options unchanged"
    )
    func resolveCacheEntryPathToAbsoluteLocalNoSrcDest() {
        let entry = Service.Build.CacheEntry(
            type: "local",
            options: ["mode": "max"]
        )
        let projectDirectory = URL(fileURLWithPath: "/Users/me/myproject")
        let resolved = entry.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.options == ["mode": "max"])
    }

    @Test(
        "Test CacheEntry resolvePathToAbsolute - non-local type is returned unchanged"
    )
    func resolveCacheEntryPathToAbsoluteNonLocalType() {
        let entry = Service.Build.CacheEntry(
            type: "registry",
            options: ["ref": "myregistry/myapp:cache"]
        )
        let projectDirectory = URL(fileURLWithPath: "/Users/me/myproject")
        let resolved = entry.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.type == "registry")
        #expect(resolved.options["ref"] == "myregistry/myapp:cache")
    }

    @Test(
        "Test CacheEntry resolvePathToAbsolute - type=local with empty options stays empty"
    )
    func resolveCacheEntryPathToAbsoluteLocalEmptyOptions() {
        let entry = Service.Build.CacheEntry(type: "local", options: [:])
        let projectDirectory = URL(fileURLWithPath: "/Users/me/myproject")
        let resolved = entry.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.options.isEmpty)
    }

    // MARK: - Build
    @Test(
        "Test Build resolvePathToAbsolute - local context resolved to absolute path"
    )
    func resolveBuildPathToAbsoluteLocalContext() {
        let build = Service.Build(
            context: "./backend",
            dockerfile: nil,
            args: nil,
            additional_contexts: nil,
            cache_from: nil,
            cache_to: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.context == "/Users/me/myproject/backend")
    }

    @Test("Test Build resolvePathToAbsolute - non-local context left unchanged")
    func resolveBuildPathToAbsoluteNonLocalContext() {
        let build = Service.Build(
            context: "https://github.com/user/repo.git",
            dockerfile: nil,
            args: nil,
            additional_contexts: nil,
            cache_from: nil,
            cache_to: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.context == "https://github.com/user/repo.git")
    }

    @Test(
        "Test Build resolvePathToAbsolute - additional_contexts mix of local, non-local, and nil values"
    )
    func resolveBuildPathToAbsoluteAdditionalContexts() {
        let build = Service.Build(
            context: ".",
            dockerfile: nil,
            args: nil,
            additional_contexts: [
                "base": "../shared/base",
                "remote": "https://github.com/user/repo.git",
                "reset": nil,
            ],
            cache_from: nil,
            cache_to: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(
            resolved.additional_contexts?["base"] == "/Users/me/shared/base"
        )
        #expect(
            resolved.additional_contexts?["remote"]
                == "https://github.com/user/repo.git"
        )
        if let resetValue = resolved.additional_contexts?["reset"] {
            #expect(resetValue == nil)
        } else {
            Issue.record(
                "Expected 'reset' key to be present in additional_contexts"
            )
        }
    }

    @Test(
        "Test Build resolvePathToAbsolute - dockerfile resolved against resolved context, not projectDirectory"
    )
    func resolveBuildPathToAbsoluteDockerfileAgainstContext() {
        let build = Service.Build(
            context: "./backend",
            dockerfile: "Dockerfile.prod",
            args: nil,
            additional_contexts: nil,
            cache_from: nil,
            cache_to: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.context == "/Users/me/myproject/backend")
        #expect(
            resolved.dockerfile == "/Users/me/myproject/backend/Dockerfile.prod"
        )
    }

    @Test("Test Build resolvePathToAbsolute - nil dockerfile stays nil")
    func resolveBuildPathToAbsoluteNilDockerfile() {
        let build = Service.Build(
            context: ".",
            dockerfile: nil,
            args: nil,
            additional_contexts: nil,
            cache_from: nil,
            cache_to: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.dockerfile == nil)
    }

    @Test(
        "Test Build resolvePathToAbsolute - cache_from and cache_to entries resolved via CacheEntry"
    )
    func resolveBuildPathToAbsoluteCacheEntries() {
        let build = Service.Build(
            context: ".",
            dockerfile: nil,
            args: nil,
            additional_contexts: nil,
            cache_from: [
                Service.Build.CacheEntry(
                    type: "local",
                    options: ["src": "cache/build"]
                ),
                Service.Build.CacheEntry(
                    type: "registry",
                    options: ["ref": "myregistry/myapp:cache"]
                ),
            ],
            cache_to: [
                Service.Build.CacheEntry(
                    type: "local",
                    options: ["dest": "cache/out"]
                )
            ]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(
            resolved.cache_from?[0].options["src"]
                == "/Users/me/myproject/cache/build"
        )
        #expect(
            resolved.cache_from?[1].options["ref"] == "myregistry/myapp:cache"
        )
        #expect(
            resolved.cache_to?[0].options["dest"]
                == "/Users/me/myproject/cache/out"
        )
    }

    @Test(
        "Test Build resolvePathToAbsolute - nil cache_from/cache_to/additional_contexts stay nil"
    )
    func resolveBuildPathToAbsoluteNilOptionalFields() {
        let build = Service.Build(
            context: ".",
            dockerfile: nil,
            args: nil,
            additional_contexts: nil,
            cache_from: nil,
            cache_to: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = build.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.cache_from == nil)
        #expect(resolved.cache_to == nil)
        #expect(resolved.additional_contexts == nil)
    }

    // MARK: - Service.Volume
    @Test(
        "Test Volume resolvePathToAbsolute - bind type resolves source to absolute path"
    )
    func resolveVolumePathToAbsoluteBindType() {
        let volume = Service.Volume(
            type: .bind,
            source: "./data",
            target: "/var/lib/data"
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = volume.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.source == "/Users/me/myproject/data")
    }

    @Test(
        "Test Volume resolvePathToAbsolute - volume type leaves source unchanged"
    )
    func resolveVolumePathToAbsoluteVolumeType() {
        let volume = Service.Volume(
            type: .volume,
            source: "db-data",
            target: "/var/lib/mysql"
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = volume.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.source == "db-data")
    }

    @Test(
        "Test Volume resolvePathToAbsolute - tmpfs type leaves nil source unchanged"
    )
    func resolveVolumePathToAbsoluteTmpfsType() {
        let volume = Service.Volume(
            type: .tmpfs,
            source: nil,
            target: "/tmp/cache"
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = volume.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.source == nil)
    }

    @Test(
        "Test Volume resolvePathToAbsolute - bind type with nil source stays nil"
    )
    func resolveVolumePathToAbsoluteBindTypeNilSource() {
        let volume = Service.Volume(
            type: .bind,
            source: nil,
            target: "/app/data"
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = volume.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.source == nil)
    }

    @Test(
        "Test Volume resolvePathToAbsolute - bind type with already-absolute source unchanged"
    )
    func resolveVolumePathToAbsoluteBindTypeAlreadyAbsolute() {
        let volume = Service.Volume(
            type: .bind,
            source: "/already/absolute/data",
            target: "/app/data"
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = volume.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.source == "/already/absolute/data")
    }

    @Test("Test Volume resolvePathToAbsolute - other fields left unchanged")
    func resolveVolumePathToAbsoluteOtherFieldsUnchanged() {
        let volume = Service.Volume(
            type: .bind,
            source: "./data",
            target: "/app/data",
            read_only: true,
            consistency: "cached"
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = volume.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.target == "/app/data")
        #expect(resolved.read_only == true)
        #expect(resolved.consistency == "cached")
    }

    // MARK: - Service
    @Test(
        "Test Service resolvePathToAbsolute - env_file paths resolved to absolute"
    )
    func resolveServicePathToAbsoluteEnvFile() {
        let service = Service(
            env_file: [
                .init(path: "config.env", required: true),
                .init(path: "./nested/optional.env", required: false),
            ]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.env_file?[0].path == "/Users/me/myproject/config.env")
        #expect(resolved.env_file?[0].required == true)
        #expect(
            resolved.env_file?[1].path
                == "/Users/me/myproject/nested/optional.env"
        )
        #expect(resolved.env_file?[1].required == false)
    }

    @Test("Test Service resolvePathToAbsolute - nil env_file stays nil")
    func resolveServicePathToAbsoluteNilEnvFile() {
        let service = Service(env_file: nil)
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.env_file == nil)
    }

    @Test(
        "Test Service resolvePathToAbsolute - label_file paths resolved to absolute"
    )
    func resolveServicePathToAbsoluteLabelFile() {
        let service = Service(label_file: [
            "labels.env", "./nested/more-labels.env",
        ])
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(
            resolved.label_file == [
                "/Users/me/myproject/labels.env",
                "/Users/me/myproject/nested/more-labels.env",
            ]
        )
    }

    @Test(
        "Test Service resolvePathToAbsolute - credential_spec.file resolved to absolute path"
    )
    func resolveServicePathToAbsoluteCredentialSpec() {
        let service = Service(
            credential_spec: Service.CredentialSpec(
                file: "./creds/my_credential_spec.json"
            )
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(
            resolved.credential_spec?.file
                == "/Users/me/myproject/creds/my_credential_spec.json"
        )
    }

    @Test(
        "Test Service resolvePathToAbsolute - extends.file resolved to absolute path"
    )
    func resolveServicePathToAbsoluteExtends() {
        let service = Service(
            extends: Service.Extends(
                service: "base",
                file: "./common/compose.yaml"
            )
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(
            resolved.extends?.file == "/Users/me/myproject/common/compose.yaml"
        )
        #expect(resolved.extends?.service == "base")
    }

    @Test("Test Service resolvePathToAbsolute - nil label_file stays nil")
    func resolveServicePathToAbsoluteNilLabelFile() {
        let service = Service(label_file: nil)
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.label_file == nil)
    }

    @Test(
        "Test Service resolvePathToAbsolute - env_file with already-absolute path unchanged"
    )
    func resolveServicePathToAbsoluteEnvFileAlreadyAbsolute() {
        let service = Service(
            env_file: [
                .init(path: "/already/absolute/config.env", required: true)
            ]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.env_file?[0].path == "/already/absolute/config.env")
    }

    @Test(
        "Test Service resolvePathToAbsolute - label_file with already-absolute path unchanged"
    )
    func resolveServicePathToAbsoluteLabelFileAlreadyAbsolute() {
        let service = Service(label_file: ["/already/absolute/labels.env"])
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = service.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.label_file == ["/already/absolute/labels.env"])
    }

    // MARK: - Top Level Config
    @Test("Test Config resolvePathToAbsolute - file resolved to absolute path")
    func resolveConfigPathToAbsoluteFile() {
        let config = Config(file: "./app_config.json")
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = config.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.file == "/Users/me/myproject/app_config.json")
    }

    @Test("Test Config resolvePathToAbsolute - nil file stays nil")
    func resolveConfigPathToAbsoluteNilFile() {
        let config = Config(file: nil)
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = config.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.file == nil)
    }

    @Test("Test Config resolvePathToAbsolute - already-absolute file unchanged")
    func resolveConfigPathToAbsoluteAlreadyAbsolute() {
        let config = Config(file: "/already/absolute/app_config.json")
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = config.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.file == "/already/absolute/app_config.json")
    }

    // MARK: Top Level Secret
    @Test("Test Secret resolvePathToAbsolute - file resolved to absolute path")
    func resolveSecretPathToAbsoluteFile() {
        let secret = Secret(file: "./secrets/db_password.txt", environment: nil)
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = secret.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.file == "/Users/me/myproject/secrets/db_password.txt")
    }

    @Test("Test Secret resolvePathToAbsolute - nil file stays nil")
    func resolveSecretPathToAbsoluteNilFile() {
        let secret = Secret(file: nil, environment: "DB_PASSWORD")
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = secret.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.file == nil)
        #expect(resolved.environment == "DB_PASSWORD")
    }

    @Test("Test Secret resolvePathToAbsolute - already-absolute file unchanged")
    func resolveSecretPathToAbsoluteAlreadyAbsolute() {
        let secret = Secret(
            file: "/already/absolute/secret.txt",
            environment: nil
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        let resolved = secret.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        #expect(resolved.file == "/already/absolute/secret.txt")
    }

    @Test("Test DockerCompose resolvePathToAbsolute - services resolved")
    func resolveDockerComposePathToAbsoluteServices() {
        var compose = DockerCompose(
            services: [
                "web": Service(
                    build: Service.Build(
                        context: "./web",
                        dockerfile: nil,
                        args: nil
                    )
                )
            ]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(
            compose.services["web"]??.build?.context
                == "/Users/me/myproject/web"
        )
    }

    @Test(
        "Test DockerCompose resolvePathToAbsolute - nil service value stays nil"
    )
    func resolveDockerComposePathToAbsoluteNilServiceValue() {
        var compose = DockerCompose(services: ["worker": nil])
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(compose.services.keys.contains("worker"))
        if let workerValue = compose.services["worker"] {
            #expect(workerValue == nil)
        } else {
            Issue.record("Expected 'worker' key to be present in services")
        }
    }

    @Test("Test DockerCompose resolvePathToAbsolute - configs resolved")
    func resolveDockerComposePathToAbsoluteConfigs() {
        var compose = DockerCompose(
            services: [:],
            configs: ["app_config": Config(file: "./app_config.json")]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(
            compose.configs?["app_config"]??.file
                == "/Users/me/myproject/app_config.json"
        )
    }

    @Test("Test DockerCompose resolvePathToAbsolute - nil configs stays nil")
    func resolveDockerComposePathToAbsoluteNilConfigs() {
        var compose = DockerCompose(services: [:], configs: nil)
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(compose.configs == nil)
    }

    @Test("Test DockerCompose resolvePathToAbsolute - secrets resolved")
    func resolveDockerComposePathToAbsoluteSecrets() {
        var compose = DockerCompose(
            services: [:],
            secrets: [
                "my_secret": Secret(
                    file: "./secrets/db_password.txt",
                    environment: nil
                )
            ]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(
            compose.secrets?["my_secret"]??.file
                == "/Users/me/myproject/secrets/db_password.txt"
        )
    }

    @Test("Test DockerCompose resolvePathToAbsolute - nil secrets stays nil")
    func resolveDockerComposePathToAbsoluteNilSecrets() {
        var compose = DockerCompose(services: [:], secrets: nil)
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(compose.secrets == nil)
    }

    @Test(
        "Test DockerCompose resolvePathToAbsolute - include is left untouched"
    )
    func resolveDockerComposePathToAbsoluteIncludeUntouched() {
        var compose = DockerCompose(
            include: [Include(path: ["../commons/compose.yaml"])],
            services: [:]
        )
        let projectDirectory = URL(
            fileURLWithPath: "/Users/me/myproject",
            isDirectory: true
        )
        compose.resolvePathToAbsolute(projectDirectory: projectDirectory)

        #expect(compose.include?.first?.path == ["../commons/compose.yaml"])
    }

}
