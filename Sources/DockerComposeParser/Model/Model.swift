//
//  Model.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Represents a single entry in the top-level `models` element. Declares an
/// AI model (pulled as an OCI artifact and served by a model runner) that
/// services can reference through their own `models` attribute.
///
/// ```yaml
/// models:
///   ai_model:
///     model: ai/model
///     context_size: 1024
///     runtime_flags:
///       - "--a-flag"
/// ```
public struct Model: Codable, Hashable {
    /// The OCI artifact identifier for the model. This is what Compose pulls
    /// and runs via the model runner.
    public var model: String

    /// The maximum token context size for the model.
    public var context_size: Int?

    /// Raw command-line flags passed to the inference engine when the model is started.
    public var runtime_flags: [String]?
    
    public var tags: [String: ComposeTag?] = [:]


    public init(
        model: String,
        context_size: Int? = nil,
        runtime_flags: [String]? = nil
    ) {
        self.model = model
        self.context_size = context_size
        self.runtime_flags = runtime_flags
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.model = try container.decode(String.self, forKey: .model)
        self.context_size = try container.decodeIfPresent(Int.self, forKey: .context_size)
        self.runtime_flags = try container.decodeIfPresent([String].self, forKey: .runtime_flags)
    }
}

import Yams
extension Model: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        // `try?` acts as decodeIfPresent
        guard let model = try mapping.value(for: CodingKeys.model).string(envs: envs) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. model is required."
                )
            )
        }
        self.model = model
        self.context_size = try? mapping.value(for: CodingKeys.context_size).int(envs: envs)
        self.runtime_flags = try? mapping.value(for: CodingKeys.runtime_flags).array(of: String.self , envs: envs)
    }
}
