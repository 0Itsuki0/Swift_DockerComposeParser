//
//  Secret.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

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

        /// Custom initializer to handle `secret_name` (string) or `{ source: secret_name, target: /path }` (object).
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let sourceName = try? container.decode(String.self) {
                self.source = sourceName
                self.target = nil
                self.uid = nil
                self.gid = nil
                self.mode = nil
            } else {
                let keyedContainer = try decoder.container(
                    keyedBy: CodingKeys.self
                )
                self.source = try keyedContainer.decode(
                    String.self,
                    forKey: .source
                )
                self.target = try keyedContainer.decodeIfPresent(
                    String.self,
                    forKey: .target
                )
                self.uid = try keyedContainer.decodeIfPresent(
                    String.self,
                    forKey: .uid
                )
                self.gid = try keyedContainer.decodeIfPresent(
                    String.self,
                    forKey: .gid
                )
                self.mode = try keyedContainer.decodeIfPresent(
                    Int.self,
                    forKey: .mode
                )
            }
        }

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
import Yams

// MARK: - ServiceSecret.swift

extension Service.Secret: NodeConvertible {

    // Custom initializer to handle `secret_name` (string) or
    // `{ source: secret_name, target: /path }` (object).
    public init(_ node: Node, envs: [String: String]) throws {
        if let sourceName = try node.string(envs: envs) {
            self.source = sourceName
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
                    debugDescription: "Invalid yaml data. Expected a string or a mapping."
                )
            )
        }

        guard let source = try mapping.value(for: CodingKeys.source).string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.source],
                    debugDescription: "Secret entry must have a 'source' specified."
                )
            )
        }
        self.source = source

        self.target = try? mapping.value(for: CodingKeys.target).string(envs: envs)
        self.uid = try? mapping.value(for: CodingKeys.uid).string(envs: envs)
        self.gid = try? mapping.value(for: CodingKeys.gid).string(envs: envs)
        self.mode = try? mapping.value(for: CodingKeys.mode).int(envs: envs)
    }
}
