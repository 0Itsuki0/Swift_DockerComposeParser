// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DockerComposeParser",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DockerComposeParser",
            targets: ["DockerComposeParser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.2"),
        .package(
          url: "https://github.com/apple/swift-collections.git",
          .upToNextMinor(from: "1.6.0") // or `.upToNextMajor`
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DockerComposeParser",
            dependencies: [
                "Yams",
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/DockerComposeParser"

        ),
        // Tests
        .testTarget(
            name: "DockerComposeParserTest",
            dependencies: [
                "DockerComposeParser"
            ],
            path: "Test"
        ),

    ]
)
