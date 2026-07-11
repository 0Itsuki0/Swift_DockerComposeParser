//
//  Healthcheck.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Yams

/// Healthcheck configuration for a service.
extension Service {
    public struct Healthcheck: Codable, Hashable {
        private static let durationUnits: [String: TimeInterval] = [
            "ns": 0.000000001,
            "us": 0.000001,
            "µs": 0.000001,
            "ms": 0.001,
            "s": 1,
            "m": 60,
            "h": 3600,
        ]
        private static let durationRegex = try! NSRegularExpression(
            pattern: #"([0-9]+(?:\.[0-9]+)?)(ns|us|µs|ms|s|m|h)"#
        )

        /// Command to run to check health
        public var test: [String]?
        /// Grace period for the container to start
        public var start_period: String?
        /// How often to run the check
        public var interval: String?
        /// Number of consecutive failures to consider unhealthy
        public var retries: Int?
        /// Timeout for each check
        public var timeout: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            test: [String]? = nil,
            start_period: String? = nil,
            interval: String? = nil,
            retries: Int? = nil,
            timeout: String? = nil
        ) {
            self.test = test
            self.start_period = start_period
            self.interval = interval
            self.retries = retries
            self.timeout = timeout
        }

        public var isDisabled: Bool {
            test?.first?.uppercased() == "NONE"
        }

        public var execArguments: [String]? {
            guard let test, !test.isEmpty, !isDisabled else {
                return nil
            }

            switch test[0].uppercased() {
            case "CMD":
                let command = Array(test.dropFirst())
                return command.isEmpty ? nil : command
            case "CMD-SHELL":
                let command = test.dropFirst().joined(separator: " ")
                return command.isEmpty ? nil : ["sh", "-c", command]
            default:
                return test
            }
        }
    }
}

extension Service.Healthcheck: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        // `test` accepts either a list of strings or a single string, the
        // latter is wrapped as `["CMD-SHELL", testString]`, same as the
        // decoder-based init.
        // string first because .array(of:) will also resolve string to array
        // and we need to distinguish between test: ["NONE"] vs test: "NONE"
        if let testString = try? mapping.value(for: CodingKeys.test)
            .string(envs: envs)
        {
            // If it's a string, it's equivalent to specifying CMD-SHELL followed by that string.
            self.test = ["CMD-SHELL", testString]
        } else if let testArray = try? mapping.value(for: CodingKeys.test)
            .array(of: String.self, envs: envs), !testArray.isEmpty
        {
            //  If it's a list, the first item must be either NONE, CMD or CMD-SHELL.
            if !["CMD-SHELL", "CMD", "NONE"].contains(testArray.first) {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.test],
                        debugDescription:
                            "Invalid compose yaml. test when declared as an array must start with CMD-SHELL, CMD or NONE."
                    )
                )
            }
            self.test = testArray
        } else {
            self.test = nil
        }
        self.tags[CodingKeys.test.stringValue] = mapping.composeTag(
            for: CodingKeys.test
        )

        self.start_period = try? mapping.value(for: CodingKeys.start_period)
            .string(envs: envs)
        self.tags[CodingKeys.start_period.stringValue] = mapping.composeTag(
            for: CodingKeys.start_period
        )

        self.interval = try? mapping.value(for: CodingKeys.interval).string(
            envs: envs
        )
        self.tags[CodingKeys.interval.stringValue] = mapping.composeTag(
            for: CodingKeys.interval
        )

        self.retries = try? mapping.value(for: CodingKeys.retries).int(
            envs: envs
        )
        self.tags[CodingKeys.retries.stringValue] = mapping.composeTag(
            for: CodingKeys.retries
        )

        self.timeout = try? mapping.value(for: CodingKeys.timeout).string(
            envs: envs
        )
        self.tags[CodingKeys.timeout.stringValue] = mapping.composeTag(
            for: CodingKeys.timeout
        )

    }
}
