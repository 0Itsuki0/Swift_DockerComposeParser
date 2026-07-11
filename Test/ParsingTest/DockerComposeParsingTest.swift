//
//  DockerComposeTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Testing
import Yams

@testable import DockerComposeParser

@Suite("DockerCompose Parsing Tests")
struct DockerComposeTestSuite {

    @Test("Test DockerCompose parsing - minimal with just services")
    func parseMinimal() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.version == nil)
        #expect(compose.name == nil)
        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.include == nil)
        #expect(compose.models == nil)
        #expect(compose.volumes == nil)
        #expect(compose.networks == nil)
        #expect(compose.configs == nil)
        #expect(compose.secrets == nil)
    }

    @Test("Test DockerCompose parsing - version and name present")
    func parseVersionAndName() throws {
        let yaml = """
            version: "3.8"
            name: myapp
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.version == "3.8")
        #expect(compose.name == "myapp")
    }

    @Test("Test DockerCompose parsing - services with null value (reset)")
    func parseServiceNullValue() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
              worker:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services.keys.contains("worker"))
        if let workerValue = compose.services["worker"] {
            #expect(workerValue == nil)
        } else {
            Issue.record("Expected 'worker' key to be present in services")
        }
    }

    @Test("Test DockerCompose parsing - include as single bare string")
    func parseIncludeSingleString() throws {
        let yaml = """
            include: ../commons/compose.yaml
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.include?.count == 1)
        #expect(compose.include?.first?.path == ["../commons/compose.yaml"])
    }

    @Test(
        "Test DockerCompose parsing - include as list of short syntax entries"
    )
    func parseIncludeList() throws {
        let yaml = """
            include:
              - ../commons/compose.yaml
              - ../another_domain/compose.yaml
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.include?.count == 2)
        #expect(compose.include?[0].path == ["../commons/compose.yaml"])
        #expect(compose.include?[1].path == ["../another_domain/compose.yaml"])
    }

    @Test("Test DockerCompose parsing - include as list of long syntax entries")
    func parseIncludeLongSyntaxList() throws {
        let yaml = """
            include:
              - path: ../commons/compose.yaml
                project_directory: ..
                env_file: ../another/.env
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.include?.count == 1)
        #expect(compose.include?.first?.path == ["../commons/compose.yaml"])
        #expect(compose.include?.first?.project_directory == "..")
    }

    @Test("Test DockerCompose parsing - top-level models map with options")
    func parseModels() throws {
        let yaml = """
            models:
              my_model:
                model: ai/model
                context_size: 1024
                runtime_flags:
                  - "--a-flag"
                  - "--another-flag=42"
              other_model:
                model: ai/other-model
            services:
              web:
                image: nginx:latest
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.models?["my_model"]??.model == "ai/model")
        #expect(compose.models?["my_model"]??.context_size == 1024)
        #expect(
            compose.models?["my_model"]??.runtime_flags == [
                "--a-flag", "--another-flag=42",
            ]
        )
        #expect(compose.models?["other_model"]??.model == "ai/other-model")
        #expect(compose.models?["other_model"]??.context_size == nil)
    }

    @Test("Test DockerCompose parsing - top-level volumes")
    func parseVolumes() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            volumes:
              db-data:
                driver: local
              cache:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.volumes?["db-data"]??.driver == "local")
        #expect(compose.volumes?.keys.contains("cache") == true)
    }

    @Test("Test DockerCompose parsing - top-level networks")
    func parseNetworks() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            networks:
              frontend:
                driver: bridge
              backend:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.networks?["frontend"]??.driver == "bridge")
        #expect(compose.networks?.keys.contains("backend") == true)
    }

    @Test("Test DockerCompose parsing - top-level secrets")
    func parseSecrets() throws {
        let yaml = """
            services:
              web:
                image: nginx:latest
            secrets:
              my_secret:
                file: ./secrets/db_password.txt
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(
            compose.secrets?["my_secret"]??.file == "./secrets/db_password.txt"
        )
    }

    @Test("Test DockerCompose parsing - missing services throws")
    func parseMissingServices() throws {
        let yaml = "version: \"3.8\""
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try DockerCompose(node!, envs: [:])
        }
    }

    @Test("Test DockerCompose parsing - env var interpolation")
    func parseEnvInterpolation() throws {
        let yaml = """
            name: ${PROJECT_NAME}
            services:
              web:
                image: ${IMAGE_NAME}
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(
            node!,
            envs: ["PROJECT_NAME": "myapp", "IMAGE_NAME": "nginx:latest"]
        )

        #expect(compose.name == "myapp")
        #expect(compose.services["web"]??.image == "nginx:latest")
    }

    @Test(
        "Test DockerCompose parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try DockerCompose(node!, envs: [:])
        }
    }

    @Test(
        "Test DockerCompose parsing - name defined as used as an env using the default `COMPOSE_PROJECT_NAME`"
    )
    func parseWithNameEnv() throws {
        let yaml = """
            name: myapp
            services:
              foo:
                image: busybox
                command: echo "I'm running ${COMPOSE_PROJECT_NAME}"
            """
        // NOTE: not using the node initializer here as we will be checking whether if the `COMPOSE_PROJECT_NAME` env is resolved correctly within the DockerCompose(string...) function
        let compose = try DockerCompose(string: yaml, envs: [:])
        #expect(compose.name == "myapp")
        #expect(
            compose.services["foo"]??.command == ["echo \"I'm running myapp\""]
        )

    }

    @Test("Test DockerCompose parsing - full realistic compose file")
    func parseFullCompose() throws {
        let yaml = """
            version: "3.8"
            name: myapp
            services:
              web:
                image: nginx:latest
                ports:
                  - "80:80"
                depends_on:
                  - api
              api:
                build: ./api
                environment:
                  - NODE_ENV=production
            volumes:
              db-data:
            networks:
              frontend:
            """
        let node = try Yams.compose(yaml: yaml)
        let compose = try DockerCompose(node!, envs: [:])

        #expect(compose.version == "3.8")
        #expect(compose.name == "myapp")
        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["api"]??.build?.context == "./api")
        #expect(compose.volumes?.keys.contains("db-data") == true)
        #expect(compose.networks?.keys.contains("frontend") == true)
    }
}
