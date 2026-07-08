//
//  Ulimit.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// A single ulimit entry, either a single value (soft == hard) or distinct soft/hard values.
extension Service {
    public struct Ulimit: Codable, Hashable {
        public var soft: Int
        public var hard: Int
        
        public var tags: [String: ComposeTag?] = [:]

        public init(soft: Int, hard: Int) {
            self.soft = soft
            self.hard = hard
        }

        public init(single: Int) {
            self.soft = single
            self.hard = single
        }
    }
}
import Yams

// MARK: - ServiceUlimit.swift

extension Service.Ulimit: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        if let single = try? node.int(envs: envs) {
            self.soft = single
            self.hard = single
            return
        }

        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected an int or a mapping."
                )
            )
        }

        guard let soft = try mapping.value(for: CodingKeys.soft).int(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.soft],
                    debugDescription: "Ulimit entry must have a 'soft' value specified."
                )
            )
        }
        self.soft = soft

        guard let hard = try mapping.value(for: CodingKeys.hard).int(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.hard],
                    debugDescription: "Ulimit entry must have a 'hard' value specified."
                )
            )
        }
        self.hard = hard
    }
}
