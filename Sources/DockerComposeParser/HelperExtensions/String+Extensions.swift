//
//  String+Extensions.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Foundation

extension String {
    func absolutePath(relativeTo: URL) -> String {
        // to handle the case where the relativeTo is missing the trailing slash and the URL(filePath:) will treat it as a file instead of directory
        let baseDirectory =
            relativeTo.hasDirectoryPath
            ? relativeTo
            : relativeTo.standardizedFileURL
                .appendingPathComponent("", isDirectory: true)
        return URL(filePath: self, relativeTo: baseDirectory).path()
    }
}
