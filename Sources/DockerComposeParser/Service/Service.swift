//
//  Service.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

import Foundation
//
import Playgrounds
import Yams

/// Represents a single service definition within the `services` section.
/// https://docs.docker.com/reference/compose-file/services/
public struct Service: Codable, Hashable {
    /// Docker image name
    public var image: String?

    /// Build configuration if the service is built from a Dockerfile
    public var build: Build?

    /// Deployment configuration (primarily for Swarm)
    public var deploy: Deploy?

    /// Restart policy (e.g., 'unless-stopped', 'always')
    public var restart: String?

    /// Healthcheck configuration
    public var healthcheck: Healthcheck?

    /// List of volume mounts (e.g., "hostPath:containerPath", "namedVolume:/path")
    public var volumes: [Volume]?

    /// Environment variables to set in the container
    // optional value to handle reset
    public var environment: [String: String?]?

    /// List of .env files to load environment variables from
    /// The env_file attribute is used to specify one or more files that contain environment variables to be passed to the **containers**.
    public var env_file: [EnvFileEntry]?

    /// Port mappings (e.g., "hostPort:containerPort")
    public var ports: [Service.Port]?

    /// Command to execute in the container, overriding the image's default
    public var command: [String]?

    /// Services this service depends on (for startup order)
    public var depends_on: [String]?

    /// Service dependency options keyed by dependency service name.
    // optional value to handle reset
    public var dependencyConditions: [String: Dependency?]?

    /// User or UID to run the container as
    public var user: String?

    /// Explicit name for the container instance
    public var container_name: String?

    /// User-defined labels applied to the container (e.g. `{ "foo": "bar" }`).
    /// Passed through as `--label key=value`; the `com.docker.compose.project` and
    /// `com.docker.compose.service` labels are additionally stamped by `ComposeUp`
    /// and take precedence over any user value for those keys.
    // optional value to handle reset
    public var labels: [String: String?]?

    /// List of networks the service will connect to
    /// optional value to handle reset
    public var networks: [String: Service.Network?]?

    /// Container hostname
    public var hostname: String?

    /// Entrypoint to execute in the container, overriding the image's default
    public var entrypoint: [String]?

    /// Run container in privileged mode
    public var privileged: Bool?

    /// Mount container's root filesystem as read-only
    public var read_only: Bool?

    /// Working directory inside the container
    public var working_dir: String?

    /// Platform architecture for the service
    public var platform: String?

    /// Service-specific config usage (primarily for Swarm)
    public var configs: [Service.Config]?

    /// Service-specific secret usage (primarily for Swarm)
    public var secrets: [Service.Secret]?

    /// Keep STDIN open (-i flag for `container run`)
    public var stdin_open: Bool?

    /// Allocate a pseudo-TTY (-t flag for `container run`)
    public var tty: Bool?

    /// Memory limit shorthand (e.g., "512m", "1g") — top-level alternative to
    /// `deploy.resources.limits.memory`. Takes precedence when both are set.
    public var mem_limit: String?

    /// Additional `/etc/hosts` entries injected into the container. Each entry is a
    /// `"hostname:IP"` string. The special token `host-gateway` resolves to the host
    /// machine's IP as seen from inside the container.
    public var extra_hosts: [String]?

    /// Profile names that gate this service (per the Compose spec `profiles` key).
    /// A service with no profiles (nil/empty) is always eligible. A service with
    /// profiles is only eligible when at least one of them is active — unless the
    /// service is named explicitly on the command line, or is a dependency of an
    /// eligible service, both of which bypass the profile gate per the Compose spec.
    public var profiles: [String]?

    /// Annotations applied to the container. Accepts either a map or a list of `key=value` strings.
    // optional value to handle reset
    public var annotations: [String: String?]?

    /// When `false`, Compose does not collect this service's logs until explicitly requested. Defaults to `true`.
    public var attach: Bool?

    /// Block I/O (blkio) limits for the service container.
    public var blkio_config: BlkioConfig?

    /// Number of usable CPUs for the service container.
    public var cpu_count: Int?

    /// Usable percentage of the available CPUs.
    public var cpu_percent: Double?

    /// Service container's relative CPU weight versus other containers.
    public var cpu_shares: Int?

    /// CPU CFS (Completely Fair Scheduler) period, as a duration string.
    public var cpu_period: String?

    /// CPU CFS (Completely Fair Scheduler) quota, as a duration string.
    public var cpu_quota: String?

    /// Real-time scheduler CPU runtime allocation (microseconds or duration string).
    public var cpu_rt_runtime: String?

    /// Real-time scheduler CPU period allocation (microseconds or duration string).
    public var cpu_rt_period: String?

    /// Number of (potentially virtual/fractional) CPUs to allocate. `0` means no limit.
    public var cpus: Double?

    /// Explicit CPUs on which execution is permitted (e.g. "0-3" or "0,1").
    public var cpuset: String?

    /// Additional container capabilities to add.
    public var cap_add: [String]?

    /// Container capabilities to drop.
    public var cap_drop: [String]?

    /// The cgroup namespace to join (`host` or `private`).
    public var cgroup: String?

    /// Optional parent cgroup for the container.
    public var cgroup_parent: String?

    /// Credential spec for a managed service account (mainly for Windows containers).
    public var credential_spec: CredentialSpec?

    /// Development-time configuration for keeping the container in sync with source (`compose watch`).
    public var develop: Develop?

    /// Device cgroup rules for this container.
    public var device_cgroup_rules: [String]?

