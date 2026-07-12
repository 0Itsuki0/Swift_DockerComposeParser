//
//  Secret.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
import Yams

/// Represents a service's usage of a secret.
extension Service {

    /// Models a single entry in a Compose service's `volumes:` list.
    ///
    /// Docker Compose supports two syntaxes for volumes:
    /// - **Short syntax**: a single string like `db-data:/var/lib/mysql:ro`
    /// - **Long syntax**: a mapping with `type`, `source`, `target`, etc.
    ///
    /// Reference: https://docs.docker.com/reference/compose-file/services/#volumes
    public struct Volume: Codable, Sendable, Equatable, Hashable {
        public var type: VolumeType
        public var source: String?
        public var target: String
        public var read_only: Bool?
        public var bind: BindOptions?
        public var volume: VolumeOptions?
        public var tmpfs: TmpfsOptions?
        public var consistency: String?

        public var tags: [String: ComposeTag?] = [:]

        // MARK: - Custom decoding

        public init(
            type: VolumeType,
            source: String? = nil,
            target: String,
            read_only: Bool? = nil,
            bind: BindOptions? = nil,
            volume: VolumeOptions? = nil,
            tmpfs: TmpfsOptions? = nil,
            consistency: String? = nil
        ) {
            self.type = type
            self.source = source
            self.target = target
            self.read_only = read_only
            self.bind = bind
            self.volume = volume
            self.tmpfs = tmpfs
            self.consistency = consistency
        }
    }

    public enum VolumeType: String, Codable, Sendable, Equatable, Hashable {
        case volume
        case bind
        case tmpfs
        case npipe
        case cluster
    }

    public enum BindPropagation: String, Codable, Sendable, Equatable, Hashable {
        case rprivate
        case `private`
        case rshared
        case shared
        case rslave
        case slave
    }

    public struct BindOptions: Codable, Sendable, Equatable, Hashable {
        public var propagation: BindPropagation?
        public var create_host_path: Bool?
        /// "z" (shared) or "Z" (private) SELinux relabeling.
        public var selinux: String?
        public var tags: [String: ComposeTag?] = [:]

        public init(
            propagation: BindPropagation? = nil,
            create_host_path: Bool? = nil,
            selinux: String? = nil
        ) {
            self.propagation = propagation
            self.create_host_path = create_host_path
            self.selinux = selinux
        }
    }

    public struct VolumeOptions: Codable, Sendable, Equatable, Hashable {
        public var nocopy: Bool?
        public var subpath: String?
        public var tags: [String: ComposeTag?] = [:]

        public init(nocopy: Bool? = nil, subpath: String? = nil) {
            self.nocopy = nocopy
            self.subpath = subpath
        }
    }

    public struct TmpfsOptions: Codable, Sendable, Equatable, Hashable {
        public var size: Int?
        public var mode: Int?
        public var tags: [String: ComposeTag?] = [:]

        public init(size: Int? = nil, mode: Int? = nil) {
            self.size = size
            self.mode = mode
        }
    }
}

// MARK: - ServiceVolume.swift
extension Service.BindOptions: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        if let propagationString = try? mapping.value(
            for: CodingKeys.propagation
        )
        .string(envs: envs) {
            self.propagation = Service.BindPropagation.init(
                rawValue: propagationString
            )

        } else {
            self.propagation = nil
        }
        self.tags[CodingKeys.propagation.stringValue] = mapping.composeTag(
            for: CodingKeys.propagation
        )

        self.create_host_path = try? mapping.value(
            for: CodingKeys.create_host_path
        ).bool(envs: envs)
        self.tags[CodingKeys.create_host_path.stringValue] = mapping.composeTag(
            for: CodingKeys.create_host_path
        )

        self.selinux = try? mapping.value(for: CodingKeys.selinux).string(
            envs: envs
        )
        self.tags[CodingKeys.selinux.stringValue] = mapping.composeTag(
            for: CodingKeys.selinux
        )
    }
}

extension Service.VolumeOptions: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.nocopy = try? mapping.value(for: CodingKeys.nocopy).bool(envs: envs)
        self.tags[CodingKeys.nocopy.stringValue] = mapping.composeTag(
            for: CodingKeys.nocopy
        )

        self.subpath = try? mapping.value(for: CodingKeys.subpath).string(
            envs: envs
        )
        self.tags[CodingKeys.subpath.stringValue] = mapping.composeTag(
            for: CodingKeys.subpath
        )

    }
}

