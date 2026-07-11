//
//  ComposeTag.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

public enum ComposeTag: String, Codable, Hashable {
    case override = "!override"
    case reset = "!reset"
}
