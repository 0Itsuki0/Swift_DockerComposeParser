//
//  ServicePlatform.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/12.
//

import Yams

extension Service {
    public struct Platform: Codable, Equatable, Hashable, Sendable {
        public var os: String
        public var arch: String?
        public var variant: String?
    }
}

extension Service.Platform: NodeConvertible {
    init(_ node: Yams.Node, envs: [String: String]) throws {
        guard let string = try node.string(envs: envs),
            let parsed = Service.Platform.parsePlatform(string)
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid platform. Expected string."
                )
            )
        }
        self.os = parsed.os
        self.arch = parsed.arch
        self.variant = parsed.variant
    }

    static func parsePlatform(_ platform: String) -> (
        os: String, arch: String?, variant: String?
    )? {
        let parts = platform.split(separator: "/").map(String.init)
        switch parts.count {
        case 1:
            return (os: parts[0], arch: nil, variant: nil)
        case 2:
            return (os: parts[0], arch: parts[1], variant: nil)
        case 3:
            return (os: parts[0], arch: parts[1], variant: parts[2])
        default:
            return nil
        }
    }
}
