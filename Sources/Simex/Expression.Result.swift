//
//  Expression.Result.swift
// Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    /// Represents the result from extraction by `Expression`.
    public enum Result {
        // Denotes a null
        case null

        // Denotes a boolean value.
        case bool(Bool)

        // Denotes an integer value.
        case int(Int)

        // Denotes a floating point number value.
        case number(Double)

        // Denotes a single string value.
        case string(String)

        // Denotes a containers holding a list of `Result` in ordered sequence.
        case array([Result])

        // Denotes a container holding a list of `Result` by theirs unique labels.
        case dictionary([String: Result])
    }
}

extension Expression.Result {
    /// Returns true if the `Result` is `Result.null`.
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    /// Returns a Bool value if the `Result` is `Result.bool`.
    public var bool: Bool? {
        if case .bool(let bool) = self {
            return bool
        }
        return nil
    }

    /// Returns a Int value if the `Result` is `Result.int`.
    public var int: Int? {
        if case .int(let int) = self {
            return int
        }
        return nil
    }

    /// Returns a Double value if the `Result` is `Result.int` or `Result.number`.
    public var number: Double? {
        if case .number(let number) = self {
            return number
        }
        else if case .int(let int) = self {
            return Double(int)
        }
        return nil
    }

    /// Returns a single string value if the `Result` is `Result.string`.
    public var string: String? {
        if case .string(let string) = self {
            return string
        }
        return nil
    }

    /// Returns an array of `Result` if the `Result` is `Result.array`.
    public var array: [Expression.Result]? {
        if case .array(let array) = self {
            return array
        }
        return nil
    }

    /// Returns an array of `Result` if the `Result` is `Result.dictionary`.
    public var dictionary: [String: Expression.Result]? {
        if case .dictionary(let dictionary) = self {
            return dictionary
        }
        return nil
    }

    /// Returns a `Result` element at a given index if the `Result` is an `Result.array`.
    ///
    /// - Parameter index: The position of the element to access. `index` must be
    ///   greater than or equal to 0 and less than the number of elements in the array.
    ///
    /// - Returns: If the `Result` is an array and the given `index` is within the range, then
    ///   returns the `Result` element at the given `index`, otherwise retuns `nil`.
    public subscript(index: Int) -> Expression.Result? {
        if index >= 0 {
            if let array = self.array, array.count > index {
                return array[index]
            }
        }
        return nil
    }

    /// Returns a `Result` value at a given key if the `Result` is a `Result.dictionary`.
    ///
    /// - Parameter key: The key of the value to access. `key` must exist in the dictionary.
    ///
    /// - Returns: If the `Result` is a dictionary and the given `key` exits, then
    ///   returns the `Result` value at the given `key`, otherwise retuns nil.
    public subscript(key: String) -> Expression.Result? {
        if let dictionary = self.dictionary {
            if let value = dictionary[key] {
                return value
            }
        }
        return nil
    }
}

extension Expression.Result: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        }
        else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        }
        else if let int = try? container.decode(Int.self) {
            self = .int(int)
        }
        else if let number = try? container.decode(Double.self) {
            self = .number(number)
        }
        else if let string = try? container.decode(String.self) {
            self = .string(string)
        }
        else if let array = try? container.decode([Expression.Result].self) {
            self = .array(array)
        }
        else {
            let dictionary = try container.decode([String: Expression.Result].self)
            self = .dictionary(dictionary)
        }
    }

    /// Encodes this value into the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case .int(let int):
            var container = encoder.singleValueContainer()
            try container.encode(int)
        case .number(let number):
            var container = encoder.singleValueContainer()
            try container.encode(number)
        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        case .array(let array):
            try array.encode(to: encoder)
        case .dictionary(let dictionary):
            try dictionary.encode(to: encoder)
        }
    }
}