    /// Device mappings in the form `HOST_PATH:CONTAINER_PATH[:CGROUP_PERMISSIONS]`, or CDI device references.
    public var devices: [String]?

    /// Custom DNS servers for the container's network interface. Accepts a single value or a list.
    public var dns: [String]?

    /// Custom DNS resolver options (`/etc/resolv.conf`).
    public var dns_opt: [String]?

    /// Custom DNS search domains. Accepts a single value or a list.
    public var dns_search: [String]?

    /// Custom domain name for the service container (must be a valid RFC 1123 hostname).
    public var domainname: String?

    /// Incoming ports (or port ranges) exposed to linked services but not published to the host.
    public var expose: [String]?

    /// Base service definition to merge with, per the Compose spec `extends` key.
    public var extends: ServiceExtends?

    /// Links to service containers managed outside of this Compose application.
    public var external_links: [String]?

    /// GPU devices to allocate to the container.
    public var gpus: GPU?

    /// Additional groups (by name or number) the container's user must be a member of.
    public var group_add: [String]?

    /// Runs an init process (PID 1) inside the container that forwards signals and reaps processes.
    public var `init`: Bool?

    /// IPC isolation mode for the service container (`shareable` or `service:{name}`).
    public var ipc: String?

    /// Container's isolation technology. Supported values are platform specific.
    public var isolation: String?

    /// External file(s) to load labels from. Accepts a single path or a list of paths.
    public var label_file: [String]?

    /// Network links to containers in another service (`SERVICE` or `SERVICE:ALIAS`).
    public var links: [String]?

    /// Logging configuration for the service's containers.
    public var logging: Logging?

    /// MAC address for the service container.
    public var mac_address: String?

    /// Memory reservation, set as a byte-value string (e.g. "128m").
    public var mem_reservation: String?

    /// Percentage (0-100) of anonymous memory pages the host kernel may swap out for this container.
    public var mem_swappiness: Int?

    /// Total memory + swap limit, set as a byte-value string.
    public var memswap_limit: String?

    /// Per-model options keyed by model name, for models referenced via the long syntax.
    public var models: [String: Service.Model?]?

    /// Network mode for the container (e.g. `host`, `bridge`, `none`, `service:{name}`).
    // TODO: - When set, the networks attribute is not allowed and Compose rejects any Compose file containing both attributes.
    public var network_mode: String?

    /// Disables the OOM killer for this container when `true`.
    public var oom_kill_disable: Bool?

    /// Tunes the container's preference to be OOM-killed (-1000 to 1000).
    public var oom_score_adj: Int?

    /// PID namespace mode for the container.
    public var pid: String?

    /// Tune the container's maximum number of PIDs.
    public var pids_limit: Int?

    /// Commands run after the container has started.
    public var post_start: [Hook]?

    /// Commands run before the container stops.
    public var pre_stop: [Hook]?

    /// Configuration for a service implemented by a Compose provider plugin.
    public var provider: Provider?

    /// Policy controlling when Compose pulls the image (e.g. "always", "never", "missing", "build").
    public var pull_policy: String?

    /// Runtime to use for the service's containers (e.g. "runc", "nvidia").
    public var runtime: String?

    /// Number of containers to run for this service.
    public var scale: Int?

    /// Additional security options (labels) applied to the container.
    public var security_opt: [String]?

    /// Size of `/dev/shm` for this container, set as a byte-value string.
    public var shm_size: String?

    /// Time to wait before sending SIGKILL after a graceful stop request, as a duration string.
    public var stop_grace_period: String?

    /// Custom signal used to stop the container.
    public var stop_signal: String?

    /// Storage driver options for the container.
    // optional value to handle reset
    public var storage_opt: [String: String?]?

    /// Kernel parameters to set in the container. Accepts either a map or a list of `key=value` strings.
    // optional value to handle reset
    public var sysctls: [String: String?]?

    /// Mount points to mount as `tmpfs` inside the container. Accepts a single value or a list.
    public var tmpfs: [String]?

    /// Ulimit overrides keyed by ulimit name (e.g. "nofile", "nproc").
    // optional value to handle reset
    public var ulimits: [String: Ulimit?]?

    /// When `true`, exposes the Docker/container engine API socket to this service.
    public var use_api_socket: Bool?

    /// User namespace mode for the container (e.g. "host").
    public var userns_mode: String?

    /// UTS namespace mode for the container (e.g. "host").
    public var uts: String?

    /// Mounts all volumes from another service or container.
    public var volumes_from: [String]?

    /// Other services that depend on this service
    public var dependedBy: [String] = []

    public var tags: [String: ComposeTag?] = [:]

    // Defines custom coding keys to map YAML keys to Swift properties
    // dependedBy not included
    //    enum CodingKeys: String, CodingKey {
    //        case image, build, deploy, restart, healthcheck, volumes, environment,
    //            env_file, ports, command, depends_on, user,
    //            container_name, labels, networks, hostname, entrypoint, privileged,
    //            read_only, working_dir, configs, secrets, stdin_open, tty, platform,
    //            mem_limit, extra_hosts, profiles,
    //            annotations, attach, blkio_config, cpu_count, cpu_percent,
    //            cpu_shares, cpu_period, cpu_quota, cpu_rt_runtime,
    //            cpu_rt_period, cpus, cpuset, cap_add, cap_drop, cgroup,
    //            cgroup_parent, credential_spec, develop,
    //            device_cgroup_rules, devices, dns, dns_opt, dns_search, domainname,
    //            expose, extends, external_links, gpus,
    //            group_add, `init`, ipc, isolation, label_file, links, logging,
    //            mac_address, mem_reservation, mem_swappiness,
    //            memswap_limit, models, network_mode, oom_kill_disable,
    //            oom_score_adj, pid, pids_limit, post_start, pre_stop,
    //            provider, pull_policy, runtime, scale, security_opt, shm_size,
    //            stop_grace_period, stop_signal, storage_opt,
    //            sysctls, tmpfs, ulimits, use_api_socket, userns_mode, uts,
    //            volumes_from
    //    }

