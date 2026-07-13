//
//  ServiceTmpfs.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/13.
//

import Yams

extension Service {

    /// https://docs.docker.com/reference/compose-file/services/#tmpfs
    public struct Tmpfs: Codable, Sendable, Equatable, Hashable {
        public var path: String

        /// Available options:
        /// - mode: Sets the file system permissions.
        /// - uid: Sets the user ID that owns the mounted tmpfs.
        /// - gid: Sets the group ID that owns the mounted tmpfs.
        public var options: [String: String?]?

        public var tags: [String: ComposeTag?] = [:]

        public init(path: String, options: [String: String?]? = nil) {
            self.path = path
            self.options = options
        }
    }

}

extension Service.Tmpfs: NodeConvertible {
    init(_ node: Yams.Node, envs: [String: String]) throws {
        guard let raw = try node.string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Tmps has to be a string."
                )
            )
        }
        self = Self.parse(raw)
        self.tags[CodingKeys.path.stringValue] = node.composeTag
        self.tags[CodingKeys.options.stringValue] = node.composeTag
        return

    }
}

extension Service.Tmpfs {
    /// Parses a single short-syntax tmpfs entry: `PATH[:OPTION[,OPTION...]]`,
    /// e.g. `/tmp:size=100m,mode=1777,noexec`. Options are comma-separated
    /// `key=value` pairs; a bare flag with no `=value` (e.g. `noexec`) is
    /// stored with a `nil` value.
    static func parse(_ raw: String) -> Service.Tmpfs {
        guard let colonIndex = raw.firstIndex(of: ":") else {
            return Service.Tmpfs(path: raw, options: nil)
        }

        let path = String(raw[..<colonIndex])
        let optionsString = raw[raw.index(after: colonIndex)...]

        guard !optionsString.isEmpty else {
            return Service.Tmpfs(path: path, options: nil)
        }

        var options: [String: String?] = [:]
        for component in optionsString.split(separator: ",") {
            if let eqIndex = component.firstIndex(of: "=") {
                let key = String(component[..<eqIndex])
                let value = String(
                    component[component.index(after: eqIndex)...]
                )
                options[key] = value
            } else {
                options[String(component)] = String?.none
            }
        }

        return Service.Tmpfs(path: path, options: options)
    }
}
