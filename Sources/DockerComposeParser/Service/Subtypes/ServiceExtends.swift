//
//  ServiceExtends.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Reference to a base service definition to merge with (`extends`).
extension Service {
    public struct ServiceExtends: Codable, Hashable {
        public var service: String
        public var file: String?
        
        public var tags: [String: ComposeTag?] = [:]

        public init(service: String, file: String? = nil) {
            self.service = service
            self.file = file
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.service = try container.decode(String.self, forKey: .service)
            self.file = try container.decodeIfPresent(
                String.self,
                forKey: .file
            )
        }
    }
}

import Yams

extension Service.ServiceExtends: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        guard let service = try mapping.value(for: CodingKeys.service).string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.service],
                    debugDescription: "ServiceExtends entry must have a 'service' specified."
                )
            )
        }
        self.service = service

        self.file = try? mapping.value(for: CodingKeys.file).string(envs: envs)
    }
}
