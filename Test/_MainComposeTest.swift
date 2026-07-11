//
//  _MainComposeTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Foundation
import Testing
import Yams

@testable import DockerComposeParser

// MARK: - Helpers

private func makeTempDirectory() throws -> URL {
    let dir = URL.temporaryDirectory.appendingPathComponent(
        UUID().uuidString,
        isDirectory: true
    )
    try FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true
    )
    return dir
}

private func writeFile(_ content: String, to url: URL) throws {
    if FileManager.default.fileExists(atPath: url.path()) {
        try FileManager.default.removeItem(at: url)
    }
    try content.write(to: url, atomically: true, encoding: .utf8)
}

// MARK: - Single Compose Test
@Suite("Single compose parsing resolving test")
class SingleComposeResolvingTestSuite {
    let projectDirectory = try! makeTempDirectory()

    deinit {
        try? FileManager.default.removeItem(at: projectDirectory)
    }

    // MARK: - 1. Basic compose (no include, no extends)

    @Test("Test loadCompose - basic compose with no include or extends")
    func loadComposeBasic() throws {
        let composeURL = projectDirectory.appendingPathComponent("compose.yaml")

        try writeFile(
            """
            services:
              web:
                image: nginx:latest
                build:
                  context: ./web
            """,
            to: composeURL
        )

        let compose = try ComposeParser.loadCompose(
            composeURL,
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:latest")
        // build.context should be resolved to an absolute path relative to the project directory.
        #expect(
            compose.services["web"]??.build?.context
                == projectDirectory.appendingPathComponent("web").path()
        )
        #expect(compose.include == nil)
    }

