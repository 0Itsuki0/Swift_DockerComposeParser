//
//  Healthcheck.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation

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

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Handle if `test` is a single string instead of an array
            if let test = try? container.decodeIfPresent(
                [String].self,
                forKey: .test
            ) {
                self.test = test
            } else if let testString = try? container.decodeIfPresent(
                String.self,
                forKey: .test
            ) {
                self.test = ["CMD-SHELL", testString]
            } else {
                self.test = nil
            }

            self.start_period = try container.decodeIfPresent(
                String.self,
                forKey: .start_period
            )
            self.interval = try container.decodeIfPresent(
                String.self,
                forKey: .interval
            )
            self.retries = try container.decodeIfPresent(
                Int.self,
                forKey: .retries
            )
            self.timeout = try container.decodeIfPresent(
                String.self,
                forKey: .timeout
            )
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

        public static func parseDuration(
            _ value: String?,
            default defaultValue: TimeInterval
        ) -> TimeInterval {
            guard let value, !value.isEmpty else {
                return defaultValue
            }

            if let seconds = TimeInterval(value) {
                return seconds
            }

            let range = NSRange(value.startIndex..<value.endIndex, in: value)
            let matches = Self.durationRegex.matches(in: value, range: range)
            guard !matches.isEmpty else {
                return defaultValue
            }

            return matches.reduce(0) { total, match in
                guard
                    let amountRange = Range(match.range(at: 1), in: value),
                    let unitRange = Range(match.range(at: 2), in: value),
                    let amount = TimeInterval(value[amountRange])
                else {
                    return total
                }
                return total + amount
                    * (Self.durationUnits[String(value[unitRange])] ?? 0)
            }
        }
    }
}


import Yams
extension Service.Healthcheck: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
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
        if let testArray = try? mapping.value(for: CodingKeys.test)
            .array(of: String.self, envs: envs), !testArray.isEmpty
        {
            self.test = testArray
        } else if let testString = try? mapping.value(for: CodingKeys.test)
            .string(envs: envs)
        {
            self.test = ["CMD-SHELL", testString]
        } else {
            self.test = nil
        }

        self.start_period = try? mapping.value(for: CodingKeys.start_period)
            .string(envs: envs)
        self.interval = try? mapping.value(for: CodingKeys.interval).string(envs: envs)
        self.retries = try? mapping.value(for: CodingKeys.retries).int(envs: envs)
        self.timeout = try? mapping.value(for: CodingKeys.timeout).string(envs: envs)
    }
}
