//
//  OrderedDictionary.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/07.
//
//
//import Foundation
//import Playgrounds
//
//public struct Pair<Value: Codable>: Codable {
//    public var key: String
//    public var value: Value
//}
//
//public struct OrderedDictionary<Value: Codable>: Codable {
//    //    public var key: String
//    //    public var value: Value
//    public var pairs: [Pair<Value>] = []
//
//    struct DynamicCodingKey: CodingKey {
//        var stringValue: String
//        var intValue: Int? { nil }
//
//        init?(stringValue: String) {
//            self.stringValue = stringValue
//        }
//        init?(intValue: Int) { nil }
//    }
//
//    /// Creates a new dictionary by decoding from the given decoder.
//    ///
//    /// `OrderedDictionary` expects its contents to be encoded as alternating
//    /// key-value pairs in an unkeyed container.
//    ///
//    /// This initializer throws an error if reading from the decoder fails, or
//    /// if the decoded contents are not in the expected format.
//    ///
//    /// - Note: Unlike the standard `Dictionary` type, ordered dictionaries
//    ///    always encode themselves into an unkeyed container, because
//    ///    `Codable`'s keyed containers do not guarantee that they preserve the
//    ///    ordering of the items they contain. (And in popular encoding formats,
//    ///    keyed containers tend to map to unordered data structures -- e.g.,
//    ///    JSON's "object" construct is explicitly unordered.)
//    ///
//    /// - Parameter decoder: The decoder to read data from.
//    public init(from decoder: Decoder) throws {
//
//        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
//        let string: String
//        do {
//            let data = try decoder.singleValueContainer().decode(Data.self)
//            string = String(data: data, encoding: .utf8)!
//        } catch (let error) {
//            throw DecodingError.dataCorrupted(
//                .init(
//                    codingPath: [],
//                    debugDescription: "Given data is not valid JSON string.",
//                    underlyingError: error
//                )
//            )
//        }
//        print("string: ", string)
//        let orderedKeys: [String] = Utility.getJSONTopLevelKeysPreservingOrder(
//            string
//        )
//        print(
//            "orderedkeys: ",
//            orderedKeys,
//            "container key",
//            container.allKeys.count
//        )
//        guard orderedKeys.count == container.allKeys.count else {
//            throw DecodingError.dataCorrupted(
//                .init(
//                    codingPath: [],
//                    debugDescription: "Fail to extract ordered keys."
//                )
//            )
//
//        }
//        for key in orderedKeys {
//            let value = try container.decode(
//                String.self,
//                forKey: DynamicCodingKey(stringValue: key)!
//            )
//            print(value)
//        }
//
//    }
//
//}
//extension CodingUserInfoKey {
//    static let originalString = CodingUserInfoKey(rawValue: "orignalString")!
//}
//
//
//struct DynamicCodingKey: CodingKey {
//    var stringValue: String
//    var intValue: Int? { nil }
//
//    init?(stringValue: String) {
//        self.stringValue = stringValue
//    }
//    init?(intValue: Int) { nil }
//}
//
////extension KeyedDecodingContainer {
////    public func decode<Value: Decodable>(
////        _ type: OrderedDictionary<String, Value>.Type,
////        forKey key: KeyedDecodingContainer<K>.Key,
////    ) throws -> OrderedDictionary<String, Value> {
////        print("here for key: ", key.stringValue)
////        let container = try self.nestedContainer(
////            keyedBy: DynamicCodingKey.self,
////            forKey: key
////        )
////        var keyedValues = OrderedDictionary<String, Value>()
////        for key in container.allKeys {
////            let decodedValue = try container.decode(Value.self, forKey: key)
////            keyedValues[key.stringValue] = decodedValue
////        }
////        return keyedValues
////    }
////
////    public func decode(
////        _ type: OrderedDictionary<String, String>.Type,
////        forKey key: KeyedDecodingContainer<K>.Key,
////        envs: [String: String]
////    ) throws -> OrderedDictionary<String, String> {
////        let container = try self.nestedContainer(
////            keyedBy: DynamicCodingKey.self,
////            forKey: key
////        )
////        var keyedValues = OrderedDictionary<String, String>()
////        for key in container.allKeys {
////            let decodedValue = try container.decode(
////                String.self,
////                forKey: key,
////                envs: envs
////            )
////            keyedValues[key.stringValue] = decodedValue
////        }
////        return keyedValues
////    }
////}
//
//#Playground {
//    let jsonString = """
//        {
//            "zebra": 2,
//            "apple": 2,
//            "monkey": 3
//        }
//        """
//    let jsonData = jsonString.data(using: .utf8)!
//
//    //    print(getTopLevelKeysPreservingOrder(from: jsonString))
//
//        do {
//            // Decode into our wrapper instead of a normal dictionary
////            let decoder = JSONDecoder()
////            let result = try decoder.decode(
////                OrderedDictionary<Int>.self,
////                from: jsonData,
////                userInfo: [.orignalString: jsonString]
////            )
////            decoder.de
////            print(result)
//    
//            // Print to verify order is preserved
//    //        for pair in result {
//    //            print("\(pair)")
//    //        }
//        } catch {
//            print("Decoding error: \(error)")
//        }
//
//}
//
//extension Utility {
//   public static func getJSONTopLevelKeysPreservingOrder(_ jsonString: String)
//        -> [String]
//    {
//        let scanner = Scanner(string: jsonString)
//        scanner.charactersToBeSkipped = .whitespacesAndNewlines
//
//        var keys: [String] = []
//        var depth = 0
//        var expectingKey = true  // true right after `{` or `,` at depth 1
//
//        // Reads a quoted string starting at the current position, handling escapes.
//        func readStringLiteral() -> String {
//            _ = scanner.scanString("\"")
//            var result = ""
//            while true {
//                if let chunk = scanner.scanUpToCharacters(
//                    from: CharacterSet(charactersIn: "\"\\")
//                ) {
//                    result += chunk
//                }
//                if scanner.scanString("\\") != nil {
//                    if let escaped = scanner.scanCharacter() {
//                        result.append("\\")
//                        result.append(escaped)
//                    }
//                    continue
//                }
//                if scanner.scanString("\"") != nil { break }
//                if scanner.isAtEnd { break }
//            }
//            return result
//        }
//
//        // Skips a quoted string without capturing it.
//        func skipStringLiteral() {
//            _ = readStringLiteral()
//        }
//
//        // Move past the initial structural opening brace
//        _ = scanner.scanUpToString("{")
//        guard scanner.scanString("{") != nil else { return [] }
//        depth = 1
//
//        while !scanner.isAtEnd && depth > 0 {
//            let savedIndex = scanner.currentIndex
//            guard let c = scanner.scanCharacter() else { break }
//
//            switch c {
//            case "\"":
//                scanner.currentIndex = savedIndex
//                if depth == 1 && expectingKey {
//                    let key = readStringLiteral()
//                    keys.append(key)
//                    expectingKey = false
//                    // consume the colon separating key and value
//                    _ = scanner.scanUpToString(":")
//                    _ = scanner.scanString(":")
//                } else {
//                    skipStringLiteral()
//                }
//            case "{", "[":
//                depth += 1
//            case "}", "]":
//                depth -= 1
//            case ",":
//                if depth == 1 { expectingKey = true }
//            default:
//                break
//            }
//        }
//
//        return keys
//    }
//
//}