    @Test("Test loadCompose - throws on nonexistent file")
    func loadComposeNonexistentFile() throws {
        let missingURL = URL.temporaryDirectory.appendingPathComponent(
            "\(UUID().uuidString).yaml"
        )

        #expect(throws: (any Error).self) {
            try ComposeParser.loadCompose(
                missingURL,
                envFiles: [],
                projectDirectory: nil
            )
        }
    }

    @Test("Test loadCompose - throws on non-file URL")
    func loadComposeNonFileURL() throws {
        let httpURL = URL(string: "https://example.com/compose.yaml")!

        #expect(throws: (any Error).self) {
            try ComposeParser.loadCompose(
                httpURL,
                envFiles: [],
                projectDirectory: nil
            )
        }
    }

    // MARK: - 2. One-level include

    @Test(
        "Test loadCompose - one level include merges services from included file"
    )
    func loadComposeOneLevelInclude() throws {

        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let commonsURL = projectDirectory.appendingPathComponent("commons.yaml")

        try writeFile(
            """
            services:
              db:
                image: postgres:latest
            """,
            to: commonsURL
        )

        try writeFile(
            """
            include:
              - commons.yaml
            services:
              web:
                image: nginx:latest
                depends_on:
                  db:
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadCompose(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["db"]??.image == "postgres:latest")
        #expect(compose.include == nil)
    }

    @Test("Test loadCompose - include with override applied from base compose")
    func loadComposeIncludeWithOverride() throws {

        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let commonsURL = projectDirectory.appendingPathComponent("commons.yaml")

        try writeFile(
            """
            services:
              db:
                image: postgres:14
            """,
            to: commonsURL
        )

        try writeFile(
            """
            include:
              - commons.yaml
            services:
              db:
                image: postgres:16
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadCompose(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["db"]??.image == "postgres:16")
    }

    // MARK: - 3. Nested includes

    @Test("Test loadCompose - nested includes resolve transitively")
    func loadComposeNestedIncludes() throws {

        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let midURL = projectDirectory.appendingPathComponent("mid.yaml")
        let leafURL = projectDirectory.appendingPathComponent("leaf.yaml")

        try writeFile(
            """
            services:
              cache:
                image: redis:latest
            """,
            to: leafURL
        )

        try writeFile(
            """
            include:
              - leaf.yaml
            services:
              db:
                image: postgres:latest
            """,
            to: midURL
        )

        try writeFile(
            """
            include:
              - mid.yaml
            services:
              web:
                image: nginx:latest
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadCompose(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["db"]??.image == "postgres:latest")
        #expect(compose.services["cache"]??.image == "redis:latest")
    }

    @Test(
        "Test loadCompose - nested includes each resolve relative paths against their own directory"
    )
    func loadComposeNestedIncludesRelativePaths() throws {

        let subDirectory = projectDirectory.appendingPathComponent(
            "sub",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: subDirectory,
            withIntermediateDirectories: true
        )

        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let subComposeURL = subDirectory.appendingPathComponent("compose.yaml")

        try writeFile(
            """
            services:
              api:
                image: myapi
                build:
                  context: ./api-src
            """,
            to: subComposeURL
        )

        try writeFile(
            """
            include:
              - sub/compose.yaml
            services:
              web:
                image: nginx:latest
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadCompose(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )

        // "api" service's build context should resolve relative to `sub/`, not
        // the top-level project directory.
        #expect(
            compose.services["api"]??.build?.context
                == subDirectory.appendingPathComponent("api-src").path()
        )
    }

    // MARK: - 4. Dependencies

    @Test("Test loadCompose - missing required dependency throws")
    func loadComposeMissingRequiredDependency() throws {

        let composeURL = projectDirectory.appendingPathComponent("compose.yaml")

        try writeFile(
            """
            services:
              web:
                image: nginx:latest
                depends_on:
                  db:
                    required: true
            """,
            to: composeURL
        )

        #expect(throws: (any Error).self) {
            try ComposeParser.loadCompose(
                composeURL,
                envFiles: [],
                projectDirectory: nil
            )
        }
    }

    @Test("Test loadCompose - dependency satisfied via include does not throw")
    func loadComposeDependencySatisfiedViaInclude() throws {

        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let commonsURL = projectDirectory.appendingPathComponent("commons.yaml")

        try writeFile(
            """
            services:
              db:
                image: postgres:latest
            """,
            to: commonsURL
        )

        try writeFile(
            """
            include:
              - commons.yaml
            services:
              web:
                image: nginx:latest
                depends_on:
                  db:
                    required: true
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadCompose(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )
        #expect(compose.services["web"]??.image == "nginx:latest")
    }

    @Test(
        "Test loadCompose - missing optional (required: false) dependency still throws per validateDependency"
    )
    func loadComposeMissingOptionalDependencyThrows() throws {

        let composeURL = projectDirectory.appendingPathComponent("compose.yaml")

        try writeFile(
            """
            services:
              web:
                image: nginx:latest
                depends_on:
                  cache:
                    required: false
            """,
            to: composeURL
        )

        // validateDependency throws for both required and warning-level missing
        // dependencies (via ComposeError.dependencyNotFound), it just separates
        // them into different arrays inside the thrown error.
        #expect(throws: (any Error).self) {
            try ComposeParser.loadCompose(
                composeURL,
                envFiles: [],
                projectDirectory: nil
            )
        }
    }

    // MARK: - 5. Extends

    @Test(
        "Test loadCompose - service extends another service in a different file"
    )
    func loadComposeExtendsFromAnotherFile() throws {

        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let baseURL = projectDirectory.appendingPathComponent("base.yaml")

        try writeFile(
            """
            services:
              base_service:
                image: myapp:base
                environment:
                  FOO: bar
            """,
            to: baseURL
        )

        try writeFile(
            """
            services:
              web:
                extends:
                  file: base.yaml
                  service: base_service
                environment:
                  BAZ: qux
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadCompose(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )
        #expect(compose.services["web"]??.image == "myapp:base")
        #expect(compose.services["web"]??.environment?["FOO"] == "bar")
        #expect(compose.services["web"]??.environment?["BAZ"] == "qux")
    }

    @Test("Test loadCompose - extends referencing a nonexistent service throws")
    func loadComposeExtendsNonexistentServiceThrows() throws {
        let mainURL = projectDirectory.appendingPathComponent("compose.yaml")
        let baseURL = projectDirectory.appendingPathComponent("base.yaml")

        try writeFile(
            """
            services:
              base_service:
                image: myapp:base
            """,
            to: baseURL
        )

        try writeFile(
            """
            services:
              web:
                extends:
                  file: base.yaml
                  service: nonexistent_service
            """,
            to: mainURL
        )

        #expect(throws: (any Error).self) {
            try ComposeParser.loadCompose(
                mainURL,
                envFiles: [],
                projectDirectory: nil
            )
        }
    }
}

// MARK: - Multi Compose Test
@Suite("Multi compose parsing resolving test")
class MultiComposeResolvingTestSuite {
    let projectDirectory = try! makeTempDirectory()

    deinit {
        try? FileManager.default.removeItem(at: projectDirectory)
    }

    @Test(
        "Test loadComposes - single compose with no additional files behaves like loadCompose"
    )
    func loadComposesSingleFile() throws {
        let temp = projectDirectory
        let composeURL = temp.appendingPathComponent("compose.yaml")

        try writeFile(
            """
            services:
              web:
                image: nginx:latest
            """,
            to: composeURL
        )

        let compose = try ComposeParser.loadComposes(
            composeURL,
            envFiles: [],
            projectDirectory: nil
        )
        #expect(compose.services["web"]??.image == "nginx:latest")
    }

