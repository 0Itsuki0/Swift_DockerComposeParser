//
//  NodeConvertible.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/08.
//

import Yams

public protocol NodeConvertible {
    init(_ node: Node, envs: [String: String]) throws
}