extension Service.TmpfsOptions: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.size = try? mapping.value(for: CodingKeys.size).int(envs: envs)
        self.tags[CodingKeys.size.stringValue] = mapping.composeTag(
            for: CodingKeys.size
        )

        self.mode = try? mapping.value(for: CodingKeys.mode).int(envs: envs)
        self.tags[CodingKeys.mode.stringValue] = mapping.composeTag(
            for: CodingKeys.mode
        )

    }
}

extension Service.Volume: NodeConvertible {

    init(_ node: Node, envs: [String: String]) throws {
        // Try the short string syntax first.
        if let raw = try node.string(envs: envs) {
            self = try Self.parseShortSyntax(raw)
            for key in [
                CodingKeys.type, .source, .target, .read_only, .bind, .volume,
                .tmpfs, .consistency,
            ] {
                self.tags[key.stringValue] = node.composeTag
            }
            return
        }

        // Fall back to the long mapping syntax.
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid yaml data. Expected a string or a mapping."
                )
            )
        }

        if let typeString = try? mapping.value(for: CodingKeys.type).string(
            envs: envs
        ),
            let typeValue = Service.VolumeType.init(rawValue: typeString)
        {
            self.type = typeValue
        } else {
            self.type = .volume
        }
        self.tags[CodingKeys.type.stringValue] = mapping.composeTag(
            for: CodingKeys.type
        )

        self.source = try? mapping.value(for: CodingKeys.source).string(
            envs: envs
        )
        self.tags[CodingKeys.source.stringValue] = mapping.composeTag(
            for: CodingKeys.source
        )

        guard
            let target = try mapping.value(for: CodingKeys.target).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.target],
                    debugDescription:
                        "Volume entry must have a 'target' specified."
                )
            )
        }
        self.target = target
        self.tags[CodingKeys.target.stringValue] = mapping.composeTag(
            for: CodingKeys.target
        )

        self.read_only = try? mapping.value(for: CodingKeys.read_only).bool(envs: envs)
        self.tags[CodingKeys.read_only.stringValue] = mapping.composeTag(
            for: CodingKeys.read_only
        )

        self.bind = try? Service.BindOptions(
            mapping.value(for: CodingKeys.bind),
            envs: envs
        )
        self.tags[CodingKeys.bind.stringValue] = mapping.composeTag(
            for: CodingKeys.bind
        )

        self.volume = try? Service.VolumeOptions(
            mapping.value(for: CodingKeys.volume),
            envs: envs
        )
        self.tags[CodingKeys.volume.stringValue] = mapping.composeTag(
            for: CodingKeys.volume
        )

        self.tmpfs = try? Service.TmpfsOptions(
            mapping.value(for: CodingKeys.tmpfs),
            envs: envs
        )
        self.tags[CodingKeys.tmpfs.stringValue] = mapping.composeTag(
            for: CodingKeys.tmpfs
        )

        self.consistency = try? mapping.value(for: CodingKeys.consistency)
            .string(envs: envs)
        self.tags[CodingKeys.consistency.stringValue] = mapping.composeTag(
            for: CodingKeys.consistency
        )
    }

}

// MARK: - Helper functions
extension Service.Volume {

    /// Returns true if `source` looks like a host filesystem path rather
    /// than a named volume.
    private static func isBindSource(_ source: String) -> Bool {
        if source.hasPrefix("/") || source.hasPrefix("./")
            || source.hasPrefix("../") || source.hasPrefix("~/")
            || source == "." || source == ".."
        {
            return true
        }
        // Windows drive letter, e.g. "C:\Users\me\data"
        if source.count >= 2,
            let first = source.first, first.isLetter,
            source[source.index(source.startIndex, offsetBy: 1)] == ":"
        {
            return true
        }
        return false
    }

