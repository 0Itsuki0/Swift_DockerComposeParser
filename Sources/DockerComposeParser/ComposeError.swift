//
//  ComposeError.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Foundation

enum ComposeError: Error, LocalizedError {
    case invalidURL(String?)
    case dependencyNotFound(required: [String], warning: [String])
    case envFailToResolve(String?)
    case mergeError(String?)
    case fileNotFound
    case invalidFileData
    case invalidInclude(String?)
    case invalidExtends(String?)
    case failToResolveVar(String?)
    case failToResolveProjectURL

    var errorDescription: String? {
        switch self {
        case .dependencyNotFound(let required, let warning):
            if required.isEmpty {
                return
                    "Following Dependencies are included but not found: \(warning.joined(separator: ", "))."
            }
            if warning.isEmpty {
                return
                    "Following Dependencies are required but not found: \(required.joined(separator: ", "))."
            }

            return
                "Following Dependencies are not found. Required: \(required.joined(separator: ", ")). Included but not required: \(warning.joined(separator: ", "))."
        case .invalidURL(let message):
            return "Invalid Compose URL. \(message ?? "")"
        case .failToResolveProjectURL:
            return "Fail to resolve project url for the included compose file."
        case .envFailToResolve(let message):
            return "Environment variables cannot be resolved. \(message ?? "")"
        case .mergeError(let message):
            return "Error merging composes. \(message ?? "")"
        case .fileNotFound:
            return "Compose file not found"
        case .invalidExtends(let message):
            return "Invalid extends attributes in service. \(message ?? "")"
        case .invalidFileData:
            return "Invalid compose file data"
        case .invalidInclude(let message):
            return "Invalid includes attributes. \(message ?? "")"
        case .failToResolveVar(let message):
            return "Fail to resolve variable. \(message ?? "")"
        }
    }
}