    /// Public memberwise initializer for testing
    public init(
        image: String? = nil,
        build: Build? = nil,
        deploy: Deploy? = nil,
        restart: String? = nil,
        healthcheck: Healthcheck? = nil,
        volumes: [Volume]? = nil,
        environment: [String: String]? = nil,
        env_file: [EnvFileEntry]? = nil,
        ports: [Service.Port]? = nil,
        command: [String]? = nil,
        depends_on: [String]? = nil,
        dependencyConditions: [String: Dependency]? = nil,
        user: String? = nil,
        container_name: String? = nil,
        labels: [String: String]? = nil,
        networks: [String: Network]? = nil,
        hostname: String? = nil,
        entrypoint: [String]? = nil,
        privileged: Bool? = nil,
        read_only: Bool? = nil,
        working_dir: String? = nil,
        platform: String? = nil,
        configs: [Config]? = nil,
        secrets: [Secret]? = nil,
        stdin_open: Bool? = nil,
        tty: Bool? = nil,
        mem_limit: String? = nil,
        extra_hosts: [String]? = nil,
        profiles: [String]? = nil,
        annotations: [String: String]? = nil,
        attach: Bool? = nil,
        blkio_config: BlkioConfig? = nil,
        cpu_count: Int? = nil,
        cpu_percent: Double? = nil,
        cpu_shares: Int? = nil,
        cpu_period: String? = nil,
        cpu_quota: String? = nil,
        cpu_rt_runtime: String? = nil,
        cpu_rt_period: String? = nil,
        cpus: Double? = nil,
        cpuset: String? = nil,
        cap_add: [String]? = nil,
        cap_drop: [String]? = nil,
        cgroup: String? = nil,
        cgroup_parent: String? = nil,
        credential_spec: CredentialSpec? = nil,
        develop: Develop? = nil,
        device_cgroup_rules: [String]? = nil,
        devices: [String]? = nil,
        dns: [String]? = nil,
        dns_opt: [String]? = nil,
        dns_search: [String]? = nil,
        domainname: String? = nil,
        expose: [String]? = nil,
        extends: ServiceExtends? = nil,
        external_links: [String]? = nil,
        gpus: GPU? = nil,
        group_add: [String]? = nil,
        `init`: Bool? = nil,
        ipc: String? = nil,
        isolation: String? = nil,
        label_file: [String]? = nil,
        links: [String]? = nil,
        logging: Logging? = nil,
        mac_address: String? = nil,
        mem_reservation: String? = nil,
        mem_swappiness: Int? = nil,
        memswap_limit: String? = nil,
        models: [String: Model?]? = nil,
        network_mode: String? = nil,
        oom_kill_disable: Bool? = nil,
        oom_score_adj: Int? = nil,
        pid: String? = nil,
        pids_limit: Int? = nil,
        post_start: [Hook]? = nil,
        pre_stop: [Hook]? = nil,
        provider: Provider? = nil,
        pull_policy: String? = nil,
        runtime: String? = nil,
        scale: Int? = nil,
        security_opt: [String]? = nil,
        shm_size: String? = nil,
        stop_grace_period: String? = nil,
        stop_signal: String? = nil,
        storage_opt: [String: String]? = nil,
        sysctls: [String: String]? = nil,
        tmpfs: [String]? = nil,
        ulimits: [String: Ulimit]? = nil,
        use_api_socket: Bool? = nil,
        userns_mode: String? = nil,
        uts: String? = nil,
        volumes_from: [String]? = nil,
        dependedBy: [String] = []
    ) {
        self.image = image
        self.build = build
        self.deploy = deploy
        self.restart = restart
        self.healthcheck = healthcheck
        self.volumes = volumes
        self.environment = environment
        self.env_file = env_file
        self.ports = ports
        self.command = command
        self.depends_on = depends_on
        self.dependencyConditions = dependencyConditions
        self.user = user
        self.container_name = container_name
        self.labels = labels
        self.networks = networks
        self.hostname = hostname
        self.entrypoint = entrypoint
        self.privileged = privileged
        self.read_only = read_only
        self.working_dir = working_dir
        self.platform = platform
        self.configs = configs
        self.secrets = secrets
        self.stdin_open = stdin_open
        self.tty = tty
        self.mem_limit = mem_limit
        self.extra_hosts = extra_hosts
        self.profiles = profiles
        self.annotations = annotations
        self.attach = attach
        self.blkio_config = blkio_config
        self.cpu_count = cpu_count
        self.cpu_percent = cpu_percent
        self.cpu_shares = cpu_shares
        self.cpu_period = cpu_period
        self.cpu_quota = cpu_quota
        self.cpu_rt_runtime = cpu_rt_runtime
        self.cpu_rt_period = cpu_rt_period
        self.cpus = cpus
        self.cpuset = cpuset
        self.cap_add = cap_add
        self.cap_drop = cap_drop
        self.cgroup = cgroup
        self.cgroup_parent = cgroup_parent
        self.credential_spec = credential_spec
        self.develop = develop
        self.device_cgroup_rules = device_cgroup_rules
        self.devices = devices
        self.dns = dns
        self.dns_opt = dns_opt
        self.dns_search = dns_search
        self.domainname = domainname
        self.expose = expose
        self.extends = extends
        self.external_links = external_links
        self.gpus = gpus
        self.group_add = group_add
        self.`init` = `init`
        self.ipc = ipc
        self.isolation = isolation
        self.label_file = label_file
        self.links = links
        self.logging = logging
        self.mac_address = mac_address
        self.mem_reservation = mem_reservation
        self.mem_swappiness = mem_swappiness
        self.memswap_limit = memswap_limit
        self.models = models
        self.network_mode = network_mode
        self.oom_kill_disable = oom_kill_disable
        self.oom_score_adj = oom_score_adj
        self.pid = pid
        self.pids_limit = pids_limit
        self.post_start = post_start
        self.pre_stop = pre_stop
        self.provider = provider
        self.pull_policy = pull_policy
        self.runtime = runtime
        self.scale = scale
        self.security_opt = security_opt
        self.shm_size = shm_size
        self.stop_grace_period = stop_grace_period
        self.stop_signal = stop_signal
        self.storage_opt = storage_opt
        self.sysctls = sysctls
        self.tmpfs = tmpfs
        self.ulimits = ulimits
        self.use_api_socket = use_api_socket
        self.userns_mode = userns_mode
        self.uts = uts
        self.volumes_from = volumes_from
        self.dependedBy = dependedBy
    }

