//
//  ValidateDependencyTest.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//


@testable import DockerComposeParser
import Testing
import Yams

@Suite("Dependency validation Tests")
struct ValidateDependencyTestSuite {
    @Test("Test validateDependency - no depends_on passes without throwing")
    func validateDependencyNoDependencies() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(image: "nginx")
            ]
        )
        try compose.validateDependency()
    }

    @Test("Test validateDependency - all depended-on services exist passes without throwing")
    func validateDependencyAllExist() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(image: "nginx", depends_on: ["api": Service.Dependency()]),
                "api": Service(image: "myapi"),
            ]
        )
        try compose.validateDependency()
    }

    @Test("Test validateDependency - missing required dependency throws with service in 'required' list")
    func validateDependencyMissingRequiredThrows() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: ["db": Service.Dependency(required: true)]
                )
            ]
        )

        #expect(throws: ComposeError.self) {
            try compose.validateDependency()
        }

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(required == ["db"])
            #expect(warning.isEmpty)
        }
    }

    @Test("Test validateDependency - missing optional (required: false) dependency throws with service in 'warning' list")
    func validateDependencyMissingOptionalWarns() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: ["cache": Service.Dependency(required: false)]
                )
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(required.isEmpty)
            #expect(warning == ["cache"])
        }
    }

    @Test("Test validateDependency - missing dependency with nil Dependency value defaults to required")
    func validateDependencyMissingWithNilDependencyValueDefaultsRequired() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: ["db": nil]
                )
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(required == ["db"])
            #expect(warning.isEmpty)
        }
    }

    @Test("Test validateDependency - missing dependency with Dependency() default (required unset) defaults to required")
    func validateDependencyMissingWithDefaultDependencyDefaultsRequired() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: ["db": Service.Dependency()]
                )
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(required == ["db"])
            #expect(warning.isEmpty)
        }
    }

    @Test("Test validateDependency - mix of missing required and missing optional across services")
    func validateDependencyMixedRequiredAndWarning() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: [
                        "db": Service.Dependency(required: true),
                        "cache": Service.Dependency(required: false),
                    ]
                ),
                "worker": Service(
                    image: "worker",
                    depends_on: ["queue": Service.Dependency(required: true)]
                ),
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(Set(required) == Set(["db", "queue"]))
            #expect(warning == ["cache"])
        }
    }

    @Test("Test validateDependency - existing dependency alongside a missing one only reports the missing one")
    func validateDependencyPartiallyExisting() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: [
                        "api": Service.Dependency(required: true),
                        "db": Service.Dependency(required: true),
                    ]
                ),
                "api": Service(image: "myapi"),
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(required == ["db"])
            #expect(warning.isEmpty)
        }
    }

    @Test("Test validateDependency - service with empty depends_on is treated as no dependencies")
    func validateDependencyEmptyDependsOnIgnored() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(image: "nginx", depends_on: [:])
            ]
        )
        try compose.validateDependency()
    }

    @Test("Test validateDependency - same missing service depended on by multiple services reports duplicate entries")
    func validateDependencyDuplicateMissingServiceNotDeduped() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: ["db": Service.Dependency(required: true)]
                ),
                "worker": Service(
                    image: "worker",
                    depends_on: ["db": Service.Dependency(required: true)]
                ),
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            // Function does not dedupe; "db" is expected to appear once per
            // depending service.
            #expect(required.filter { $0 == "db" }.count == 2)
            #expect(warning.isEmpty)
        }
    }

    @Test("Test validateDependency - service depending on itself and missing is still reported")
    func validateDependencySelfDependencyMissing() throws {
        let compose = DockerCompose(
            services: [
                "web": Service(
                    image: "nginx",
                    depends_on: ["ghost": Service.Dependency(required: true)]
                )
            ]
        )

        do {
            try compose.validateDependency()
            Issue.record("Expected validateDependency to throw")
        } catch ComposeError.dependencyNotFound(let required, let warning) {
            #expect(required == ["ghost"])
            #expect(warning.isEmpty)
        }
    }
}
