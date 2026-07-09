//
//  Secret.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Yams

/// Represents a service's usage of a secret.
extension Service {
    public struct Secret: Codable, Hashable {
        /// Name of the secret being used
        public var source: String

        /// Path in the container where the secret will be mounted
        public var target: String?

        /// User ID for the mounted secret file
        public var uid: String?

        /// Group ID for the mounted secret file
        public var gid: String?

        /// Permissions mode for the mounted secret file
        public var mode: Int?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            source: String,
            target: String?,
            uid: String?,
            gid: String?,
            mode: Int?
        ) {
            self.source = source
            self.target = target
            self.uid = uid
            self.gid = gid
            self.mode = mode
        }
    }
}

extension Service.Secret {
    func merge(with other: Service.Secret) -> Service.Secret {
        let old = self
        let new = other
        let merged = Service.Secret(
            source: new.source,
            target: new.target ?? old.target,
            uid: new.uid ?? old.uid,
            gid: new.gid ?? old.gid,
            mode: new.mode ?? old.mode
        )

        return merged
    }
}

extension Array where Element == Service.Secret {
    func merge(with otherVolumes: [Service.Secret]) -> [Service.Secret] {
        var result: [Service.Secret] = self
        for new in otherVolumes {
            if let firstIndex = result.firstIndex(where: {
                $0.target == new.target
            }) {
                result[firstIndex] = result[firstIndex].merge(with: new)
            } else {
                result.append(new)
            }
        }

        return result
    }
}

// MARK: - ServiceSecret.swift

extension Service.Secret: NodeConvertible {

    // Custom initializer to handle `secret_name` (string) or
    // `{ source: secret_name, target: /path }` (object).
    public init(_ node: Node, envs: [String: String]) throws {
        if let sourceName = try node.string(envs: envs) {
            self.source = sourceName
            self.tags[CodingKeys.source.stringValue] = node.composeTag
            self.target = nil
            self.uid = nil
            self.gid = nil
            self.mode = nil
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
            let source = try mapping.value(for: CodingKeys.source).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.source],
                    debugDescription:
                        "Secret entry must have a 'source' specified."
                )
            )
        }
        self.source = source
        self.tags[CodingKeys.source.stringValue] = mapping.composeTag(
            for: CodingKeys.source
        )

        self.target = try? mapping.value(for: CodingKeys.target).string(
            envs: envs
        )
        self.tags[CodingKeys.target.stringValue] = mapping.composeTag(
            for: CodingKeys.target
        )

        self.uid = try? mapping.value(for: CodingKeys.uid).string(envs: envs)
        self.tags[CodingKeys.uid.stringValue] = mapping.composeTag(
            for: CodingKeys.uid
        )

        self.gid = try? mapping.value(for: CodingKeys.gid).string(envs: envs)
        self.tags[CodingKeys.gid.stringValue] = mapping.composeTag(
            for: CodingKeys.gid
        )

        self.mode = try? mapping.value(for: CodingKeys.mode).int(envs: envs)
        self.tags[CodingKeys.mode.stringValue] = mapping.composeTag(
            for: CodingKeys.mode
        )
    }
}
