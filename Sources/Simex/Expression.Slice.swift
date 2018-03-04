//
//  Expression.Slice.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

internal protocol Subexpression {
    func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result
}

extension Expression {
    internal struct Slice {
        fileprivate let path: String

        fileprivate let has: Bytes?
        fileprivate let between: [Expression.Between]?
        fileprivate let process: [Expression.Process]?
        fileprivate let value: Result?
        fileprivate let slice: [Subexpression]?
        fileprivate let array: Subexpression?
        fileprivate let dictionary: Subexpression?

        fileprivate let betweenIsArray: Bool
        fileprivate let processIsArray: Bool
        fileprivate let sliceIsArray: Bool
    }
}

extension Expression.Slice: Codable {
    internal enum CodingKeys: String, CodingKey {
        case has
        case between
        case process
        case value
        case slice
        case array
        case dictionary
    }

    // swiftlint:disable:next function_body_length
    internal init(from decoder: Decoder) throws {
        path = Expression.path(of: decoder.codingPath)

        let sliceErrorType: Expression.ErrorType = {
            let codingPath = decoder.codingPath
            let lastKey = decoder.codingPath.last
            if let codingKey = lastKey as? Expression.CodingKeys {
                if codingKey == .root {
                    return .root
                }
            }
            else if lastKey is Expression.Array.CodingKeys {
                return .item
            }
            else if lastKey is Expression.Dictionary.CodingKeys {
                return .member
            }
            else if nil !=  lastKey?.intValue, codingPath.count >= 2 {
                let priorKey = codingPath[codingPath.count - 2]
                if priorKey is Expression.Array.CodingKeys {
                    return .item
                }
                else if priorKey is Expression.Dictionary.CodingKeys {
                    return .member
                }
            }
            return .slice
        }()

        // The container must be a dictionary.
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            throw Expression.Error(sliceErrorType, at: path)
        }

        // Gets the optional `has`.
        if container.contains(.has) {
            guard let value = try? container.decode(String.self, forKey: .has) else {
                throw Expression.Error(.has, at: path + ".has")
            }
            has = value.toBytes()
        }
        else {
            has = nil
        }

        // Gets the optional `between`
        if container.contains(.between) {
            if (try? container.decodeNil(forKey: .between)) == true {
                throw Expression.Error(.between, at: path + ".between")
            }
            do {
                let array = try container.decode([Expression.Between].self, forKey: .between)
                between = array
                betweenIsArray = true
            }
            catch DecodingError.typeMismatch {
                between = [try container.decode(Expression.Between.self, forKey: .between)]
                betweenIsArray = false
            }
        }
        else {
            between = nil
            betweenIsArray = false
        }

        // Gets the optional `process`
        if container.contains(.process) {
            if (try? container.decodeNil(forKey: .process)) == true {
                throw Expression.Error(.process, at: path + ".process")
            }
            do {
                let array = try container.decode([Expression.Process].self, forKey: .process)
                process = array
                processIsArray = true
            }
            catch DecodingError.typeMismatch {
                process = [try container.decode(Expression.Process.self, forKey: .process)]
                processIsArray = false
            }
        }
        else {
            process = nil
            processIsArray = false
        }

        // Gets the optional one of `value`, `slice`, `array`, `dictionary`.
        if container.contains(.value) {
            guard !container.contains(.slice)
            && !container.contains(.array)
            && !container.contains(.dictionary) else {
                throw Expression.Error(.subexpressions, at: path)
            }

            value = try container.decode(Expression.Result.self, forKey: .value)

            slice = nil
            sliceIsArray = false
            array = nil
            dictionary = nil
        }
        else if container.contains(.slice) {
            guard !container.contains(.array)
            && !container.contains(.dictionary) else {
                throw Expression.Error(.subexpressions, at: path)
            }
            if (try? container.decodeNil(forKey: .slice)) == true {
                throw Expression.Error(.slice, at: path + ".slice")
            }
            do {
                let array = try container.decode([Expression.Slice].self, forKey: .slice)
                if array.isEmpty {
                    throw Expression.Error(.slice, at: path + ".slice")
                }
                slice = array
                sliceIsArray = true
            }
            catch DecodingError.typeMismatch {
                slice = [try container.decode(Expression.Slice.self, forKey: .slice)]
                sliceIsArray = false
            }

            value = nil
            array = nil
            dictionary = nil
        }
        else if container.contains(.array) {
            guard !container.contains(.dictionary) else {
                throw Expression.Error(.subexpressions, at: path)
            }
            if (try? container.decodeNil(forKey: .array)) == true {
                throw Expression.Error(.array, at: path + ".array")
            }
            array = try container.decode(Expression.Array.self, forKey: .array)

            value = nil
            slice = nil
            sliceIsArray = false
            dictionary = nil
        }
        else if container.contains(.dictionary) {
            if (try? container.decodeNil(forKey: .dictionary)) == true {
                throw Expression.Error(.dictionary, at: path + ".dictionary")
            }
            dictionary = try container.decode(Expression.Dictionary.self, forKey: .dictionary)

            value = nil
            slice = nil
            sliceIsArray = false
            array = nil
        }
        else {
            value = nil
            slice = nil
            sliceIsArray = false
            array = nil
            dictionary = nil
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Sets the optional `has`.
        try container.encodeIfPresent(has?.toString(), forKey: .has)

        // Sets the optional `between`.
        if betweenIsArray {
            try container.encodeIfPresent(between, forKey: .between)
        }
        else {
            try container.encodeIfPresent(between?[0], forKey: .between)
        }

        // Sets the optional `process`.
        if processIsArray {
            try container.encodeIfPresent(process, forKey: .process)
        }
        else {
            try container.encodeIfPresent(process?[0], forKey: .process)
        }

        // Sets the optional `value`.
        try container.encodeIfPresent(value, forKey: .value)

        // Sets the optional `slice`.
        if sliceIsArray {
            try container.encodeIfPresent(slice as? [Expression.Slice], forKey: .slice)
        }
        else {
            try container.encodeIfPresent(slice?[0] as? Expression.Slice, forKey: .slice)
        }

        // Sets the optional `array`.
        try container.encodeIfPresent(array as? Expression.Array, forKey: .array)

        // Sets the optional `dictionary`.
        try container.encodeIfPresent(dictionary as? Expression.Dictionary, forKey: .dictionary)
    }
}

extension Expression.Slice: Subexpression {
    internal func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result {
        if let has = self.has, has.count > 0 {
            guard input.index(of: has) != nil else {
                throw Expression.Error(.inputUnmatched, at: path + ".has")
            }
        }

        var bytes = input
        if let between = self.between {
            for item in between {
                bytes = try item.extract(bytes)
            }
        }

        if let process = self.process {
            for item in process {
                bytes = try item.extract(bytes)
            }
        }

        if let value = self.value {
            return value
        }
        else if let slices = self.slice {
            var errors = [Expression.Error]()
            for slice in slices {
                do {
                    return try slice.extract(bytes)
                }
                catch let error as Expression.Error {
                    errors.append(error)
                }
            }

            // Should have errors since this.slice is not empty.
            // Don't check errors.length, to let it throw exception,
            // if there are mistakes in code.
            if sliceIsArray {
                let location = errors.map { $0.at }.joined(separator: "\n")
                throw Expression.Error(.inputUnmatched, at: location)
            }
            else {
                throw errors[0]
            }
        }
        else if let array = self.array {
            return try array.extract(bytes)
        }
        else if let dictionary = self.dictionary {
            return try dictionary.extract(bytes)
        }

        return Expression.Result.string(bytes.toString())
    }
}