    /// Splits a short-syntax volume string on `:`, but keeps a leading
    /// Windows drive letter (`C:\...`) attached to its path instead of
    /// treating the drive colon as a field separator.
    private static func splitRespectingWindowsDrive(_ raw: String)
        -> [String]
    {
        let raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            return []
        }
        // Detect "C:\..." or "C:/..." at the very start of the string.
        let isWindowsDriveSource: Bool = {
            guard raw.count >= 3 else { return false }
            let chars = Array(raw)
            guard chars[0].isLetter, chars[1] == ":" else { return false }
            return chars[2] == "\\" || chars[2] == "/"
        }()

        if isWindowsDriveSource {
            // Reattach the drive letter to the first path segment after
            // splitting on the remaining colons.
            let driveLetter = String(raw.prefix(2))  // "C:"
            let rest = String(raw.dropFirst(2))  // "\Users\...:target:opts"
            var parts = rest.split(
                separator: ":",
                omittingEmptySubsequences: false
            ).map(String.init)
            parts[0] = driveLetter + parts[0]
            return parts
        }

        return raw.split(separator: ":", omittingEmptySubsequences: false)
            .map(String.init)
    }

    // MARK: - Short syntax parsing
    //
    // Grammar (informal): [SOURCE:]TARGET[:OPTIONS]
    // - SOURCE, if present, is either a named volume or a host path
    //   (host paths start with `/`, `./`, `../`, `~/`, or a Windows drive
    //   letter like `C:\`).
    // - OPTIONS is a comma-separated list such as `ro`, `rw`, `z`, `Z`,
    //   `nocopy`, `cached`, `delegated`, `consistent`.
    private static func parseShortSyntax(_ raw: String) throws -> Service.Volume
    {
        let components = splitRespectingWindowsDrive(raw)
        guard !components.isEmpty, components.count <= 3 else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid short-syntax volume string: \(raw)"
                )
            )
        }

        let source: String?
        let target: String
        let optionsString: String?

        switch components.count {
        case 1:
            source = nil
            target = components[0]
            optionsString = nil
        case 2:
            source = components[0]
            target = components[1]
            optionsString = nil
        default:  // 3
            source = components[0]
            target = components[1]
            optionsString = components[2]
        }

        let isBind = source.map(isBindSource) ?? false
        var volume = Service.Volume(
            type: isBind ? .bind : .volume,
            source: source,
            target: target
        )

        if let optionsString {
            let options = optionsString.split(separator: ",").map(String.init)

            if options.contains("ro") {
                volume.read_only = true
            } else if options.contains("rw") {
                volume.read_only = false
            }

            if isBind {
                var bindOptions = Service.BindOptions()
                if options.contains("z") {
                    bindOptions.selinux = "z"
                } else if options.contains("Z") {
                    bindOptions.selinux = "Z"
                }
                if let propagation =
                    options
                    .compactMap({ Service.BindPropagation(rawValue: $0) })
                    .first
                {
                    bindOptions.propagation = propagation
                }
                if bindOptions != Service.BindOptions() {
                    volume.bind = bindOptions
                }
            } else {
                var volOptions = Service.VolumeOptions()
                if options.contains("nocopy") {
                    volOptions.nocopy = true
                }
                if volOptions != Service.VolumeOptions() {
                    volume.volume = volOptions
                }
            }

            if let consistency = options.first(where: {
                ["consistent", "cached", "delegated"].contains($0)
            }) {
                volume.consistency = consistency
            }
        }

        return volume
    }
}

extension Service.Volume {
    
    func merge(with update: Service.Volume) -> Service.Volume {
        guard let old = try? self.toDictionary(),
            let new = try? update.toDictionary()
        else {
            return self
        }
        let merged = old.deepMerge(with: new)

        return (try? Service.Volume.fromDictionary(merged)) ?? self
    }
}

extension Array where Element == Service.Volume {
    func merge(with update: [Service.Volume]) -> [Service.Volume] {
        var result: [Service.Volume] = self
        for new in update {
            if let firstIndex = result.firstIndex(where: {
                $0.target == new.target
            }) {
                let current = result[firstIndex]
                result[firstIndex] = current.merge(with: new)
            } else {
                result.append(new)
            }
        }

        return result
    }
}

extension Service.Volume {
    func resolvePathToAbsolute(projectDirectory: URL) -> Service.Volume {
        var resolved = self
        if resolved.type == .bind {
            resolved.source = resolved.source?.absolutePath(
                relativeTo: projectDirectory
            )
        }
        return resolved
    }
}
