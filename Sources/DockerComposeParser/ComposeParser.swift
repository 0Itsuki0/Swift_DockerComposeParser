//
//  ComposeParser.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//
import Foundation

// MARK: - ComposeParser
// Functions for loading composes including resolving any includes/extends
public enum ComposeParser {

    /// Main Entry for loading multiple composes files (similar to the -f option of the compose command)
    ///
    /// Argument:
    ///  - composeURL: base compose to be loaded
    ///  - otherComposes: an array of additional compose files.
    ///     - The order of the array will be the order that resource override/merging happens.
    ///     - all relative path within the composes will be resolved based on the projectDirectory
    ///  - envFiles: files containing environment variables to resolve ${VAR} within the yaml (not attached to image / container, and etc.)
    ///     If not set, falling back to the `.env` file contained within the project directory
    ///  - projectDirectory: project directory  to be used to resolve relative paths for **all** composes
    ///     if not set, falling back to the directory containing the base compose.
    ///
    /// Returning:
    /// - A compose with everything resolved
    static public func loadComposes(
        _ composeURL: URL,
        otherComposes: [URL] = [],
        envFiles: [URL] = [],
        projectDirectory: URL?
    ) throws -> DockerCompose {
        let projectDirectory =
            projectDirectory ?? composeURL.deletingLastPathComponent()

        let resolvedEnvs = try Utility.loadProjectEnvFiles(
            envFiles,
            projectDirectory: projectDirectory
        )

        var baseCompose = try loadCompose(
            composeURL,
            envs: resolvedEnvs,
            projectDirectory: projectDirectory,
            validateDependency: false
        )

        let additionalComposes = try otherComposes.map({
            try loadCompose(
                $0,
                envs: resolvedEnvs,
                projectDirectory: projectDirectory,
                // set validation to false here because, for example,
                // if docker-compose.override.yml has a service with depends_on: web,
                // but web is only defined in the base docker-compose.yml,
                // loading the override file alone will fail validateDependency()
                // even though the combined multi-file setup is completely valid Compose.
                validateDependency: false
            )
        })

        // different from includes, later ones override early ones
        for includedCompose in additionalComposes {
            baseCompose = try baseCompose.deepMerge(with: includedCompose)
        }

        try baseCompose.validateDependency()

        return baseCompose
    }

    /// Main Entry for loading single composes file
    ///
    /// Argument:
    ///  - composeURL: base compose to be loaded
    ///  - envFiles: files containing environment variables to resolve ${VAR} within the yaml (not attached to image / container, and etc.)
    ///     If not set, falling back to the `.env` file contained within the project directory
    ///  - projectDirectory: project directory  to be used to resolve relative paths for the base composes
    ///     if not set, falling back to the directory containing the base compose.
    ///
    /// Returning:
    /// - A compose with everything resolved
    static public func loadCompose(
        _ composeURL: URL,
        envFiles: [URL],
        projectDirectory: URL?,
    ) throws -> DockerCompose {
        let projectDirectory =
            projectDirectory ?? composeURL.deletingLastPathComponent()
        let resolvedEnvs = try Utility.loadProjectEnvFiles(
            envFiles,
            projectDirectory: projectDirectory
        )

        return try loadCompose(
            composeURL,
            envs: resolvedEnvs,
            projectDirectory: projectDirectory,
            validateDependency: true
        )
    }

    /// Load a single compose.
    ///
    /// 1. load the base compose
    /// 2. resolve for relative path in the base compose
    /// 3. load the includes
    /// 4. apply overrides specified in the base compose if there is any to the includes
    /// 5. load the extended services
    ///
    /// Argument:
    ///  - composeURL: base compose to be loaded
    ///  - envs: environment variables to resolve ${VAR} within the yaml (not attached to image / container, and etc.)
    ///  - projectDirectory: project directory  to be used to resolve relative paths within the base compose
    ///  - validateDependency: whether to validate service `depend_on` or not.
    ///     when loading multiple compose at once (similar to the -f in compose CLI), set this to false and validate after loading and merging all files
    ///
    /// Returning:
    /// - A compose with everything resolved
    static func loadCompose(
        _ composeURL: URL,
        envs: [String: String],
        projectDirectory: URL,
        validateDependency: Bool
    ) throws -> DockerCompose {
        guard composeURL.isFileURL else {
            throw ComposeError.invalidURL("Compose URL is not a file URL.")
        }

        guard FileManager.default.fileExists(atPath: composeURL.path()) else {
            throw ComposeError.invalidURL(
                "Compose does not exist at the specified path."
            )
        }

        var baseCompose = try DockerCompose.init(url: composeURL, envs: envs)

        // 1. resolve relative path (service, config, include, secret
        baseCompose = baseCompose.resolvePathToAbsolute(
            projectDirectory: projectDirectory
        )

        // 2. load include
        let includedComposes = try baseCompose.loadIncludes(mainEnvs: envs)
        baseCompose.include = nil

        // 3. check if all resources declared within the included compose are unique
        // because there isn't a main/sub between them and we cannot say override one with anther
        try Utility.checkIncludeUniqueness(includedComposes)

        var resolvedIncludes: [DockerCompose] = []
        for includedCompose in includedComposes {
            // 4. filter main for service, volumes, networks, and etc to only include those defined within the included compose
            let overrideCompose = createOverrideCompose(
                base: includedCompose,
                overrideCompose: baseCompose
            )
            // 5. apply any override to the included compose declared within the base compose
            let merged = try includedCompose.deepMerge(with: overrideCompose)
            resolvedIncludes.append(merged)
            // 6. remove those resources from the base compose
            baseCompose = baseCompose.removeResources(containedIn: merged)
        }

        // 7. merge together the base and the resolved includes
        // NOTE: not using deep merging here to avoid unnecessary looping as we already knew that the base and includes should not have the duplicate key (name) for the resources
        var finalCompose = baseCompose
        for resolvedInclude in resolvedIncludes {
            finalCompose = finalCompose.simpleMerge(with: resolvedInclude)
        }

        // 7. resolve extended service
        finalCompose =
            try finalCompose
            .resolveServiceExtends(resolveInFile: { name, url in
                let loadedServices: [String: Service?] =
                    (try loadCompose(
                        url,
                        envs: envs,
                        projectDirectory: projectDirectory,
                        validateDependency: true
                    )).services

                guard let optional = loadedServices[name],
                    let service = optional
                else {
                    throw ComposeError.invalidExtends(
                        "Service: \(name) not found."
                    )
                }
                return service
            })

        // 8. validate all service depending on are included
        if validateDependency {
            try finalCompose.validateDependency()
        }

        return finalCompose
    }
}