    /// True when this service should be included by default given the currently
    /// active profiles. Per the Compose spec: a service with no `profiles` is
    /// always eligible; a service with `profiles` is eligible only when at least
    /// one of them is active. This gate is bypassed entirely for services named
    /// explicitly on the command line and for dependencies of an eligible service
    /// (see `selectServices(from:requestedServices:activeProfiles:)`).
    public func isProfileEligible(activeProfiles: Set<String>) -> Bool {
        guard let profiles, !profiles.isEmpty else { return true }
        return !Set(profiles).isDisjoint(with: activeProfiles)
    }
}

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

        public init(from decoder: Decoder) throws {
            if let s = try? decoder.singleValueContainer().decode(
                String.self
            ) {
                path = s
                required = true
            } else {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                path = try c.decode(String.self, forKey: .path)
                required = try c.decode(Bool.self, forKey: .required)
            }
        }

        public init(path: String, required: Bool) {
            self.path = path
            self.required = required
        }
    }
}

//
//
//#Playground {
//    let base = """
//      services:
//        foo:
//          image: nginx:latest
//          ports:
//            - ${HOST_PORT}
//          environment:
//            POSTGRES_USER: example
//            POSTGRES_DB: exampledb
//          command: ["echo", "foo"]
//          volumes:
//            - foo:/work
//          secrets:
//            - source: my-token
//              target: test
//            - source: my-token2
//              target: test2
//
//    """
//    let merging = """
//        services:
//          foo:
//            environment:
//              key2: example
//            command: ["echo", "bar"]
//            volumes:
//              - bar:/work
//            secrets:
//              - source: my-token3
//                target: test2
//
//        """
//
//    let env = ["HOST_PORT":"8080"]
//    do {
//        let decoder = YAMLDecoder()
//        let base = try decoder.decode(DockerCompose.self, from: base, userInfo: [ .env!: env])
//        let merging = try decoder.decode(DockerCompose.self, from: merging)
//        let merged = try base.deepMerge(with: merging)
//        print(merged.services["foo"]??.ports)
//    } catch (let error) {
//        print(error)
//    }
//}

extension Service {
    //    ServiceExtends

    // needs to be processed in order of defined within the compose file.
    public func resolveExtends(
        composeDirectory: URL,
        selfName: String,
        servicesBeforeSelf: [Service]
    ) throws -> Service {
        var service = self
        guard let extend = self.extends else {
            return service
        }

        // extending from anther file
        if let file = extend.file {
            //            let fullURL = URL(filePath: file, relativeTo: composeDirectory)
            //            let compose = try DockerCompose(url: fullURL)
            //            guard let baseServiceIndex = compose.services.firstIndex(where: {$0.key == selfName}) else {
            //                throw ComposeError.invalidExtends("Service \(selfName) not found in \(file)")
            //            }
            //
            //            let baseService = compose.services[baseServiceIndex]

            //            let resolved = baseService.value.resolveExtends(composeDirectory: composeDirectory, selfName: selfName, servicesBeforeSelf: <#T##[Service]#>)
            //            let merged = baseService.value.deepMerge(with: self)
        }

        // extending from the same file
        //        self.services.ser

        return service
    }
}

//
//extension Array where Element == String {
//    func merge(with otherVolumes: [Service.Secret]) -> [Service.Secret] {
//        var result: [Service.Secret] = self
//        for new in otherVolumes {
//            if let firstIndex = result.firstIndex(where: {
//                $0.target == new.target
//            }) {
//                result[firstIndex] = result[firstIndex].merge(with: new)
//            } else {
//                result.append(new)
//            }
//        }
//
//        return result
//    }
//}

extension Service {

