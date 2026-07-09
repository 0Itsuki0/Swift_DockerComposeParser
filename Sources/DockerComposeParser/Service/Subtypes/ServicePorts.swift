//
//  ServicePorts.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//
import Yams

extension Service {
    public enum PortProtocol: String, Codable, Hashable {
        case tcp
        case udp
    }

    public enum Mode: String, Codable, Hashable {
        case host
        case ingress
    }

    /// Models a single entry in a Compose service's `ports:` list.
    ///
    /// Reference: https://docs.docker.com/reference/compose-file/services/#ports
    public struct Port: Codable, Hashable {

        /// Container port or range, e.g. "80" or "8080-8081". Required.
        public var target: String
        /// Host port or range, e.g. "8080" or "8080-8090". Nil = Docker picks a random host port.
        public var published: String?
        public var host_ip: String?
        public var `protocol`: PortProtocol?
        public var app_protocol: String?
        public var mode: Mode?
        public var name: String?

        public var tags: [String: ComposeTag?] = [:]

        public init(
            target: String,
            published: String? = nil,
            host_ip: String? = nil,
            app_protocol: String? = nil,
            `protocol`: PortProtocol? = nil,
            mode: Mode? = nil,
            name: String? = nil
        ) {
            self.target = target
            self.published = published
            self.host_ip = host_ip
            self.app_protocol = app_protocol
            self.protocol = `protocol`
            self.mode = mode
            self.name = name
        }
    }
}

extension Service.Port {
    func merge(with other: Service.Port) -> Service.Port {
        let old = self
        let new = other
        let merged = Service.Port(
            target: new.target,
            published: new.published ?? old.published,
            host_ip: new.host_ip ?? old.host_ip,
            app_protocol: new.app_protocol ?? old.app_protocol,
            protocol: new.protocol ?? old.protocol,
            mode: new.mode ?? old.mode,
            name: new.name ?? old.name
        )

        return merged
    }
}

extension Array where Element == Service.Port {
    func merge(with otherVolumes: [Service.Port]) -> [Service.Port] {
        var result: [Service.Port] = self
        for new in otherVolumes {
            // unique Key: {ip, target, published, protocol}
            if let firstIndex = result.firstIndex(where: {
                $0.host_ip == new.host_ip && $0.target == new.target
                    && $0.published == new.published
                    && $0.protocol == new.protocol
            }) {
                result[firstIndex] = result[firstIndex].merge(with: new)
            } else {
                result.append(new)
            }
        }

        return result
    }
}

extension Service.Port: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        // Bare scalar entry, e.g. `ports: - "8080:80"` or `ports: - 3000`.
        // `.string(envs:)` already stringifies int-tagged scalars, so a bare
        // int like `3000` flows through parseShortSyntax the same as `"3000"`
        // and yields the same single-part (target-only) result.
        if let raw = try node.string(envs: envs) {
            self = try Self.parseShortSyntax(raw)
            for key in [
                CodingKeys.target, .published, .host_ip, .app_protocol,
                .protocol, .mode, .name,
            ] {
                self.tags[key.stringValue] = node.composeTag
            }
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

        // `target` can be written as a YAML int (80) or string ("80-90").
        guard
            let target = try mapping.value(for: CodingKeys.target).string(
                envs: envs
            )
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.target],
                    debugDescription: "`target` is required for Port."
                )
            )
        }
        self.target = target
        self.tags[CodingKeys.target.stringValue] = mapping.composeTag(
            for: CodingKeys.target
        )

        self.published = try? mapping.value(for: CodingKeys.published).string(
            envs: envs
        )
        self.tags[CodingKeys.published.stringValue] = mapping.composeTag(
            for: CodingKeys.published
        )

        self.host_ip = try? mapping.value(for: CodingKeys.host_ip).string(
            envs: envs
        )
        self.tags[CodingKeys.host_ip.stringValue] = mapping.composeTag(
            for: CodingKeys.host_ip
        )

        if let protoString = try? mapping.value(for: CodingKeys.protocol)
            .string(envs: envs)
        {
            self.protocol = Service.PortProtocol.init(rawValue: protoString)
        } else {
            self.protocol = nil
        }
        self.tags[CodingKeys.protocol.stringValue] = mapping.composeTag(
            for: CodingKeys.protocol
        )

        self.app_protocol = try? mapping.value(for: CodingKeys.app_protocol)
            .string(envs: envs)
        self.tags[CodingKeys.app_protocol.stringValue] = mapping.composeTag(
            for: CodingKeys.app_protocol
        )

        if let modeString = try? mapping.value(for: CodingKeys.mode).string(
            envs: envs
        ) {
            self.mode = Service.Mode.init(rawValue: modeString)
        } else {
            self.mode = nil
        }
        self.tags[CodingKeys.mode.stringValue] = mapping.composeTag(
            for: CodingKeys.mode
        )

        self.name = try? mapping.value(for: CodingKeys.name).string(envs: envs)
        self.tags[CodingKeys.name.stringValue] = mapping.composeTag(
            for: CodingKeys.name
        )
    }

    // MARK: - Short syntax parsing
    //
    // [[HOST_IP:]HOST_PORT:]CONTAINER_PORT[/PROTOCOL]
    // - HOST_IP is optional and, if present, requires HOST_PORT.
    // - HOST_PORT and CONTAINER_PORT may each be a single port or a range
    //   ("start-end"); when both are ranges they must be equal length.
    // - PROTOCOL is "tcp" or "udp"; defaults to tcp.
    // - HOST_IP may be bracketed for IPv6, e.g. "[::1]:8080:80".
    private static func parseShortSyntax(_ raw: String) throws -> Service.Port {
        var remainder = Substring(raw)

        var proto: Service.PortProtocol?
        if let slashIndex = remainder.lastIndex(of: "/") {
            let protoString = String(
                remainder[remainder.index(after: slashIndex)...]
            )
            guard let parsed = Service.PortProtocol(rawValue: protoString)
            else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription:
                            "Invalid protocol in port string: \(raw)"
                    )
                )
            }
            proto = parsed
            remainder = remainder[..<slashIndex]
        }

        var hostIp: String?
        var rest: Substring = remainder

        if remainder.hasPrefix("["),
            let closeBracket = remainder.firstIndex(of: "]")
        {
            hostIp = String(
                remainder[
                    remainder.index(after: remainder.startIndex)..<closeBracket
                ]
            )
            let afterBracket = remainder[
                remainder.index(after: closeBracket)...
            ]
            guard afterBracket.hasPrefix(":") else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription:
                            "Expected ':' after bracketed host IP in: \(raw)"
                    )
                )
            }
            rest = afterBracket.dropFirst()
        }

        let parts = rest.split(separator: ":", omittingEmptySubsequences: false)

        let target: String
        let published: String?

        switch parts.count {
        case 1:
            target = String(parts[0])
            published = nil
        case 2:
            published = String(parts[0])
            target = String(parts[1])
        case 3:
            guard hostIp == nil else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription:
                            "Unexpected extra ':' after bracketed host IP in: \(raw)"
                    )
                )
            }
            hostIp = String(parts[0])
            published = String(parts[1])
            target = String(parts[2])
        default:
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription:
                        "Invalid short-syntax port string: \(raw). Expected CONTAINER_PORT, HOST_PORT:CONTAINER_PORT, or HOST_IP:HOST_PORT:CONTAINER_PORT"
                )
            )
        }

        return Service.Port(
            target: target,
            published: published,
            host_ip: hostIp,
            protocol: proto
        )
    }
}
