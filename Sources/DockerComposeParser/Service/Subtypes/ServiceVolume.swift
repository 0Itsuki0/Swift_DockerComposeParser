//
//  Secret.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

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
    public struct Volume: Codable, Hashable {
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

        public init(from decoder: Decoder) throws {
            // Try the short string syntax first.
            if let single = try? decoder.singleValueContainer(),
                let raw = try? single.decode(String.self)
            {
                let short = try Self.parseShortSyntax(raw, decoder: decoder)
                self = short
                return
            }

            // Fall back to the long mapping syntax.
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type =
                try container.decodeIfPresent(VolumeType.self, forKey: .type)
                ?? .volume
            self.source = try container.decodeIfPresent(
                String.self,
                forKey: .source
            )
            self.target = try container.decode(String.self, forKey: .target)
            self.read_only = try container.decodeIfPresent(
                Bool.self,
                forKey: .read_only
            )
            self.bind = try container.decodeIfPresent(
                BindOptions.self,
                forKey: .bind
            )
            self.volume = try container.decodeIfPresent(
                VolumeOptions.self,
                forKey: .volume
            )
            self.tmpfs = try container.decodeIfPresent(
                TmpfsOptions.self,
                forKey: .tmpfs
            )
            self.consistency = try container.decodeIfPresent(
                String.self,
                forKey: .consistency
            )
        }

        // MARK: - Short syntax parsing
        //
        // Grammar (informal): [SOURCE:]TARGET[:OPTIONS]
        // - SOURCE, if present, is either a named volume or a host path
        //   (host paths start with `/`, `./`, `../`, `~/`, or a Windows drive
        //   letter like `C:\`).
        // - OPTIONS is a comma-separated list such as `ro`, `rw`, `z`, `Z`,
        //   `nocopy`, `cached`, `delegated`, `consistent`.
        private static func parseShortSyntax(_ raw: String, decoder: Decoder)
            throws -> Volume
        {
            let components = splitRespectingWindowsDrive(raw)

            guard !components.isEmpty, components.count <= 3 else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
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
                // Anonymous volume: just a target path inside the container.
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
            var volume = Volume(
                type: isBind ? .bind : .volume,
                source: source,
                target: target
            )

            if let optionsString {
                let options = optionsString.split(separator: ",").map(
                    String.init
                )

                if options.contains("ro") {
                    volume.read_only = true
                } else if options.contains("rw") {
                    volume.read_only = false
                }

                if isBind {
                    var bindOptions = BindOptions()
                    if options.contains("z") {
                        bindOptions.selinux = "z"
                    } else if options.contains("Z") {
                        bindOptions.selinux = "Z"
                    }
                    if let propagation =
                        options
                        .compactMap({ BindPropagation(rawValue: $0) })
                        .first
                    {
                        bindOptions.propagation = propagation
                    }
                    if bindOptions != BindOptions() {
                        volume.bind = bindOptions
                    }
                } else {
                    var volOptions = VolumeOptions()
                    if options.contains("nocopy") {
                        volOptions.nocopy = true
                    }
                    if volOptions != VolumeOptions() {
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
    }

    public enum VolumeType: String, Codable, Hashable {
        case volume
        case bind
        case tmpfs
        case npipe
        case cluster
    }

    public enum BindPropagation: String, Codable, Hashable {
        case rprivate
        case `private`
        case rshared
        case shared
        case rslave
        case slave
    }

    public struct BindOptions: Codable, Hashable {
        public var propagation: BindPropagation?
        public var create_host_path: Bool?
        /// "z" (shared) or "Z" (private) SELinux relabeling.
        public var selinux: String?

        public init(
            propagation: BindPropagation? = nil,
            create_host_path: Bool? = nil,
            selinux: String? = nil
        ) {
            self.propagation = propagation
            self.create_host_path = create_host_path
            self.selinux = selinux
        }

        public init(from decoder: any Decoder) throws {
            let container:
                KeyedDecodingContainer<Service.BindOptions.CodingKeys> =
                    try decoder.container(
                        keyedBy: Service.BindOptions.CodingKeys.self
                    )
            self.propagation = try container.decodeIfPresent(
                Service.BindPropagation.self,
                forKey: Service.BindOptions.CodingKeys.propagation
            )
            self.create_host_path = try container.decodeIfPresent(
                Bool.self,
                forKey: Service.BindOptions.CodingKeys.create_host_path
            )
            self.selinux = try container.decodeIfPresent(
                String.self,
                forKey: Service.BindOptions.CodingKeys.selinux
            )
        }
    }

    public struct VolumeOptions: Codable, Hashable {
        public var nocopy: Bool?
        public var subpath: String?

        public init(nocopy: Bool? = nil, subpath: String? = nil) {
            self.nocopy = nocopy
            self.subpath = subpath
        }
        public init(from decoder: any Decoder) throws {
            let container:
                KeyedDecodingContainer<Service.VolumeOptions.CodingKeys> =
                    try decoder.container(
                        keyedBy: Service.VolumeOptions.CodingKeys.self
                    )
            self.nocopy = try container.decodeIfPresent(
                Bool.self,
                forKey: Service.VolumeOptions.CodingKeys.nocopy
            )
            self.subpath = try container.decodeIfPresent(
                String.self,
                forKey: Service.VolumeOptions.CodingKeys.subpath
            )
        }
    }

    public struct TmpfsOptions: Codable, Hashable {
        public  var size: Int?
        public  var mode: Int?

        public init(size: Int? = nil, mode: Int? = nil) {
            self.size = size
            self.mode = mode
        }
        public init(from decoder: any Decoder) throws {
            let container:
                KeyedDecodingContainer<Service.TmpfsOptions.CodingKeys> =
                    try decoder.container(
                        keyedBy: Service.TmpfsOptions.CodingKeys.self
                    )
            self.size = try container.decodeIfPresent(
                Int.self,
                forKey: Service.TmpfsOptions.CodingKeys.size
            )
            self.mode = try container.decodeIfPresent(
                Int.self,
                forKey: Service.TmpfsOptions.CodingKeys.mode
            )
        }
    }
}

extension Service.Volume {
    func merge(with otherVolume: Service.Volume) -> Service.Volume {
        let oldVolume = self
        let newVolume = otherVolume
        let merged = Service.Volume(
            type: newVolume.type,
            source: newVolume.source ?? oldVolume.source,
            target: newVolume.target,
            read_only: newVolume.read_only ?? oldVolume.read_only,
            bind: newVolume.bind ?? oldVolume.bind,
            volume: newVolume.volume ?? oldVolume.volume,
            tmpfs: newVolume.tmpfs ?? oldVolume.tmpfs,
            consistency: newVolume.consistency ?? oldVolume.consistency
        )

        return merged
    }
}

extension Array where Element == Service.Volume {
    func merge(with otherVolumes: [Service.Volume]) -> [Service.Volume] {
        var result: [Service.Volume] = self
        for new in otherVolumes {
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

// MARK: - ServiceVolume.swift

extension Service.BindOptions: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
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

        self.create_host_path = try? mapping.value(
            for: CodingKeys.create_host_path
        ).bool
        self.selinux = try? mapping.value(for: CodingKeys.selinux).string(
            envs: envs
        )
    }
}

extension Service.VolumeOptions: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.nocopy = try? mapping.value(for: CodingKeys.nocopy).bool
        self.subpath = try? mapping.value(for: CodingKeys.subpath).string(
            envs: envs
        )
    }
}

extension Service.TmpfsOptions: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.size = try? mapping.value(for: CodingKeys.size).int(envs: envs)
        self.mode = try? mapping.value(for: CodingKeys.mode).int(envs: envs)
    }
}

extension Service.Volume: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        // Try the short string syntax first.
        if let raw = try node.string(envs: envs) {
            self = try Self.parseShortSyntax(raw)
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

        self.source = try? mapping.value(for: CodingKeys.source).string(
            envs: envs
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

        self.read_only = try? mapping.value(for: CodingKeys.read_only).bool

        self.bind = try? Service.BindOptions(
            mapping.value(for: CodingKeys.bind),
            envs: envs
        )
        self.volume = try? Service.VolumeOptions(
            mapping.value(for: CodingKeys.volume),
            envs: envs
        )
        self.tmpfs = try? Service.TmpfsOptions(
            mapping.value(for: CodingKeys.tmpfs),
            envs: envs
        )

        self.consistency = try? mapping.value(for: CodingKeys.consistency)
            .string(envs: envs)
    }

    // MARK: - Short syntax parsing
    //
    // Same grammar as the decoder-based `parseShortSyntax`:
    // [SOURCE:]TARGET[:OPTIONS]

    private static func parseShortSyntax(_ raw: String) throws -> Service.Volume
    {
        let components = splitRespectingWindowsDrive(raw)
        print("components: \(components)")
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
