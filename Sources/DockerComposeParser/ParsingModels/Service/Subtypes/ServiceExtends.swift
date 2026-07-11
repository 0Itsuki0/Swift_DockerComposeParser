//
//  ServiceExtends.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Reference to a base service definition to merge with (`extends`).
extension Service {
    public struct Extends: Codable, Hashable {
        public var service: String
        public var file: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(service: String, file: String? = nil) {
            self.service = service
            self.file = file
        }
    }
}

extension Service.Extends: NodeConvertible {

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
            let service = try mapping.value(for: CodingKeys.service).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.service],
                    debugDescription:
                        "ServiceExtends entry must have a 'service' specified."
                )
            )
        }
        self.service = service
        self.tags[CodingKeys.service.stringValue] = mapping.composeTag(
            for: CodingKeys.service
        )

        self.file = try? mapping.value(for: CodingKeys.file).string(envs: envs)
        self.tags[CodingKeys.file.stringValue] = mapping.composeTag(
            for: CodingKeys.file
        )
    }
}


import Foundation
extension Service.Extends {
    func resolvePathToAbsolute(projectDirectory: URL) -> Service.Extends
    {
        var resolved = self
        resolved.file = resolved.file?.absolutePath(
            relativeTo: projectDirectory
        )
        return resolved
    }
}