    /// Returns the services in topological order based on `depends_on` relationships.
    public static func topoSortConfiguredServices(
        _ services: [(serviceName: String, service: Service)]
    ) throws -> [(serviceName: String, service: Service)] {

        var visited = Set<String>()
        var visiting = Set<String>()
        var sorted: [(String, Service)] = []

        func visit(_ name: String, from service: String? = nil) throws {
            guard
                var serviceTuple = services.first(where: {
                    $0.serviceName == name
                })
            else { return }
            if let service {
                serviceTuple.service.dependedBy.append(service)
            }

            if visiting.contains(name) {
                throw NSError(
                    domain: "ComposeError",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Cyclic dependency detected involving '\(name)'"
                    ]
                )
            }
            guard !visited.contains(name) else { return }

            visiting.insert(name)
            for depName in serviceTuple.service.depends_on ?? [] {
                try visit(depName, from: name)
            }
            visiting.remove(name)
            visited.insert(name)
            sorted.append(serviceTuple)
        }

        for (serviceName, _) in services {
            if !visited.contains(serviceName) {
                try visit(serviceName)
            }
        }

        return sorted
    }

    /// Selects the services `up`, `build`, and `down` should act on by default,
    /// applying both explicit service-name filtering and Compose `profiles` gating.
    ///
    /// Per the Compose spec, `profiles` gating is bypassed in two cases:
    ///   - a service named explicitly in `requestedServices`
    ///   - a service reached only as a `depends_on` dependency of an eligible
    ///     service (its own `profiles` are ignored)
    /// When `requestedServices` is empty, the seed set is every service that
    /// is profile-eligible for `activeProfiles` (unprofiled, or one of its
    /// profiles is active); dependencies of that seed are then pulled in
    /// regardless of their own profile.
    public static func selectServices(
        from services: [(serviceName: String, service: Service)],
        requestedServices: [String],
        activeProfiles: Set<String> = []
    ) -> [(serviceName: String, service: Service)] {
        let servicesByName = Dictionary(
            uniqueKeysWithValues: services.map { ($0.serviceName, $0.service) }
        )

        let seedNames: [String]
        if !requestedServices.isEmpty {
            seedNames = requestedServices
        } else {
            seedNames =
                services
                .filter {
                    $0.service.isProfileEligible(activeProfiles: activeProfiles)
                }
                .map(\.serviceName)
        }

        var selected = Set<String>()

        func include(_ serviceName: String) {
            guard let service = servicesByName[serviceName],
                selected.insert(serviceName).inserted
            else {
                return
            }

            for dependency in service.depends_on ?? [] {
                include(dependency)
            }
        }

        for serviceName in seedNames {
            include(serviceName)
        }

        return services.filter { selected.contains($0.serviceName) }
    }
}

extension Service.EnvFileEntry: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        if let s = try node.string(envs: envs) {
            self.path = s
            self.required = true
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

        guard let required = try mapping.value(for: CodingKeys.required).bool
        else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.required],
                    debugDescription:
                        "EnvFileEntry entry must have a 'required' specified."
                )
            )
        }
        self.required = required
    }
}

