//
//  Develop.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Development-time configuration for keeping a container in sync with source (`develop`).
extension Service {
    public struct Develop: Codable, Hashable {
        public var watch: [DevelopWatchItem]?
        
        public var tags: [String: ComposeTag?] = [:]

        public init(watch: [DevelopWatchItem]? = nil) {
            self.watch = watch
        }
    }
}

import Yams

extension Service.Develop: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.watch = try? mapping.value(for: CodingKeys.watch)
            .array(of: Service.DevelopWatchItem.self, envs: envs)
    }
}
