//
//  DevelopWatchItem.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// A single `develop.watch` rule describing a path to monitor and the action to take on change.
extension Service {
    public struct DevelopWatchItem: Codable, Sendable, Equatable, Hashable {
        public var path: String
        public var action: String
        public var target: String?
        public var ignore: [String]?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            path: String,
            action: String,
            target: String? = nil,
            ignore: [String]? = nil
        ) {
            self.path = path
            self.action = action
            self.target = target
            self.ignore = ignore
        }
    }
}

extension Service.DevelopWatchItem: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        guard
            let path = try mapping.value(for: CodingKeys.path).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.path],
                    debugDescription:
                        "DevelopWatchItem entry must have a 'path' specified."
                )
            )
        }
        self.path = path
        self.tags[CodingKeys.path.stringValue] = mapping.composeTag(
            for: CodingKeys.path
        )

        guard
            let action = try mapping.value(for: CodingKeys.action).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.action],
                    debugDescription:
                        "DevelopWatchItem entry must have an 'action' specified."
                )
            )
        }
        self.action = action
        self.tags[CodingKeys.action.stringValue] = mapping.composeTag(
            for: CodingKeys.action
        )

        self.target = try? mapping.value(for: CodingKeys.target).string(
            envs: envs
        )
        self.tags[CodingKeys.target.stringValue] = mapping.composeTag(
            for: CodingKeys.target
        )

        self.ignore = try? mapping.value(for: CodingKeys.ignore)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.ignore.stringValue] = mapping.composeTag(
            for: CodingKeys.ignore
        )
    }
}
