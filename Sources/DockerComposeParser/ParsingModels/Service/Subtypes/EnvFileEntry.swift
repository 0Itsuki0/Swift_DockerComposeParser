//
//  EnvFileEntry.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/09.
//

import Yams

extension Service {
    // `env_file` accepts three forms per the Compose spec:
    //   env_file: path.env               → single string
    //   env_file: [path1.env, path2.env] → array of strings
    //   env_file:                         → array of {path:, required:?} dicts (Compose 2.x extended form)
    //     - path: optional.env
    //       required: false
    // Arrays may also mix plain strings and dict entries.
    // Missing optional files (required: false) are loaded silently as empty — loadEnvFile
    // already suppresses read errors, which is the correct behaviour for optional files.
    public struct EnvFileEntry: Codable, Hashable {
        public var path: String
        public var required: Bool
        public var tags: [String: ComposeTag?] = [:]

        public init(path: String, required: Bool) {
            self.path = path
            self.required = required
        }
    }
}

extension Service.EnvFileEntry: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        if let s = try node.string(envs: envs) {
            self.path = s
            self.required = true
            self.tags[CodingKeys.path.stringValue] = node.composeTag
            self.tags[CodingKeys.required.stringValue] = node.composeTag

            return
        }

        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid yaml data. Expected a string or a mapping."
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
                        "EnvFileEntry entry must have a 'path' specified."
                )
            )
        }
        self.path = path
        self.tags[CodingKeys.path.stringValue] = mapping.composeTag(
            for: CodingKeys.path
        )

        let required = try? mapping.value(for: CodingKeys.required).bool(envs: envs)
        self.required = required ?? true
        self.tags[CodingKeys.required.stringValue] = mapping.composeTag(
            for: CodingKeys.required
        )
    }
}
