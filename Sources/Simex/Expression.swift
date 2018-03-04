//
//  Expression.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

/// Represents an instance of `Expression`.
public struct Expression {
    /// The additional key for hooking a collection of user-defined
    /// processors to the `Expression`.
    public static let processorsKey = CodingUserInfoKey(rawValue: "processors")!

    fileprivate let root: Slice
}

extension Expression: Codable {
    internal enum CodingKeys: String, CodingKey {
        case root
    }

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws `Expression.Error`: If the provided expression definition is invalid.
    public init(from decoder: Decoder) throws {
        // The container must be a dictionary.
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            throw Expression.Error(.expression, at: "")
        }

        // Gets the required `root`.
        if container.contains(.root) {
            root = try container.decode(Slice.self, forKey: .root)
        }
        else {
            throw Expression.Error(.rootMissing, at: "")
        }
    }

    /// Encodes this value into the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Sets the required `root`.
        try container.encode(root, forKey: .root)
    }
}

extension Expression {
    /// Returns the extraction result from input string.
    ///
    /// - Parameter input: An input string to extract content from.
    /// - Returns: An `Expression.Result`.
    /// - Throws `Expression.Error`: If the input does not comply to the expression.
    public func extract(_ input: String) throws -> Result {
        let bytes = input.toBytes()
        return try self.root.extract(bytes[bytes.startIndex...])
    }
}

extension Expression {
    internal static func path(of codingKeys: [CodingKey]) -> String {
        var path = ""
        for key in codingKeys {
            if let index = key.intValue {
                path += "[\(index)]"
            }
            else if key is Expression.Dictionary.CodingKeys {
                path += "[\"\(key.stringValue)\"]"
            }
            else {
                if !path.isEmpty {
                    path += "."
                }
                path += key.stringValue
            }
        }
        return path
    }
}
