//
//  Dict+Extensions.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

import Foundation

extension Dictionary where Key == String {
    // remove keys in the base dict that is container in the dict
    func removeDuplicateKeys(in dict: Self) -> Self {
        return self.filter({ v in
            dict.contains(where: { $0.key == v.key }) == false
        })
    }

    func keepDuplicateKeys(in dict: Self) -> Self {
        return self.filter({ v in
            dict.contains(where: { $0.key == v.key })
        })
    }
}