extension Service: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.image = try? mapping.value(for: CodingKeys.image).string(
            envs: envs
        )
        self.build = try? Service.Build(
            mapping.value(for: CodingKeys.build),
            envs: envs
        )
        self.deploy = try? Service.Deploy(
            mapping.value(for: CodingKeys.deploy),
            envs: envs
        )

        self.restart = try? mapping.value(for: CodingKeys.restart).string(
            envs: envs
        )

        self.healthcheck = try? Service.Healthcheck(
            mapping.value(for: CodingKeys.healthcheck),
            envs: envs
        )

        self.volumes = try? mapping.value(for: CodingKeys.volumes)
            .array(of: Service.Volume.self, envs: envs)

        // `environment:` accepts a `KEY: VALUE` map or a `KEY=VALUE` list.
        if let asMap = try? mapping.value(for: CodingKeys.environment)
            .dictionary(envs: envs)
        {
            self.environment = asMap
        } else if let asList = try? mapping.value(for: CodingKeys.environment)
            .array(of: String.self, envs: envs), !asList.isEmpty
        {
            self.environment = Utility.parseKeyValueList(asList, isEnv: true)
        } else {
            self.environment = nil
        }

        // `env_file:` accepts a single path string, a list of paths, or a list
        // of {path, required} entries (EnvFileEntry itself handles the bare
        // string vs mapping distinction per-element).
        if let entries = try? mapping.value(for: CodingKeys.env_file)
            .array(of: EnvFileEntry.self, envs: envs), !entries.isEmpty
        {
            self.env_file = entries
        } else if let single = try? mapping.value(for: CodingKeys.env_file)
            .string(envs: envs)
        {
            self.env_file = [.init(path: single, required: true)]
        } else {
            self.env_file = nil
        }

        self.ports = try? mapping.value(for: CodingKeys.ports)
            .array(of: Service.Port.self, envs: envs)

        // `command` accepts either a single string or an array of strings.
        if let cmdArray = try? mapping.value(for: CodingKeys.command)
            .array(of: String.self, envs: envs), !cmdArray.isEmpty
        {
            self.command = cmdArray
        } else if let cmdString = try? mapping.value(for: CodingKeys.command)
            .string(envs: envs)
        {
            self.command = [cmdString]
        } else {
            self.command = nil
        }

        // `depends_on` accepts a single string, a list of strings, or a map of
        // service name -> Dependency options (possibly null).
        let dependsOnNode = try? mapping.value(for: CodingKeys.depends_on)
        if let dependsOnString = try? dependsOnNode?.string(envs: envs) {
            self.depends_on = [dependsOnString]
            self.dependencyConditions = [dependsOnString: Dependency()]
        } else if let dependsOnArray = try? dependsOnNode?.array(
            of: String.self,
            envs: envs
        ),
            !dependsOnArray.isEmpty
        {
            self.depends_on = dependsOnArray
            self.dependencyConditions = Dictionary(
                uniqueKeysWithValues: dependsOnArray.map { ($0, Dependency()) }
            )
        } else if let dependsOnMapping = dependsOnNode?.mapping {
            var normalized: [String: Dependency] = [:]
            for (key, valueNode) in dependsOnMapping {
                guard let keyString = key.string else { continue }
                if valueNode.null != nil {
                    normalized[keyString] = Dependency()
                } else {
                    normalized[keyString] = try? Dependency(
                        valueNode,
                        envs: envs
                    )
                    if normalized[keyString] == nil {
                        normalized[keyString] = Dependency()
                    }
                }
            }
            self.depends_on = normalized.keys.sorted()
            self.dependencyConditions = normalized
        } else {
            self.depends_on = nil
            self.dependencyConditions = nil
        }

        self.user = try? mapping.value(for: CodingKeys.user).string(envs: envs)
        self.container_name = try? mapping.value(for: CodingKeys.container_name)
            .string(envs: envs)

        // labels:
        // com.example.description: "Accounting webapp"
        // com.example.department: "Finance"
        // com.example.label-with-empty-value: ""
        // or
        // labels:
        // - "com.example.description=Accounting webapp"
        // - "com.example.department=Finance"
        // - "com.example.label-with-empty-value"
        self.labels = try? mapping.value(for: CodingKeys.labels).dictionary(
            envs: envs,
            isEnv: false
        )

        // `networks` accepts a list of network names, or a map of network name ->
        // Network options (possibly null).
        let networksNode = try? mapping.value(for: CodingKeys.networks)
        if let networkArray = try? networksNode?.array(
            of: String.self,
            envs: envs
        ),
            !networkArray.isEmpty
        {
            self.networks = Dictionary(
                uniqueKeysWithValues: networkArray.map {
                    ($0, Service.Network())
                }
            )
        } else if let networkMapping = networksNode?.mapping {
            var normalized: [String: Service.Network] = [:]
            for (key, valueNode) in networkMapping {
                guard let keyString = key.string else { continue }
                if valueNode.null != nil {
                    normalized[keyString] = Service.Network()
                } else {
                    normalized[keyString] = try? Service.Network(
                        valueNode,
                        envs: envs
                    )
                    if normalized[keyString] == nil {
                        normalized[keyString] = Service.Network()
                    }
                }
            }
            self.networks = normalized
        } else {
            self.networks = nil
        }

        self.hostname = try? mapping.value(for: CodingKeys.hostname).string(
            envs: envs
        )

        // `entrypoint` accepts either a single string or an array of strings.
        if let entrypointArray = try? mapping.value(for: CodingKeys.entrypoint)
            .array(of: String.self, envs: envs), !entrypointArray.isEmpty
        {
            self.entrypoint = entrypointArray
        } else if let entrypointString = try? mapping.value(
            for: CodingKeys.entrypoint
        )
        .string(envs: envs) {
            self.entrypoint = [entrypointString]
        } else {
            self.entrypoint = nil
        }

        self.privileged = try? mapping.value(for: CodingKeys.privileged).bool
        self.read_only = try? mapping.value(for: CodingKeys.read_only).bool
        self.working_dir = try? mapping.value(for: CodingKeys.working_dir)
            .string(envs: envs)
        self.platform = try? mapping.value(for: CodingKeys.platform).string(
            envs: envs
        )

        self.configs = try? mapping.value(for: CodingKeys.configs)
            .array(of: Service.Config.self, envs: envs)
        self.secrets = try? mapping.value(for: CodingKeys.secrets)
            .array(of: Service.Secret.self, envs: envs)

        self.stdin_open = try? mapping.value(for: CodingKeys.stdin_open).bool
        self.tty = try? mapping.value(for: CodingKeys.tty).bool

        // `mem_limit` accepts a string or a bare int.
        self.mem_limit = try? mapping.value(for: CodingKeys.mem_limit).string(
            envs: envs
        )

        // `extra_hosts` accepts a list of "hostname:IP" strings or a
        // {hostname: IP} map, normalized to list form.
        let extraHostsNode = try? mapping.value(for: CodingKeys.extra_hosts)
        if let list = try? extraHostsNode?.array(of: String.self, envs: envs),
            !list.isEmpty
        {
            self.extra_hosts = list
        } else if let map = try? extraHostsNode?.dictionary(envs: envs) {
            self.extra_hosts = map.map { "\($0.key):\($0.value)" }
        } else {
            self.extra_hosts = nil
        }

        self.profiles = try? mapping.value(for: CodingKeys.profiles)
            .array(of: String.self, envs: envs)

        // `annotations` accepts a map or a `key=value` list.
        if let asMap = try? mapping.value(for: CodingKeys.annotations)
            .dictionary(envs: envs)
        {
            self.annotations = asMap
        } else if let asList = try? mapping.value(for: CodingKeys.annotations)
            .array(of: String.self, envs: envs), !asList.isEmpty
        {
            self.annotations = Utility.parseKeyValueList(asList, isEnv: false)
        } else {
            self.annotations = nil
        }

        self.attach = try? mapping.value(for: CodingKeys.attach).bool

        self.blkio_config = try? Service.BlkioConfig(
            mapping.value(for: CodingKeys.blkio_config),
            envs: envs
        )

        self.cpu_count = try? mapping.value(for: CodingKeys.cpu_count).int(
            envs: envs
        )
        self.cpu_percent = try? mapping.value(for: CodingKeys.cpu_percent).float
        self.cpu_shares = try? mapping.value(for: CodingKeys.cpu_shares).int(
            envs: envs
        )

        self.cpu_period = try? mapping.value(for: CodingKeys.cpu_period).string(
            envs: envs
        )
        self.cpu_quota = try? mapping.value(for: CodingKeys.cpu_quota).string(
            envs: envs
        )
        self.cpu_rt_runtime = try? mapping.value(for: CodingKeys.cpu_rt_runtime)
            .string(envs: envs)
        self.cpu_rt_period = try? mapping.value(for: CodingKeys.cpu_rt_period)
            .string(envs: envs)

        // `cpus` accepts a Double or a numeric string.
        if let d = try? mapping.value(for: CodingKeys.cpus).float {
            self.cpus = d
        } else if let s = try? mapping.value(for: CodingKeys.cpus).string(
            envs: envs
        ) {
            self.cpus = Double(s)
        } else {
            self.cpus = nil
        }

        self.cpuset = try? mapping.value(for: CodingKeys.cpuset).string(
            envs: envs
        )

        self.cap_add = try? mapping.value(for: CodingKeys.cap_add)
            .array(of: String.self, envs: envs)
        self.cap_drop = try? mapping.value(for: CodingKeys.cap_drop)
            .array(of: String.self, envs: envs)

        self.cgroup = try? mapping.value(for: CodingKeys.cgroup).string(
            envs: envs
        )
        self.cgroup_parent = try? mapping.value(for: CodingKeys.cgroup_parent)
            .string(envs: envs)

        self.credential_spec = try? Service.CredentialSpec(
            mapping.value(for: CodingKeys.credential_spec),
            envs: envs
        )

        self.develop = try? Service.Develop(
            mapping.value(for: CodingKeys.develop),
            envs: envs
        )

        self.device_cgroup_rules = try? mapping.value(
            for: CodingKeys.device_cgroup_rules
        )
        .array(of: String.self, envs: envs)
        self.devices = try? mapping.value(for: CodingKeys.devices)
            .array(of: String.self, envs: envs)

        self.dns = try? mapping.value(for: CodingKeys.dns).array(envs: envs)

        self.dns_opt = try? mapping.value(for: CodingKeys.dns_opt)
            .array(of: String.self, envs: envs)
        self.dns_search = try? mapping.value(for: CodingKeys.dns_search).array(envs: envs)

        self.domainname = try? mapping.value(for: CodingKeys.domainname).string(
            envs: envs
        )

        // `expose` entries may be bare port numbers or quoted strings.
        self.expose = try? mapping.value(for: CodingKeys.expose)
            .array(of: String.self, envs: envs)

        self.extends = try? Service.ServiceExtends(
            mapping.value(for: CodingKeys.extends),
            envs: envs
        )
        self.external_links = try? mapping.value(for: CodingKeys.external_links)
            .array(of: String.self, envs: envs)

        self.gpus = try? Service.GPU(
            mapping.value(for: CodingKeys.gpus),
            envs: envs
        )

        self.group_add = try? mapping.value(for: CodingKeys.group_add)
            .array(of: String.self, envs: envs)

        self.`init` = try? mapping.value(for: CodingKeys.`init`).bool

        self.ipc = try? mapping.value(for: CodingKeys.ipc).string(envs: envs)
        self.isolation = try? mapping.value(for: CodingKeys.isolation).string(
            envs: envs
        )

        self.label_file = try? mapping.value(for: CodingKeys.label_file).array(envs: envs)

        self.links = try? mapping.value(for: CodingKeys.links)
            .array(of: String.self, envs: envs)

        self.logging = try? Service.Logging(
            mapping.value(for: CodingKeys.logging),
            envs: envs
        )

        self.mac_address = try? mapping.value(for: CodingKeys.mac_address)
            .string(envs: envs)
        self.mem_reservation = try? mapping.value(
            for: CodingKeys.mem_reservation
        )
        .string(envs: envs)
        self.mem_swappiness = try? mapping.value(for: CodingKeys.mem_swappiness)
            .int(envs: envs)

        // `memswap_limit` accepts a string or a bare int.
        self.memswap_limit = try? mapping.value(for: CodingKeys.memswap_limit)
            .string(envs: envs)

        // `models` accepts a list of model names, or a map of model name ->
        // Model options (possibly null).
        // services:
        //   short_syntax:
        //    image: app
        //    models:
        //     - my_model
        // or
        // services:
        //  long_syntax:
        //    image: app
        //    models:
        //      my_model:
        //        endpoint_var: MODEL_URL
        //        model_var: MODEL

        self.models = try? mapping.value(for: CodingKeys.models).dictionary(envs: envs, transformMap: { _, node in
            return try? Service.Model(
                node,
                envs: envs
            )
        }, transformArray: { stringArray in
            return stringArray.toDictionary(
                valueType: Model?.self,
                makeValue: { _ in nil }
            )
        })

        self.network_mode = try? mapping.value(for: CodingKeys.network_mode)
            .string(envs: envs)
        self.oom_kill_disable = try? mapping.value(
            for: CodingKeys.oom_kill_disable
        ).bool
        self.oom_score_adj = try? mapping.value(for: CodingKeys.oom_score_adj)
            .int(envs: envs)

        self.pid = try? mapping.value(for: CodingKeys.pid).string(envs: envs)
        self.pids_limit = try? mapping.value(for: CodingKeys.pids_limit).int(
            envs: envs
        )

        self.post_start = try? mapping.value(for: CodingKeys.post_start)
            .array(of: Service.Hook.self, envs: envs)
        self.pre_stop = try? mapping.value(for: CodingKeys.pre_stop)
            .array(of: Service.Hook.self, envs: envs)

        self.provider = try? Service.Provider(
            mapping.value(for: CodingKeys.provider),
            envs: envs
        )

        self.pull_policy = try? mapping.value(for: CodingKeys.pull_policy)
            .string(envs: envs)
        self.runtime = try? mapping.value(for: CodingKeys.runtime).string(
            envs: envs
        )
        self.scale = try? mapping.value(for: CodingKeys.scale).int(envs: envs)

        self.security_opt = try? mapping.value(for: CodingKeys.security_opt)
            .array(of: String.self, envs: envs)

        // `shm_size` accepts a string or a bare int.
        self.shm_size = try? mapping.value(for: CodingKeys.shm_size).string(
            envs: envs
        )

        self.stop_grace_period = try? mapping.value(
            for: CodingKeys.stop_grace_period
        ).string(envs: envs)
        self.stop_signal = try? mapping.value(for: CodingKeys.stop_signal)
            .string(envs: envs)

        self.storage_opt = try? mapping.value(for: CodingKeys.storage_opt)
            .dictionary(envs: envs)

        // `sysctls` accepts a map or a `key=value` list.
        self.sysctls = try? mapping.value(for: CodingKeys.sysctls).dictionary(
            envs: envs,
            isEnv: false
        )

        self.tmpfs = try? mapping.value(for: CodingKeys.tmpfs).array(envs: envs)

        // `ulimits` is a map of ulimit name -> Ulimit (int or {soft, hard}).
        self.ulimits = try? mapping.value(for: CodingKeys.tmpfs).dictionary(
            envs: envs,
            transformMap: { key, value in
                try Ulimit(value, envs: envs)
            },
            transformArray: { stringArray in
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [CodingKeys.ulimits],
                        debugDescription:
                            "Invalid yaml data. Expected a mapping or a single value."
                    )
                )
            }
        )


        self.use_api_socket = try? mapping.value(for: CodingKeys.use_api_socket)
            .bool
        self.userns_mode = try? mapping.value(for: CodingKeys.userns_mode)
            .string(envs: envs)
        self.uts = try? mapping.value(for: CodingKeys.uts).string(envs: envs)

        self.volumes_from = try? mapping.value(for: CodingKeys.volumes_from)
            .array(of: String.self, envs: envs)

        self.dependedBy = []
    }

    //    private func decodeStringOrList(
    //        _ mapping: Node.Mapping,
    //        forKey key: CodingKeys,
    //        envs: [String: String]
    //    ) throws -> [String]? {
    //        if let asList = try? mapping.value(for: key).array(
    //            of: String.self,
    //            envs: envs
    //        ),
    //            !asList.isEmpty
    //        {
    //            return asList
    //        } else if let asString = try? mapping.value(for: key).string(envs: envs)
    //        {
    //            return [asString]
    //        } else {
    //            return nil
    //        }
    //    }
    //
    //    private func decodeMapOrList(
    //        _ mapping: Node.Mapping,
    //        forKey key: CodingKeys,
    //        envs: [String: String],
    //        isEnv: Bool
    //    ) throws -> [String: String]? {
    //        if let asMap = try? mapping.value(for: key).dictionary(envs: envs) {
    //            return asMap
    //        } else if let asList = try? mapping.value(for: key)
    //            .array(of: String.self, envs: envs), !asList.isEmpty
    //        {
    //            return Utility.parseKeyValueList(asList, isEnv: isEnv)
    //        } else {
    //            return nil
    //        }
    //    }

}