    @Test("Test loadComposes - later file overrides scalar fields from base")
    func loadComposesLaterFileOverridesScalar() throws {
        let temp = projectDirectory
        let baseURL = temp.appendingPathComponent("compose.yaml")
        let overrideURL = temp.appendingPathComponent("compose.override.yaml")

        try writeFile("services:\n  web:\n    image: nginx:base\n", to: baseURL)
        try writeFile(
            "services:\n  web:\n    image: nginx:override\n",
            to: overrideURL
        )

        let compose = try ComposeParser.loadComposes(
            baseURL,
            otherComposes: [overrideURL],
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:override")
    }

    @Test("Test loadComposes - later file adds new service not present in base")
    func loadComposesLaterFileAddsNewService() throws {
        let temp = projectDirectory
        let baseURL = temp.appendingPathComponent("compose.yaml")
        let overrideURL = temp.appendingPathComponent("compose.override.yaml")

        try writeFile(
            "services:\n  web:\n    image: nginx:latest\n",
            to: baseURL
        )
        try writeFile(
            "services:\n  api:\n    image: myapi:latest\n",
            to: overrideURL
        )

        let compose = try ComposeParser.loadComposes(
            baseURL,
            otherComposes: [overrideURL],
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["api"]??.image == "myapi:latest")
    }

    @Test(
        "Test loadComposes - array fields append across files rather than override"
    )
    func loadComposesArrayFieldsAppend() throws {
        let temp = projectDirectory
        let baseURL = temp.appendingPathComponent("compose.yaml")
        let overrideURL = temp.appendingPathComponent("compose.override.yaml")

        try writeFile(
            "services:\n  web:\n    image: nginx:latest\n    ports:\n      - \"80:80\"\n",
            to: baseURL
        )
        try writeFile(
            "services:\n  web:\n    ports:\n      - \"443:443\"\n",
            to: overrideURL
        )

        let compose = try ComposeParser.loadComposes(
            baseURL,
            otherComposes: [overrideURL],
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.ports?.count == 2)
    }

    @Test(
        "Test loadComposes - multiple additional compose files apply in order, last wins"
    )
    func loadComposesMultipleAdditionalFilesOrder() throws {
        let temp = projectDirectory
        let baseURL = temp.appendingPathComponent("compose.yaml")
        let midURL = temp.appendingPathComponent("compose.mid.yaml")
        let lastURL = temp.appendingPathComponent("compose.last.yaml")

        try writeFile("services:\n  web:\n    image: nginx:base\n", to: baseURL)
        try writeFile("services:\n  web:\n    image: nginx:mid\n", to: midURL)
        try writeFile("services:\n  web:\n    image: nginx:last\n", to: lastURL)

        let compose = try ComposeParser.loadComposes(
            baseURL,
            otherComposes: [midURL, lastURL],
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:last")
    }

    @Test(
        "Test loadComposes - dependency satisfied only across files does not throw"
    )
    func loadComposesDependencySatisfiedAcrossFiles() throws {
        let temp = projectDirectory
        let baseURL = temp.appendingPathComponent("compose.yaml")
        let overrideURL = temp.appendingPathComponent("compose.override.yaml")

        try writeFile(
            """
            services:
              web:
                image: nginx:latest
                depends_on:
                  db:
                    required: true
            """,
            to: baseURL
        )
        try writeFile(
            "services:\n  db:\n    image: postgres:latest\n",
            to: overrideURL
        )

        // Base alone would fail validateDependency() if validated in isolation;
        // loadComposes must defer validation until after the full merge.
        let compose = try ComposeParser.loadComposes(
            baseURL,
            otherComposes: [overrideURL],
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["db"]??.image == "postgres:latest")
    }

    @Test(
        "Test loadComposes - dependency still missing after merging all files throws"
    )
    func loadComposesDependencyStillMissingThrows() throws {
        let temp = projectDirectory
        let baseURL = temp.appendingPathComponent("compose.yaml")
        let overrideURL = temp.appendingPathComponent("compose.override.yaml")

        try writeFile(
            """
            services:
              web:
                image: nginx:latest
                depends_on:
                  db:
                    required: true
            """,
            to: baseURL
        )
        try writeFile(
            "services:\n  cache:\n    image: redis:latest\n",
            to: overrideURL
        )

        #expect(throws: (any Error).self) {
            try ComposeParser.loadComposes(
                baseURL,
                otherComposes: [overrideURL],
                envFiles: [],
                projectDirectory: nil
            )
        }
    }

    @Test(
        "Test loadComposes - explicit env file interpolates values into merged compose"
    )
    func loadComposesExplicitEnvFile() throws {
        let temp = projectDirectory
        let composeURL = temp.appendingPathComponent("compose.yaml")
        let envURL = temp.appendingPathComponent("custom.env")

        try writeFile("IMAGE_TAG=v2\n", to: envURL)
        try writeFile(
            "services:\n  web:\n    image: nginx:${IMAGE_TAG}\n",
            to: composeURL
        )

        let compose = try ComposeParser.loadComposes(
            composeURL,
            envFiles: [envURL],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:v2")
    }

    @Test(
        "Test loadComposes - explicit env file across base and override, later env value wins"
    )
    func loadComposesMultipleEnvFilesOrder() throws {
        let temp = projectDirectory
        let composeURL = temp.appendingPathComponent("compose.yaml")
        let envAURL = temp.appendingPathComponent("a.env")
        let envBURL = temp.appendingPathComponent("b.env")

        try writeFile("IMAGE_TAG=from_a\n", to: envAURL)
        try writeFile("IMAGE_TAG=from_b\n", to: envBURL)
        try writeFile(
            "services:\n  web:\n    image: nginx:${IMAGE_TAG}\n",
            to: composeURL
        )

        let compose = try ComposeParser.loadComposes(
            composeURL,
            envFiles: [envAURL, envBURL],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:from_b")
    }

    @Test("Test loadComposes - missing explicit env file throws")
    func loadComposesMissingExplicitEnvFileThrows() throws {
        let temp = projectDirectory
        let composeURL = temp.appendingPathComponent("compose.yaml")
        let missingEnvURL = temp.appendingPathComponent("missing.env")

        try writeFile(
            "services:\n  web:\n    image: nginx:latest\n",
            to: composeURL
        )

        #expect(throws: (any Error).self) {
            try ComposeParser.loadComposes(
                composeURL,
                envFiles: [missingEnvURL],
                projectDirectory: nil
            )
        }
    }

    @Test(
        "Test loadComposes - no explicit env file falls back to default .env in project directory"
    )
    func loadComposesDefaultDotEnvFallback() throws {
        let temp = projectDirectory
        let composeURL = temp.appendingPathComponent("compose.yaml")
        let dotEnvURL = temp.appendingPathComponent(".env")

        try writeFile("IMAGE_TAG=from_dotenv\n", to: dotEnvURL)
        try writeFile(
            "services:\n  web:\n    image: nginx:${IMAGE_TAG}\n",
            to: composeURL
        )

        let compose = try ComposeParser.loadComposes(
            composeURL,
            envFiles: [],
            projectDirectory: nil
        )
        #expect(compose.services["web"]??.image == "nginx:from_dotenv")
    }

    @Test(
        "Test loadComposes - missing default .env does not throw, just yields unresolved interpolation"
    )
    func loadComposesMissingDefaultDotEnvDoesNotThrow() throws {
        let temp = projectDirectory
        let composeURL = temp.appendingPathComponent("compose.yaml")

        try writeFile(
            "services:\n  web:\n    image: nginx:latest\n",
            to: composeURL
        )

        let compose = try ComposeParser.loadComposes(
            composeURL,
            envFiles: [],
            projectDirectory: nil
        )
        #expect(compose.services["web"]??.image == "nginx:latest")
    }

    @Test(
        "Test loadComposes - explicit projectDirectory used for relative path resolution instead of compose file's directory"
    )
    func loadComposesExplicitProjectDirectory() throws {
        let temp = projectDirectory
        let subDirectory = temp.appendingPathComponent("sub", isDirectory: true)
        try FileManager.default.createDirectory(
            at: subDirectory,
            withIntermediateDirectories: true
        )

        let composeURL = subDirectory.appendingPathComponent("compose.yaml")
        try writeFile(
            """
            services:
              web:
                image: nginx:latest
                build:
                  context: ./web
            """,
            to: composeURL
        )

        let compose = try ComposeParser.loadComposes(
            composeURL,
            envFiles: [],
            projectDirectory: temp
        )

        #expect(
            compose.services["web"]??.build?.context
                == temp.appendingPathComponent("web").path()
        )
    }

    @Test(
        "Test loadComposes - includes in base file are resolved as part of the merge"
    )
    func loadComposesIncludesInBaseFile() throws {
        let temp = projectDirectory
        let mainURL = temp.appendingPathComponent("compose.yaml")
        let commonsURL = temp.appendingPathComponent("commons.yaml")

        try writeFile(
            "services:\n  db:\n    image: postgres:latest\n",
            to: commonsURL
        )
        try writeFile(
            """
            include:
              - commons.yaml
            services:
              web:
                image: nginx:latest
            """,
            to: mainURL
        )

        let compose = try ComposeParser.loadComposes(
            mainURL,
            envFiles: [],
            projectDirectory: nil
        )

        #expect(compose.services["web"]??.image == "nginx:latest")
        #expect(compose.services["db"]??.image == "postgres:latest")
    }
}
