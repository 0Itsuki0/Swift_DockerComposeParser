//
//  Model.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/06.
//

/// Long-syntax options for a model referenced by a service's `models` attribute.
/// The referenced model itself is declared in the top-level `models` element;
/// this only carries the per-service overrides.
extension Service {
    public struct Model: Codable, Hashable {
        /// Name of the environment variable Compose injects with the model
        /// runner's connection URL (defaults to `<MODEL_NAME>_URL` when omitted).
        public var endpoint_var: String?
        
        public var tags: [String: ComposeTag?] = [:]

        public init(endpoint_var: String? = nil) {
            self.endpoint_var = endpoint_var
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.endpoint_var = try container.decodeIfPresent(
                String.self,
                forKey: .endpoint_var
            )
        }
    }
}


import Yams
extension Service.Model: NodeConvertible {

    public init(_ node: Node, envs: [String: String]) throws {
        guard let mapping = node.mapping else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Invalid yaml data. Expected a mapping."
                )
            )
        }

        self.endpoint_var = try? mapping.value(for: CodingKeys.endpoint_var)
            .string(envs: envs)
    }
}
