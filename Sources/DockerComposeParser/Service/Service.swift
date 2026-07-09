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

    /// Service dependency options keyed by dependency service name.
    // optional value to handle reset
    public var depends_on: [String: Dependency?]?

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
    public var extends: Extends?

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

    public var tags: [String: ComposeTag?] = [:]

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
        depends_on: [String: Dependency?]? = nil,
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
        extends: Extends? = nil,
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
    }
}

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
        self.tags[CodingKeys.image.stringValue] = mapping.composeTag(
            for: CodingKeys.image
        )

        self.build = try? Service.Build(
            mapping.value(for: CodingKeys.build),
            envs: envs
        )
        self.tags[CodingKeys.build.stringValue] = mapping.composeTag(
            for: CodingKeys.build
        )

        self.deploy = try? Service.Deploy(
            mapping.value(for: CodingKeys.deploy),
            envs: envs
        )
        self.tags[CodingKeys.deploy.stringValue] = mapping.composeTag(
            for: CodingKeys.deploy
        )

        self.restart = try? mapping.value(for: CodingKeys.restart).string(
            envs: envs
        )
        self.tags[CodingKeys.restart.stringValue] = mapping.composeTag(
            for: CodingKeys.restart
        )

        self.healthcheck = try? Service.Healthcheck(
            mapping.value(for: CodingKeys.healthcheck),
            envs: envs
        )
        self.tags[CodingKeys.healthcheck.stringValue] = mapping.composeTag(
            for: CodingKeys.healthcheck
        )

        self.volumes = try? mapping.value(for: CodingKeys.volumes)
            .array(of: Service.Volume.self, envs: envs)
        self.tags[CodingKeys.volumes.stringValue] = mapping.composeTag(
            for: CodingKeys.volumes
        )

        // `environment:` accepts a `KEY: VALUE` map or a `KEY=VALUE` list.
        self.environment = try? mapping.value(for: CodingKeys.environment)
            .dictionary(envs: envs, isEnv: true)
        self.tags[CodingKeys.environment.stringValue] = mapping.composeTag(
            for: CodingKeys.environment
        )

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
        self.tags[CodingKeys.env_file.stringValue] = mapping.composeTag(
            for: CodingKeys.env_file
        )

        self.ports = try? mapping.value(for: CodingKeys.ports)
            .array(of: Service.Port.self, envs: envs)
        self.tags[CodingKeys.ports.stringValue] = mapping.composeTag(
            for: CodingKeys.ports
        )

        // `command` accepts either a single string or an array of strings.
        if let cmdArray = try? mapping.value(for: CodingKeys.command)
            .array(of: String.self, envs: envs), !cmdArray.isEmpty
        {
            self.command = cmdArray
        } else {
            self.command = nil
        }
        self.tags[CodingKeys.command.stringValue] = mapping.composeTag(
            for: CodingKeys.command
        )

        // `depends_on` accepts a single string, a list of strings, or a map of
        // service name -> Dependency options (possibly null).
        self.depends_on = try? mapping.value(for: CodingKeys.depends_on)
            .dictionary(
                envs: envs,
                transformMap: { _, node in
                    return
                        (try? Dependency(
                            node,
                            envs: envs
                        )) ?? Dependency()
                },
                transformArray: { stringArray in
                    return stringArray.toDictionary(
                        valueType: Dependency.self,
                        makeValue: { _ in Dependency() }
                    )
                }
            )
        self.tags[CodingKeys.depends_on.stringValue] = mapping.composeTag(
            for: CodingKeys.depends_on
        )

        self.user = try? mapping.value(for: CodingKeys.user).string(envs: envs)
        self.tags[CodingKeys.user.stringValue] = mapping.composeTag(
            for: CodingKeys.user
        )

        self.container_name = try? mapping.value(for: CodingKeys.container_name)
            .string(envs: envs)
        self.tags[CodingKeys.container_name.stringValue] = mapping.composeTag(
            for: CodingKeys.container_name
        )

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
        self.tags[CodingKeys.labels.stringValue] = mapping.composeTag(
            for: CodingKeys.labels
        )

        // `networks` accepts a list of network names, or a map of network name ->
        // Network options (possibly null).
        // services:
        // some-service:
        //   networks:
        //     - some-network
        //     - other-network
        // or
        // services:
        // some-service:
        //   networks:
        //     some-network:
        //       aliases:
        //         - alias1
        //         - alias3
        //     other-network:
        //       aliases:
        //         - alias2
        self.networks = try? mapping.value(for: CodingKeys.networks).dictionary(
            envs: envs,
            transformMap: { _, value in
                return
                    (try? Service.Network(
                        value,
                        envs: envs
                    )) ?? Service.Network()
            },
            transformArray: { stringArray in
                return stringArray.toDictionary(
                    valueType: Network?.self,
                    makeValue: { _ in Service.Network() }
                )

            }
        )
        self.tags[CodingKeys.networks.stringValue] = mapping.composeTag(
            for: CodingKeys.networks
        )

        self.hostname = try? mapping.value(for: CodingKeys.hostname).string(
            envs: envs
        )
        self.tags[CodingKeys.hostname.stringValue] = mapping.composeTag(
            for: CodingKeys.hostname
        )

        // `entrypoint` accepts either a single string or an array of strings.
        if let entrypointArray = try? mapping.value(for: CodingKeys.entrypoint)
            .array(of: String.self, envs: envs), !entrypointArray.isEmpty
        {
            self.entrypoint = entrypointArray
        } else {
            self.entrypoint = nil
        }
        self.tags[CodingKeys.entrypoint.stringValue] = mapping.composeTag(
            for: CodingKeys.entrypoint
        )

        self.privileged = try? mapping.value(for: CodingKeys.privileged).bool(envs: envs)
        self.tags[CodingKeys.privileged.stringValue] = mapping.composeTag(
            for: CodingKeys.privileged
        )

        self.read_only = try? mapping.value(for: CodingKeys.read_only).bool(envs: envs)
        self.tags[CodingKeys.read_only.stringValue] = mapping.composeTag(
            for: CodingKeys.read_only
        )

        self.working_dir = try? mapping.value(for: CodingKeys.working_dir)
            .string(envs: envs)
        self.tags[CodingKeys.working_dir.stringValue] = mapping.composeTag(
            for: CodingKeys.working_dir
        )

        self.platform = try? mapping.value(for: CodingKeys.platform).string(
            envs: envs
        )
        self.tags[CodingKeys.platform.stringValue] = mapping.composeTag(
            for: CodingKeys.platform
        )

        self.configs = try? mapping.value(for: CodingKeys.configs)
            .array(of: Service.Config.self, envs: envs)
        self.tags[CodingKeys.configs.stringValue] = mapping.composeTag(
            for: CodingKeys.configs
        )

        self.secrets = try? mapping.value(for: CodingKeys.secrets)
            .array(of: Service.Secret.self, envs: envs)
        self.tags[CodingKeys.secrets.stringValue] = mapping.composeTag(
            for: CodingKeys.secrets
        )

        self.stdin_open = try? mapping.value(for: CodingKeys.stdin_open).bool(envs: envs)
        self.tags[CodingKeys.stdin_open.stringValue] = mapping.composeTag(
            for: CodingKeys.stdin_open
        )

        self.tty = try? mapping.value(for: CodingKeys.tty).bool(envs: envs)
        self.tags[CodingKeys.tty.stringValue] = mapping.composeTag(
            for: CodingKeys.tty
        )

        // `mem_limit` accepts a string or a bare int.
        self.mem_limit = try? mapping.value(for: CodingKeys.mem_limit).string(
            envs: envs
        )
        self.tags[CodingKeys.mem_limit.stringValue] = mapping.composeTag(
            for: CodingKeys.mem_limit
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
        self.tags[CodingKeys.extra_hosts.stringValue] = mapping.composeTag(
            for: CodingKeys.extra_hosts
        )

        self.profiles = try? mapping.value(for: CodingKeys.profiles)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.profiles.stringValue] = mapping.composeTag(
            for: CodingKeys.profiles
        )

        // `annotations` accepts a map or a `key=value` list.
        self.annotations = try? mapping.value(for: CodingKeys.annotations)
            .dictionary(envs: envs)
        self.tags[CodingKeys.annotations.stringValue] = mapping.composeTag(
            for: CodingKeys.annotations
        )

        self.attach = try? mapping.value(for: CodingKeys.attach).bool(envs: envs)
        self.tags[CodingKeys.attach.stringValue] = mapping.composeTag(
            for: CodingKeys.attach
        )

        self.blkio_config = try? Service.BlkioConfig(
            mapping.value(for: CodingKeys.blkio_config),
            envs: envs
        )
        self.tags[CodingKeys.blkio_config.stringValue] = mapping.composeTag(
            for: CodingKeys.blkio_config
        )

        self.cpu_count = try? mapping.value(for: CodingKeys.cpu_count).int(
            envs: envs
        )
        self.tags[CodingKeys.cpu_count.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_count
        )

        self.cpu_percent = try? mapping.value(for: CodingKeys.cpu_percent).float(envs: envs)
        self.tags[CodingKeys.cpu_percent.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_percent
        )

        self.cpu_shares = try? mapping.value(for: CodingKeys.cpu_shares).int(
            envs: envs
        )
        self.tags[CodingKeys.cpu_shares.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_shares
        )

        self.cpu_period = try? mapping.value(for: CodingKeys.cpu_period).string(
            envs: envs
        )
        self.tags[CodingKeys.cpu_period.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_period
        )

        self.cpu_quota = try? mapping.value(for: CodingKeys.cpu_quota).string(
            envs: envs
        )
        self.tags[CodingKeys.cpu_quota.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_quota
        )

        self.cpu_rt_runtime = try? mapping.value(for: CodingKeys.cpu_rt_runtime)
            .string(envs: envs)
        self.tags[CodingKeys.cpu_rt_runtime.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_rt_runtime
        )

        self.cpu_rt_period = try? mapping.value(for: CodingKeys.cpu_rt_period)
            .string(envs: envs)
        self.tags[CodingKeys.cpu_rt_period.stringValue] = mapping.composeTag(
            for: CodingKeys.cpu_rt_period
        )

        // `cpus` accepts a Double or a numeric string (already handled by float(envs:)).
        self.cpus = try? mapping.value(for: CodingKeys.cpus).float(envs: envs)
        self.tags[CodingKeys.cpus.stringValue] = mapping.composeTag(
            for: CodingKeys.cpus
        )

        self.cpuset = try? mapping.value(for: CodingKeys.cpuset).string(
            envs: envs
        )
        self.tags[CodingKeys.cpuset.stringValue] = mapping.composeTag(
            for: CodingKeys.cpuset
        )

        self.cap_add = try? mapping.value(for: CodingKeys.cap_add)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.cap_add.stringValue] = mapping.composeTag(
            for: CodingKeys.cap_add
        )

        self.cap_drop = try? mapping.value(for: CodingKeys.cap_drop)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.cap_drop.stringValue] = mapping.composeTag(
            for: CodingKeys.cap_drop
        )

        self.cgroup = try? mapping.value(for: CodingKeys.cgroup).string(
            envs: envs
        )
        self.tags[CodingKeys.cgroup.stringValue] = mapping.composeTag(
            for: CodingKeys.cgroup
        )

        self.cgroup_parent = try? mapping.value(for: CodingKeys.cgroup_parent)
            .string(envs: envs)
        self.tags[CodingKeys.cgroup_parent.stringValue] = mapping.composeTag(
            for: CodingKeys.cgroup_parent
        )

        self.credential_spec = try? Service.CredentialSpec(
            mapping.value(for: CodingKeys.credential_spec),
            envs: envs
        )
        self.tags[CodingKeys.credential_spec.stringValue] = mapping.composeTag(
            for: CodingKeys.credential_spec
        )

        self.develop = try? Service.Develop(
            mapping.value(for: CodingKeys.develop),
            envs: envs
        )
        self.tags[CodingKeys.develop.stringValue] = mapping.composeTag(
            for: CodingKeys.develop
        )

        self.device_cgroup_rules = try? mapping.value(
            for: CodingKeys.device_cgroup_rules
        )
        .array(of: String.self, envs: envs)
        self.tags[CodingKeys.device_cgroup_rules.stringValue] =
            mapping.composeTag(for: CodingKeys.device_cgroup_rules)

        self.devices = try? mapping.value(for: CodingKeys.devices)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.devices.stringValue] = mapping.composeTag(
            for: CodingKeys.devices
        )

        self.dns = try? mapping.value(for: CodingKeys.dns).array(envs: envs)
        self.tags[CodingKeys.dns.stringValue] = mapping.composeTag(
            for: CodingKeys.dns
        )

        self.dns_opt = try? mapping.value(for: CodingKeys.dns_opt)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.dns_opt.stringValue] = mapping.composeTag(
            for: CodingKeys.dns_opt
        )

        self.dns_search = try? mapping.value(for: CodingKeys.dns_search).array(
            envs: envs
        )
        self.tags[CodingKeys.dns_search.stringValue] = mapping.composeTag(
            for: CodingKeys.dns_search
        )

        self.domainname = try? mapping.value(for: CodingKeys.domainname).string(
            envs: envs
        )
        self.tags[CodingKeys.domainname.stringValue] = mapping.composeTag(
            for: CodingKeys.domainname
        )

        // `expose` entries may be bare port numbers or quoted strings.
        self.expose = try? mapping.value(for: CodingKeys.expose)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.expose.stringValue] = mapping.composeTag(
            for: CodingKeys.expose
        )

        self.extends = try? Service.Extends(
            mapping.value(for: CodingKeys.extends),
            envs: envs
        )
        self.tags[CodingKeys.extends.stringValue] = mapping.composeTag(
            for: CodingKeys.extends
        )

        self.external_links = try? mapping.value(for: CodingKeys.external_links)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.external_links.stringValue] = mapping.composeTag(
            for: CodingKeys.external_links
        )

        self.gpus = try? Service.GPU(
            mapping.value(for: CodingKeys.gpus),
            envs: envs
        )
        self.tags[CodingKeys.gpus.stringValue] = mapping.composeTag(
            for: CodingKeys.gpus
        )

        self.group_add = try? mapping.value(for: CodingKeys.group_add)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.group_add.stringValue] = mapping.composeTag(
            for: CodingKeys.group_add
        )

        self.`init` = try? mapping.value(for: CodingKeys.`init`).bool(envs: envs)
        self.tags[CodingKeys.`init`.stringValue] = mapping.composeTag(
            for: CodingKeys.`init`
        )

        self.ipc = try? mapping.value(for: CodingKeys.ipc).string(envs: envs)
        self.tags[CodingKeys.ipc.stringValue] = mapping.composeTag(
            for: CodingKeys.ipc
        )

        self.isolation = try? mapping.value(for: CodingKeys.isolation).string(
            envs: envs
        )
        self.tags[CodingKeys.isolation.stringValue] = mapping.composeTag(
            for: CodingKeys.isolation
        )

        self.label_file = try? mapping.value(for: CodingKeys.label_file).array(
            envs: envs
        )
        self.tags[CodingKeys.label_file.stringValue] = mapping.composeTag(
            for: CodingKeys.label_file
        )

        self.links = try? mapping.value(for: CodingKeys.links)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.links.stringValue] = mapping.composeTag(
            for: CodingKeys.links
        )

        self.logging = try? Service.Logging(
            mapping.value(for: CodingKeys.logging),
            envs: envs
        )
        self.tags[CodingKeys.logging.stringValue] = mapping.composeTag(
            for: CodingKeys.logging
        )

        self.mac_address = try? mapping.value(for: CodingKeys.mac_address)
            .string(envs: envs)
        self.tags[CodingKeys.mac_address.stringValue] = mapping.composeTag(
            for: CodingKeys.mac_address
        )

        self.mem_reservation = try? mapping.value(
            for: CodingKeys.mem_reservation
        )
        .string(envs: envs)
        self.tags[CodingKeys.mem_reservation.stringValue] = mapping.composeTag(
            for: CodingKeys.mem_reservation
        )

        self.mem_swappiness = try? mapping.value(for: CodingKeys.mem_swappiness)
            .int(envs: envs)
        self.tags[CodingKeys.mem_swappiness.stringValue] = mapping.composeTag(
            for: CodingKeys.mem_swappiness
        )

        // `memswap_limit` accepts a string or a bare int.
        self.memswap_limit = try? mapping.value(for: CodingKeys.memswap_limit)
            .string(envs: envs)
        self.tags[CodingKeys.memswap_limit.stringValue] = mapping.composeTag(
            for: CodingKeys.memswap_limit
        )

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

        self.models = try? mapping.value(for: CodingKeys.models).dictionary(
            envs: envs,
            transformMap: { _, node in
                return try? Service.Model(
                    node,
                    envs: envs
                )
            },
            transformArray: { stringArray in
                return stringArray.toDictionary(
                    valueType: Model?.self,
                    makeValue: { _ in nil }
                )
            }
        )
        self.tags[CodingKeys.models.stringValue] = mapping.composeTag(
            for: CodingKeys.models
        )

        self.network_mode = try? mapping.value(for: CodingKeys.network_mode)
            .string(envs: envs)
        self.tags[CodingKeys.network_mode.stringValue] = mapping.composeTag(
            for: CodingKeys.network_mode
        )

        self.oom_kill_disable = try? mapping.value(
            for: CodingKeys.oom_kill_disable
        ).bool(envs: envs)
        self.tags[CodingKeys.oom_kill_disable.stringValue] = mapping.composeTag(
            for: CodingKeys.oom_kill_disable
        )

        self.oom_score_adj = try? mapping.value(for: CodingKeys.oom_score_adj)
            .int(envs: envs)
        self.tags[CodingKeys.oom_score_adj.stringValue] = mapping.composeTag(
            for: CodingKeys.oom_score_adj
        )

        self.pid = try? mapping.value(for: CodingKeys.pid).string(envs: envs)
        self.tags[CodingKeys.pid.stringValue] = mapping.composeTag(
            for: CodingKeys.pid
        )

        self.pids_limit = try? mapping.value(for: CodingKeys.pids_limit).int(
            envs: envs
        )
        self.tags[CodingKeys.pids_limit.stringValue] = mapping.composeTag(
            for: CodingKeys.pids_limit
        )

        self.post_start = try? mapping.value(for: CodingKeys.post_start)
            .array(of: Service.Hook.self, envs: envs)
        self.tags[CodingKeys.post_start.stringValue] = mapping.composeTag(
            for: CodingKeys.post_start
        )

        self.pre_stop = try? mapping.value(for: CodingKeys.pre_stop)
            .array(of: Service.Hook.self, envs: envs)
        self.tags[CodingKeys.pre_stop.stringValue] = mapping.composeTag(
            for: CodingKeys.pre_stop
        )

        self.provider = try? Service.Provider(
            mapping.value(for: CodingKeys.provider),
            envs: envs
        )
        self.tags[CodingKeys.provider.stringValue] = mapping.composeTag(
            for: CodingKeys.provider
        )

        self.pull_policy = try? mapping.value(for: CodingKeys.pull_policy)
            .string(envs: envs)
        self.tags[CodingKeys.pull_policy.stringValue] = mapping.composeTag(
            for: CodingKeys.pull_policy
        )

        self.runtime = try? mapping.value(for: CodingKeys.runtime).string(
            envs: envs
        )
        self.tags[CodingKeys.runtime.stringValue] = mapping.composeTag(
            for: CodingKeys.runtime
        )

        self.scale = try? mapping.value(for: CodingKeys.scale).int(envs: envs)
        self.tags[CodingKeys.scale.stringValue] = mapping.composeTag(
            for: CodingKeys.scale
        )

        self.security_opt = try? mapping.value(for: CodingKeys.security_opt)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.security_opt.stringValue] = mapping.composeTag(
            for: CodingKeys.security_opt
        )

        // `shm_size` accepts a string or a bare int.
        self.shm_size = try? mapping.value(for: CodingKeys.shm_size).string(
            envs: envs
        )
        self.tags[CodingKeys.shm_size.stringValue] = mapping.composeTag(
            for: CodingKeys.shm_size
        )

        self.stop_grace_period = try? mapping.value(
            for: CodingKeys.stop_grace_period
        ).string(envs: envs)
        self.tags[CodingKeys.stop_grace_period.stringValue] =
            mapping.composeTag(
                for: CodingKeys.stop_grace_period
            )

        self.stop_signal = try? mapping.value(for: CodingKeys.stop_signal)
            .string(envs: envs)
        self.tags[CodingKeys.stop_signal.stringValue] = mapping.composeTag(
            for: CodingKeys.stop_signal
        )

        self.storage_opt = try? mapping.value(for: CodingKeys.storage_opt)
            .dictionary(envs: envs)
        self.tags[CodingKeys.storage_opt.stringValue] = mapping.composeTag(
            for: CodingKeys.storage_opt
        )

        // `sysctls` accepts a map or a `key=value` list.
        self.sysctls = try? mapping.value(for: CodingKeys.sysctls).dictionary(
            envs: envs,
            isEnv: false
        )
        self.tags[CodingKeys.sysctls.stringValue] = mapping.composeTag(
            for: CodingKeys.sysctls
        )

        self.tmpfs = try? mapping.value(for: CodingKeys.tmpfs).array(envs: envs)
        self.tags[CodingKeys.tmpfs.stringValue] = mapping.composeTag(
            for: CodingKeys.tmpfs
        )

        // `ulimits` is a map of ulimit name -> Ulimit (int or {soft, hard}).
        self.ulimits = try? mapping.value(for: CodingKeys.ulimits).dictionary(
            envs: envs,
            transformMap: { key, value in
                return try Ulimit(value, envs: envs)
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
        self.tags[CodingKeys.ulimits.stringValue] = mapping.composeTag(
            for: CodingKeys.ulimits
        )

        self.use_api_socket = try? mapping.value(for: CodingKeys.use_api_socket)
            .bool(envs: envs)
        self.tags[CodingKeys.use_api_socket.stringValue] = mapping.composeTag(
            for: CodingKeys.use_api_socket
        )

        self.userns_mode = try? mapping.value(for: CodingKeys.userns_mode)
            .string(envs: envs)
        self.tags[CodingKeys.userns_mode.stringValue] = mapping.composeTag(
            for: CodingKeys.userns_mode
        )

        self.uts = try? mapping.value(for: CodingKeys.uts).string(envs: envs)
        self.tags[CodingKeys.uts.stringValue] = mapping.composeTag(
            for: CodingKeys.uts
        )

        self.volumes_from = try? mapping.value(for: CodingKeys.volumes_from)
            .array(of: String.self, envs: envs)
        self.tags[CodingKeys.volumes_from.stringValue] = mapping.composeTag(
            for: CodingKeys.volumes_from
        )
    }
}

extension Service {
    func resolvePathToAbsolute(projectDirectory: URL) -> Service {
        var resolved = self
        resolved.build = resolved.build?.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )
        resolved.volumes = resolved.volumes?.map({
            $0.resolvePathToAbsolute(projectDirectory: projectDirectory)
        })

        resolved.extends = resolved.extends?.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )
        resolved.credential_spec = resolved.credential_spec?
            .resolvePathToAbsolute(projectDirectory: projectDirectory)

        if let env_file = resolved.env_file {
            resolved.env_file = env_file.map({ entry in
                var resolved = entry
                resolved.path = resolved.path.absolutePath(
                    relativeTo: projectDirectory
                )
                return resolved
            })
        }

        if let label_file = resolved.label_file {
            resolved.label_file = label_file.map({ entry in
                return entry.absolutePath(relativeTo: projectDirectory)
            })
        }

        return resolved
    }
}
