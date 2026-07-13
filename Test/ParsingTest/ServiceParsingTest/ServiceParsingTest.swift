//
//  ServiceTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



@Suite("Service Parsing Tests")
struct ServiceTestSuite {

    @Test("Test Service parsing - minimal service with just an image")
    func parseMinimal() throws {
        let yaml = "image: nginx:latest"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.image == "nginx:latest")
        #expect(service.build == nil)
        #expect(service.ports == nil)
    }

    @Test("Test Service parsing - empty mapping yields all nil")
    func parseEmpty() throws {
        let node = try Yams.compose(yaml: "{}")
        let service = try Service(node!, envs: [:])
        #expect(service.image == nil)
        #expect(service.build == nil)
        #expect(service.deploy == nil)
        #expect(service.environment == nil)
        #expect(service.depends_on == nil)
        #expect(service.networks == nil)
    }

    @Test("Test Service parsing - build as short syntax string")
    func parseBuildShortSyntax() throws {
        let yaml = """
            image: myapp
            build: .
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.build?.context == ".")
    }

    @Test("Test Service parsing - build as long syntax object")
    func parseBuildLongSyntax() throws {
        let yaml = """
            build:
              context: ./backend
              dockerfile: Dockerfile.prod
              args:
                NODE_ENV: production
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.build?.context == "./backend")
        #expect(service.build?.dockerfile == "Dockerfile.prod")
        #expect(service.build?.args?["NODE_ENV"] == "production")
    }

    @Test("Test Service parsing - environment as map")
    func parseEnvironmentMap() throws {
        let yaml = """
            environment:
              FOO: bar
              BAZ: qux
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.environment?["FOO"] == "bar")
        #expect(service.environment?["BAZ"] == "qux")
    }

    @Test("Test Service parsing - environment as KEY=VALUE list")
    func parseEnvironmentList() throws {
        let yaml = """
            environment:
              - FOO=bar
              - BAZ=qux
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.environment?["FOO"] == "bar")
        #expect(service.environment?["BAZ"] == "qux")
    }

    @Test("Test Service parsing - env_file as single string")
    func parseEnvFileSingleString() throws {
        let yaml = "env_file: config.env"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.env_file?.count == 1)
        #expect(service.env_file?.first?.path == "config.env")
        #expect(service.env_file?.first?.required == true)
    }

    @Test("Test Service parsing - env_file as mixed list")
    func parseEnvFileMixedList() throws {
        let yaml = """
            env_file:
              - config.env
              - path: optional.env
                required: false
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.env_file?.count == 2)
        #expect(service.env_file?[0].path == "config.env")
        #expect(service.env_file?[0].required == true)
        #expect(service.env_file?[1].path == "optional.env")
        #expect(service.env_file?[1].required == false)
    }

    @Test("Test Service parsing - command as single string")
    func parseCommandString() throws {
        let yaml = "command: echo hello"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.command == ["echo hello"])
    }

    @Test("Test Service parsing - command as array")
    func parseCommandArray() throws {
        let yaml = """
            command: ["echo", "hello"]
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.command == ["echo", "hello"])
    }

    @Test("Test Service parsing - depends_on as single string")
    func parseDependsOnString() throws {
        let yaml = "depends_on: db"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.depends_on?.map(\.key) == ["db"])
        #expect(service.depends_on?["db"] != nil)
    }

    @Test("Test Service parsing - depends_on as array")
    func parseDependsOnArray() throws {
        let yaml = """
            depends_on:
              - db
              - cache
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.depends_on?.map(\.key) ?? []) == Set(["db", "cache"])
        )
        #expect(service.depends_on?["db"] != nil)
        #expect(service.depends_on?["cache"] != nil)
    }

    @Test("Test Service parsing - depends_on as map with conditions")
    func parseDependsOnMap() throws {
        let yaml = """
            depends_on:
              db:
                condition: service_healthy
                restart: true
              cache:
                condition: service_started
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.depends_on?.map(\.key) ?? []) == Set(["db", "cache"])
        )
        #expect(service.depends_on?["db"]??.condition == .service_healthy)
        #expect(service.depends_on?["db"]??.restart == true)
        #expect(service.depends_on?["cache"]??.condition == .service_started)
    }

    @Test("Test Service parsing - depends_on map with null value uses defaults")
    func parseDependsOnMapNullValue() throws {
        let yaml = """
            depends_on:
              db:
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.depends_on?.map(\.key) == ["db"])
        #expect(service.depends_on?["db"] != nil)
    }

    @Test("Test Service parsing - networks as array")
    func parseNetworksArray() throws {
        let yaml = """
            networks:
              - frontend
              - backend
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.networks?.map(\.key) ?? [])
                == Set(["frontend", "backend"])
        )
    }

    @Test("Test Service parsing - networks as map with options")
    func parseNetworksMap() throws {
        let yaml = """
            networks:
              frontend:
                ipv4_address: 172.16.238.10
              backend:
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            Set(service.networks?.map(\.key) ?? [])
                == Set(["frontend", "backend"])
        )
        #expect(service.networks?["frontend"]??.ipv4_address == "172.16.238.10")
        #expect(service.networks?["backend"] != nil)
    }

    @Test("Test Service parsing - entrypoint as single string")
    func parseEntrypointString() throws {
        let yaml = "entrypoint: /entrypoint.sh"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.entrypoint == ["/entrypoint.sh"])
    }

    @Test("Test Service parsing - extra_hosts as list")
    func parseExtraHostsList() throws {
        let yaml = """
            extra_hosts:
              - "somehost:162.242.195.82"
              - "otherhost:50.31.209.229"
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(
            service.extra_hosts?.contains("somehost:162.242.195.82") == true
        )
    }

    @Test("Test Service parsing - extra_hosts as map")
    func parseExtraHostsMap() throws {
        let yaml = """
            extra_hosts:
              somehost: 162.242.195.82
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.extra_hosts == ["somehost:162.242.195.82"])
    }

    @Test("Test Service parsing - annotations as map")
    func parseAnnotationsMap() throws {
        let yaml = """
            annotations:
              key: value
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.annotations?["key"] == "value")
    }

    @Test("Test Service parsing - annotations as key=value list")
    func parseAnnotationsList() throws {
        let yaml = """
            annotations:
              - key=value
              - other
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.annotations?["key"] == "value")
        #expect(service.annotations?["other"] == "")
    }

    @Test("Test Service parsing - cpus as double")
    func parseCpusDouble() throws {
        let yaml = "cpus: 0.5"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.cpus == 0.5)
    }

    @Test("Test Service parsing - cpus as string")
    func parseCpusString() throws {
        let yaml = "cpus: \"0.5\""
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.cpus == 0.5)
    }

    @Test("Test Service parsing - expose as bare ints")
    func parseExposeInts() throws {
        let yaml = """
            expose:
              - 3000
              - 8000
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.expose == ["3000", "8000"])
    }

    @Test("Test Service parsing - dns as single string normalized to list")
    func parseDnsSingleString() throws {
        let yaml = "dns: 8.8.8.8"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.dns == ["8.8.8.8"])
    }

    @Test("Test Service parsing - dns as list")
    func parseDnsList() throws {
        let yaml = """
            dns:
              - 8.8.8.8
              - 9.9.9.9
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.dns == ["8.8.8.8", "9.9.9.9"])
    }

    @Test("Test Service parsing - models as array")
    func parseModelsArray() throws {
        let yaml = """
            models:
              - my_model
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.models?.map(\.key) == ["my_model"])
        #expect(service.models?["my_model"] != nil)
    }

    @Test("Test Service parsing - models as map with options")
    func parseModelsMap() throws {
        let yaml = """
            models:
              my_model:
                endpoint_var: MY_MODEL_URL
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.models?.map(\.key) == ["my_model"])
        #expect(service.models?["my_model"]??.endpoint_var == "MY_MODEL_URL")
    }

    @Test("Test Service parsing - ulimits map with int and object forms")
    func parseUlimits() throws {
        let yaml = """
            ulimits:
              nproc: 65535
              nofile:
                soft: 20000
                hard: 40000
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.ulimits?["nproc"]??.soft == 65535)
        #expect(service.ulimits?["nproc"]??.hard == 65535)
        #expect(service.ulimits?["nofile"]??.soft == 20000)
        #expect(service.ulimits?["nofile"]??.hard == 40000)
    }

    @Test("Test Service parsing - ports list mixing short and long syntax")
    func parsePortsMixed() throws {
        let yaml = """
            ports:
              - "8080:80"
              - target: 443
                published: "8443"
                protocol: tcp
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.ports?.count == 2)
        #expect(service.ports?[0].target == "80")
        #expect(service.ports?[0].published == "8080")
        #expect(service.ports?[1].target == "443")
        #expect(service.ports?[1].protocol == .tcp)
    }

    @Test("Test Service parsing - volumes list mixing short and long syntax")
    func parseVolumesMixed() throws {
        let yaml = """
            volumes:
              - db-data:/var/lib/mysql
              - type: bind
                source: ./cache
                target: /app/cache
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.volumes?.count == 2)
        #expect(service.volumes?[0].source == "db-data")
        #expect(service.volumes?[0].target == "/var/lib/mysql")
        #expect(service.volumes?[1].type == .bind)
        #expect(service.volumes?[1].target == "/app/cache")
    }

    @Test("Test Service parsing - secrets and configs short syntax")
    func parseSecretsConfigsShortSyntax() throws {
        let yaml = """
            secrets:
              - my_secret
            configs:
              - my_config
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.secrets?.first?.source == "my_secret")
        #expect(service.configs?.first?.source == "my_config")
    }

    @Test("Test Service parsing - post_start and pre_stop hooks")
    func parseHooks() throws {
        let yaml = """
            post_start:
              - command: ["echo", "started"]
            pre_stop:
              - command: ["echo", "stopping"]
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.post_start?.first?.command == ["echo", "started"])
        #expect(service.pre_stop?.first?.command == ["echo", "stopping"])
    }

    @Test("Test Service parsing - gpus as 'all'")
    func parseGpusAll() throws {
        let yaml = "gpus: all"
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.gpus?.all == true)
    }

    @Test("Test Service parsing - deploy nested structure")
    func parseDeploy() throws {
        let yaml = """
            deploy:
              mode: replicated
              replicas: 3
              resources:
                limits:
                  memory: 512M
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.deploy?.mode == "replicated")
        #expect(service.deploy?.replicas == 3)
        #expect(service.deploy?.resources?.limits?.memory == "512M")
    }

    
    @Test("Test Service parsing - tmpfs as an array")
    func parseTmpfsList() throws {
        let yaml = """
            tmpfs:
              - /data:mode=755,uid=1009,gid=1009
              - /run
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.tmpfs?.count == 2)
        #expect(service.tmpfs?[0].path == "/data")
        #expect(service.tmpfs?[0].options == [
            "mode": "755",
            "uid": "1009",
            "gid": "1009",
        ])
        #expect(service.tmpfs?[1].path == "/run")
    }
    
    @Test("Test Service parsing - tmpfs as a string")
    func parseTmpfsSingle() throws {
        let yaml = """
            tmpfs: /data:mode=755,uid=1009,gid=1009
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])
        #expect(service.tmpfs?.count == 1)
        #expect(service.tmpfs?[0].path == "/data")
        #expect(service.tmpfs?[0].options == [
            "mode": "755",
            "uid": "1009",
            "gid": "1009",
        ])
    }

    
    
    @Test("Test Service parsing - env var interpolation across fields")
    func parseEnvInterpolation() throws {
        let yaml = """
            image: ${IMAGE_NAME}
            container_name: ${CONTAINER_NAME}
            environment:
              FOO: ${FOO_VALUE}
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(
            node!,
            envs: [
                "IMAGE_NAME": "myapp:latest",
                "CONTAINER_NAME": "myapp_container",
                "FOO_VALUE": "bar",
            ]
        )
        #expect(service.image == "myapp:latest")
        #expect(service.container_name == "myapp_container")
        #expect(service.environment?["FOO"] == "bar")
    }

    @Test("Test Service parsing - full realistic service")
    func parseFullService() throws {
        let yaml = """
            image: nginx:latest
            container_name: web
            restart: unless-stopped
            platform: windows/amd64
            ports:
              - "80:80"
              - "443:443"
            environment:
              - NODE_ENV=production
            volumes:
              - ./html:/usr/share/nginx/html:ro
            networks:
              - frontend
            depends_on:
              - api
            labels:
              com.example.description: "web server"
            """
        let node = try Yams.compose(yaml: yaml)
        let service = try Service(node!, envs: [:])

        #expect(service.image == "nginx:latest")
        #expect(service.platform == .init(os: "windows", arch: "amd64"))
        #expect(service.container_name == "web")
        #expect(service.restart == "unless-stopped")
        #expect(service.ports?.count == 2)
        #expect(service.environment?["NODE_ENV"] == "production")
        #expect(service.volumes?.first?.read_only == true)
        #expect((service.networks?.map(\.key) ?? []) == ["frontend"])
        #expect((service.depends_on?.map(\.key) ?? []) == ["api"])
        #expect(service.labels?["com.example.description"] == "web server")
    }

    @Test(
        "Test Service parsing - invalid top-level node throws",
        arguments: [
            "just_a_string",
            "[a, b, c]",
        ]
    )
    func parseInvalid(_ yaml: String) throws {
        let node = try Yams.compose(yaml: yaml)
        #expect(throws: (any Error).self) {
            try Service(node!, envs: [:])
        }
    }
}
