//
//  Expression.Between.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    internal struct Between {
        fileprivate let path: String

        fileprivate let backward: Bool?
        fileprivate let prefix: [Bytes]?
        fileprivate let suffix: [Bytes]?
        fileprivate let trim: Bool?

        fileprivate let prefixIsArray: Bool
        fileprivate let suffixIsArray: Bool
    }
}

extension Expression.Between: Codable {
    internal enum CodingKeys: String, CodingKey {
        case backward
        case prefix
        case suffix
        case trim
    }

    internal init(from decoder: Decoder) throws {
        path = Expression.path(of: decoder.codingPath)

        // The container must be a dictionary.
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            throw Expression.Error(.between, at: path)
        }

        // Gets the optional `backward`.
        if container.contains(.backward) {
            guard let value = try? container.decode(Bool.self, forKey: .backward) else {
                throw Expression.Error(.backward, at: path + ".backward")
            }
            backward = value
        }
        else {
            backward = nil
        }

        // Gets the optional `prefix`
        if container.contains(.prefix) {
            if let array = try? container.decode([String].self, forKey: .prefix) {
                prefix = array.map { $0.toBytes() }
                prefixIsArray = true
            }
            else if let value = try? container.decode(String.self, forKey: .prefix) {
                prefix = [value.toBytes()]
                prefixIsArray = false
            }
            else {
                throw Expression.Error(.prefix, at: path + ".prefix")
            }
        }
        else {
            prefix = nil
            prefixIsArray = false
        }

        // Gets the optional `suffix`
        if container.contains(.suffix) {
            if let array = try? container.decode([String].self, forKey: .suffix) {
                suffix = array.map { $0.toBytes() }
                suffixIsArray = true
            }
            else if let value = try? container.decode(String.self, forKey: .suffix) {
                suffix = [value.toBytes()]
                suffixIsArray = false
            }
            else {
                throw Expression.Error(.suffix, at: path + ".suffix")
            }
        }
        else {
            suffix = nil
            suffixIsArray = false
        }

        // Gets the optional `trim`.
        if container.contains(.trim) {
            guard let value = try? container.decode(Bool.self, forKey: .trim) else {
                throw Expression.Error(.trim, at: path + ".trim")
            }
            trim = value
        }
        else {
            trim = nil
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Sets the optional `backward`.
        try container.encodeIfPresent(backward, forKey: .backward)

        // Sets the optional `prefix` as an array of or a single string.
        if self.prefixIsArray {
            try container.encodeIfPresent(prefix?.map({ $0.toString() }), forKey: .prefix)
        }
        else {
            try container.encodeIfPresent(prefix?[0].toString(), forKey: .prefix)
        }

        // Sets the optional `suffix` as an array of or a single string.
        if self.suffixIsArray {
            try container.encodeIfPresent(suffix?.map({ $0.toString() }), forKey: .suffix)
        }
        else {
            try container.encodeIfPresent(suffix?[0].toString(), forKey: .suffix)
        }

        // Sets the optional `trim`.
        try container.encodeIfPresent(trim, forKey: .trim)
    }
}

extension Expression.Between {
    internal func extract(_ input: ArraySlice<UInt8>) throws -> ArraySlice<UInt8> {
        let backward = self.backward ?? false
        var bytes = input

        // prefix
        if let prefixes = self.prefix, prefixes.count > 0 {
            for (index, prefix) in prefixes.enumerated() where prefix.count > 0 {
                if backward {
                    guard let end = bytes.lastIndex(of: prefix) else {
                        let location = path + ".prefix" + (self.prefixIsArray ? "[\(index)]" : "")
                        throw Expression.Error(.inputUnmatched, at: location)
                    }
                    bytes = bytes[bytes.startIndex ..< end]
                }
                else {
                    guard let start = bytes.index(of: prefix) else {
                        let location = path + ".prefix" + (self.prefixIsArray ? "[\(index)]" : "")
                        throw Expression.Error(.inputUnmatched, at: location)
                    }
                    bytes = bytes[(start + prefix.count)...]
                }
            }
        }

        // suffix
        var suffixed = false
        var suffixesCount = 0
        if let suffixes = self.suffix, suffixes.count > 0 {
            for suffix in suffixes {
                suffixesCount += 1
                if suffix.count > 0 {
                    if backward {
                        if let start = bytes.lastIndex(of: suffix) {
                            bytes = bytes[(start + suffix.count)...]
                            suffixed = true
                            break
                        }
                    }
                    else {
                        if let end = bytes.index(of: suffix) {
                            bytes = bytes[bytes.startIndex ..< end]
                            suffixed = true
                            break
                        }
                    }
                }
                else {
                    suffixed = true
                    break
                }
            }
            if !suffixed && suffixesCount > 0 {
                throw Expression.Error(.inputUnmatched, at: path + ".suffix")
            }
        }

        // trim
        if let trim = self.trim, trim == true {
            var startIndex = bytes.startIndex
            for byte in bytes {
                if byte == 0x20 || (0x09 <= byte && byte <= 0x0D) {
                    startIndex += 1
                }
                else {
                    break
                }
            }
            bytes = bytes[startIndex...]

            var endIndex = bytes.endIndex
            for byte in bytes.reversed() {
                if byte == 0x20 || (0x09 <= byte && byte <= 0x0D) {
                    endIndex -= 1
                }
                else {
                    break
                }
            }
            bytes = bytes[startIndex ..< endIndex]
        }

        return bytes
    }
}
