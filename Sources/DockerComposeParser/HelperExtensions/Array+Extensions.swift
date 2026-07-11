//
//  Array+Extensions.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Foundation

extension Array {
    func toDictionary<T>(
        valueType: T.Type = T.self,
        makeValue: @escaping (Element) -> T
    )
        -> [Element: T]
    {
        Dictionary(uniqueKeysWithValues: self.map { ($0, makeValue($0)) })
    }
}

extension Array where Element == [String: Any] {
    var allKeyUnique: Bool {
        let keys = self.flatMap(\.keys)
        return Set(keys).count == keys.count
    }
}