extension Array {
    //    let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
    func toDictionary<T>(
        valueType: T.Type = T.self,
        makeValue: @escaping (Element) -> T
    )
        -> [Element: T]
    {
        Dictionary(uniqueKeysWithValues: self.map { ($0, makeValue($0)) })
    }

}

//#Playground {
//    let yaml = """
//        services:
//          web:
//            image: nginx:latest
//            ports:
//              - "8080:80"
//              - 80
//            env_file:
//              - path: ./default.env
//                required: true # default
//              - path: ./override.env
//                required: false
//          db:
//            image: postgres:18
//            environment:
//              POSTGRES_USER: example
//              POSTGRES_DB: exampledb
//
//        """
//
//        do {
//            let nodes = try Yams.compose_all(yaml: yaml)
//            //        print(nodes.count(where: {_ in true}))
//            for node in nodes {
//                if let pairs = node.mapping {
//                    for pair in pairs {
//                        if pair.key == "services" {
//                            let map = pair.value.mapping!
//                            for (key, value) in map {
//                                print("key",  key)
//                                let service = try Service(value, envs: [:])
//                                print(service.image, service.ports, service.environment, service.env_file)
//                            }
//                        }
//                    }
//                }
//            }
//        } catch (let error) {
//            print(error)
//        }
//
////    do {
////
////        let decoder = YAMLDecoder()
////        let compose = try decoder.decode(DockerCompose.self, from: string)
////        print(compose.services["web"]??.env_file)
////    } catch (let error) {
////        print(error)
////    }
//}
