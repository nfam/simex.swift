//
//  Bytes.swift
//  Simex
//
//  Created by Ninh on 11/02/2016.
//  Copyright © 2016 Ninh. All rights reserved.
//

fileprivate typealias Bytes = [UInt8]

extension String {
    /// UTF8 Array representation of string
    fileprivate func toBytes() -> Bytes {
        return Array(utf8)
    }
}

extension Sequence where Iterator.Element == UInt8 {
    /// Converts a slice of bytes to string.
    fileprivate func toString() -> String {
        let array = Array(self) + [0]
        return array.withUnsafeBufferPointer { buffer in
            let pointer = buffer.baseAddress!
            var string = ""
            var index = 0
            for i in 0 ..< array.count where array[i] == 0 {
                if i > index {
                    string.append(String(cString: pointer.advanced(by: index)))
                }
                if i < array.count - 1 {
                    string.append("\u{0}")
                }
                index = i + 1
            }
            return string
        }
    }
}

extension RandomAccessCollection where Iterator.Element: Equatable {
    /// Returns the first index where the specified ordered items appears in the collection.
    fileprivate func index<T>(of items: T) -> Index? where
    T: RandomAccessCollection,
    T.Iterator.Element == Self.Element,
    T.Index == Self.Index,
    T.IndexDistance == Self.IndexDistance {
        guard self.first != nil else {
            return nil
        }
        guard let first = items.first else {
            return self.startIndex
        }
        var index = self.startIndex
        while index != self.endIndex {
            if self[index] == first {
                var i = index
                var j = items.startIndex
                while i != self.endIndex && j != items.endIndex {
                    if self[i] != items[j] {
                        break
                    }
                    i = self.index(after: i)
                    j = items.index(after: j)
                }
                if j == items.endIndex {
                    return index
                }
            }
            index = self.index(after: index)
        }
        return nil
    }

    /// Returns the last index where the specified ordered items appears in the collection.
    fileprivate func lastIndex<T>(of items: T) -> Index? where
    T: RandomAccessCollection,
    T.Iterator.Element == Self.Element,
    T.Index == Self.Index,
    T.IndexDistance == Self.IndexDistance {
        guard self.last != nil else {
            return nil
        }
        guard let last = items.last else {
            return self.endIndex
        }
        var index = self.endIndex
        repeat {
            index = self.index(before: index)
            if self[index] == last {
                var matched = true
                var i = self.index(after: index)
                var j = items.endIndex
                repeat {
                    i = self.index(before: i)
                    j = items.index(before: j)
                    if self[i] != items[j] {
                        matched = false
                        break
                    }
                } while i != self.startIndex && j != items.startIndex
                if matched && j == items.startIndex {
                    return i
                }
            }
        } while index != self.startIndex
        return nil
    }
}

extension ArraySlice where Iterator.Element == UInt8 {
    fileprivate func split(separator: [UInt8]) -> [ArraySlice<UInt8>] {
        var array: [ArraySlice<UInt8>] = []
        var value = self
        while true {
            if let index = value.index(of: separator) {
                array.append(value[value.startIndex ..< index])
                let nextIndex = value.index(index, offsetBy: separator.count)
                value = value[nextIndex...]
            }
            else {
                array.append(value)
                break
            }
        }
        return array
    }
}

//
//  Expression.Array.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    fileprivate struct Array {
        fileprivate let path: String

        fileprivate let separator: [Bytes]
        fileprivate let omit: Bool?
        fileprivate let item: [Slice?]?

        fileprivate let separatorIsArray: Bool
        fileprivate let itemIsArray: Bool
    }
}

extension Expression.Array: Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case separator
        case omit
        case item
    }

    fileprivate init(from decoder: Decoder) throws {
        path = Expression.path(of: decoder.codingPath)

        // The container must be a dictionary.
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            throw Expression.Error(.array, at: path)
        }

        // Gets the required `separator`
        if container.contains(.separator) {
            if let array = try? container.decode([String].self, forKey: .separator) {
                for value in array where value == "" {
                    throw Expression.Error(.separator, at: path + ".separator")
                }
                separator = array.map { $0.toBytes() }
                separatorIsArray = true
            }
            else if let value = try? container.decode(String.self, forKey: .separator) {
                if value == "" {
                    throw Expression.Error(.separator, at: path + ".separator")
                }
                separator = [value.toBytes()]
                separatorIsArray = false
            }
            else {
                throw Expression.Error(.separator, at: path + ".separator")
            }
            if self.separator.count == 0 {
                throw Expression.Error(.separator, at: path + ".separator")
            }
        }
        else {
            throw Expression.Error(.separatorMissing, at: path)
        }

        // Gets the optional `omit`.
        if container.contains(.omit) {
            guard let value = try? container.decode(Bool.self, forKey: .omit) else {
                throw Expression.Error(.omit, at: path + ".omit")
            }
            omit = value
        }
        else {
            omit = nil
        }

        // Gets the optional `item`
        if container.contains(.item) {
            if (try? container.decodeNil(forKey: .item)) == true {
                throw Expression.Error(.item, at: path + ".item")
            }
            do {
                let array = try container.decode([Expression.Slice?].self, forKey: .item)
                if array.isEmpty {
                    throw Expression.Error(.item, at: path + ".item")
                }
                item = array
                itemIsArray = true
            }
            catch DecodingError.typeMismatch {
                item = [try container.decode(Expression.Slice.self, forKey: .item)]
                itemIsArray = false
            }
        }
        else {
            item = nil
            itemIsArray = false
        }
    }

    fileprivate func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Sets the required `separator`.
        if self.separatorIsArray {
            try container.encode(separator.map({ $0.toString() }), forKey: .separator)
        }
        else {
            try container.encode(separator[0].toString(), forKey: .separator)
        }

        // Sets the optional `omit`.
        try container.encodeIfPresent(omit, forKey: .omit)

        // Sets the optional `item`
        if self.itemIsArray {
            try container.encodeIfPresent(item, forKey: .item)
        }
        else {
            try container.encodeIfPresent(item?[0], forKey: .item)
        }
    }
}

extension Expression.Array: Subexpression {
    fileprivate func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result {
        var results = [Expression.Result]()

        var parts = [input]
        for separator in self.separator {
            var array: [ArraySlice<UInt8>] = []
            for part in parts {
                array.append(contentsOf: part.split(separator: separator))
            }
            parts = array
        }
        for part in parts {
            if part.count == 0 && self.omit == true {
                continue
            }
            if let slices = self.item {
                if itemIsArray {
                    var errors = [Expression.Error]()
                    for slice in slices {
                        if let slice = slice {
                            do {
                                results.append(try slice.extract(part))
                                errors = []
                                break
                            }
                            catch let error as Expression.Error {
                                errors.append(error)
                            }
                        }
                        else {
                            errors = []
                            break
                        }
                    }
                    if errors.count > 0 {
                        let location =  errors.map { $0.at }.joined(separator: "\n")
                        throw Expression.Error(.inputUnmatched, at: location)
                    }
                }
                else {
                    results.append(try slices[0]!.extract(part))
                }
            }
            else {
                results.append(Expression.Result.string(part.toString()))
            }
        }

        return Expression.Result.array(results)
    }
}

//
//  Expression.Between.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    fileprivate struct Between {
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
    fileprivate enum CodingKeys: String, CodingKey {
        case backward
        case prefix
        case suffix
        case trim
    }

    fileprivate init(from decoder: Decoder) throws {
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

    fileprivate func encode(to encoder: Encoder) throws {
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
    fileprivate func extract(_ input: ArraySlice<UInt8>) throws -> ArraySlice<UInt8> {
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

//
//  Expression.Dictionary.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    fileprivate struct Dictionary {
        fileprivate let path: String

        fileprivate let members: [String: (slice: [Slice?], isArray: Bool)]
    }
}

extension Expression.Dictionary: Codable {
    fileprivate struct CodingKeys: CodingKey {
        var intValue: Int?
        var stringValue: String

        fileprivate init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
        fileprivate init?(stringValue: String) { self.stringValue = stringValue }
    }

    fileprivate init(from decoder: Decoder) throws {
        path = Expression.path(of: decoder.codingPath)

        // The container must be a dictionary.
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            throw Expression.Error(.dictionary, at: path)
        }

        // Loops through all keys.
        var members = [String: (slice: [Expression.Slice?], isArray: Bool)](minimumCapacity: container.allKeys.count)
        for key in container.allKeys {
            if (try? container.decodeNil(forKey: key)) == true {
                throw Expression.Error(.member, at: path + "[\"\(key.stringValue)\"]")
            }
            do {
                let array = try container.decode([Expression.Slice?].self, forKey: key)
                if array.isEmpty {
                    throw Expression.Error(.member, at: path + "[\"\(key.stringValue)\"]")
                }
                members[key.stringValue] = (slice: array, isArray: true)
            }
            catch DecodingError.typeMismatch {
                let value = try container.decode(Expression.Slice.self, forKey: key)
                members[key.stringValue] = (slice: [value], isArray: false)
            }
        }
        self.members = members
    }

    fileprivate func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
       for (name, member) in members {
            if member.isArray {
                try container.encode(member.slice, forKey: CodingKeys(stringValue: name)!)
            }
            else {
                try container.encode(member.slice[0], forKey: CodingKeys(stringValue: name)!)
            }
       }
    }
}

extension Expression.Dictionary: Subexpression {
    fileprivate func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result {
        var results: [String: Expression.Result] = [:]

        for (name, member) in members {
            if member.isArray {
                var errors = [Expression.Error]()
                for slice in member.slice {
                    if let slice = slice {
                        do {
                            results[name] = try slice.extract(input)
                            errors = []
                            break
                        }
                        catch let error as Expression.Error {
                            errors.append(error)
                        }
                    }
                    else {
                        errors = []
                        break
                    }
                }
                if errors.count > 0 {
                    let location =  errors.map { $0.at }.joined(separator: "\n")
                    throw Expression.Error(.inputUnmatched, at: location)
                }
            }
            else {
                results[name] = try member.slice[0]!.extract(input)
            }
        }

        return Expression.Result.dictionary(results)
    }
}

//
//  Expression.Error.swift
//  EXJN
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    /// Represents the type of `Expression.Error`.`
    public enum ErrorType {
        /// Property "array" must be an object.
        case array

        /// Property "backward" must be boolean.
        case backward

        /// Property "between" must be an object or an array of object.
        case between

        /// Property "by" must be a string.
        case by

        /// Property "by" is missing.
        case byMissing

        /// Property "dictionary" must be an object.
        case dictionary

        /// Expression must be an object with the required property "root".
        case expression

        /// Property "has" must be a string.
        case has

        /// Property "item" must be an object or an non-empty array of object and null.
        case item

        /// Member value of dictionary must be an object or a non-empty array of object and null.
        case member

        /// Property "omit" must be true or false.
        case omit

        /// Property "root" must be an object.
        case root

        /// Property "root" is missing.
        case rootMissing

        /// Property "prefix" must be either a string or an array of strings.
        case prefix

        /// Property "process" must be a string, an object, or an array of string and object.
        case process

        /// Function is not found in processors.
        case processUndefined

        /// Property "separator" must be either a non-empty string or an array of non-empty strings.
        case separator

        /// Property "separator" is missing.
        case separatorMissing

        /// Property "slice" must be an object or an non-empty array of object.
        case slice

        /// Only one of value, slice, array, and dictionary shall be defined.
        case subexpressions

        /// Property "suffix" must be either a string or an array of strings.
        case suffix

        /// Property "trim" must be boolean.
        case trim

        /// Provided input does not match the expression.
        case inputUnmatched

        /// Property "with" must be either a string or an array of strings."
        case with

    }
}

extension Expression {
    /// Holds the details of error thrown from initiating `Expression` or extracting content.
    public struct Error: Swift.Error {

        /// Returns the type of error.
        public let type: ErrorType

        /// Returns the location on the expression that threw error.
        public let at: String

        fileprivate init(_ type: ErrorType, at location: String) {
            self.type = type
            if location == "" {
                self.at = ""
            }
            // A work around for _runtime(_ObjC)
            // else if location.hasPrefix("@ ") {
            else if location.index(of: "@") == location.startIndex,
            let nextIndex = location.index(of: " "), nextIndex == location.index(after: location.startIndex) {
                self.at = location
            }
            else {
                self.at = "@ " + location
            }
        }
    }
}

extension Expression.Error {
    fileprivate var message: String {
        return messages[type]!
    }
}

extension Expression.Error: CustomStringConvertible {
    /// Represents itself int text.
    public var description: String {
        return message + "\n" + at
    }
}

extension Expression.Error: CustomDebugStringConvertible {
    /// Represents itself int text.
    public var debugDescription: String {
        return self.description
    }
}

private let messages: [Expression.ErrorType: String] = [
    .array: "Property \"array\" must be an object.",
    .backward: "Property \"backward\" must be boolean.",
    .between: "Property \"between\" must be an object or an array of object.",
    .by: "Property \"by\" must be a string.",
    .byMissing: "Property \"by\" is missing.",
    .dictionary: "Property \"dictionary\" must be an object.",
    .expression: "Expression must be an object with the required property \"root\".",
    .has: "Property \"has\" must be a string.",
    .item: "Property \"item\" must be an object or a non-empty array of object and null.",
    .member: "Member value of dictionary must be an object or a non-empty array of object and null.",
    .omit: "Property \"omit\" must be true or false.",
    .root: "Property \"root\" must be an object.",
    .rootMissing: "Property \"root\" is missing.",
    .prefix: "Property \"prefix\" must be either a string or an array of strings.",
    .process: "Property \"process\" must be a string, an object, or an array of string and object.",
    .processUndefined: "Function is not found in processors.",
    .separator: "Property \"separator\" must be either a non-empty string or an array of non-empty strings.",
    .separatorMissing: "Property \"separator\" is missing.",
    .slice: "Property \"slice\" must be an object or an non-empty array of object.",
    .subexpressions: "Only one of value, slice, array, and dictionary shall be defined.",
    .suffix: "Property \"suffix\" must be either a string or an array of strings.",
    .trim: "Property \"trim\" must be boolean.",
    .inputUnmatched: "Provided input does not match the expression.",
    .with: "Property \"with\" must be either a string or an array of strings."
]

//
//  Processor.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

/// Holds a collection of user-defined processors to be hooked to an `Expression`.
public typealias Processors = [String: (String, [String]?) throws -> String]

// Native processor
private typealias Processor = (ArraySlice<UInt8>, [String]?) throws -> ArraySlice<UInt8>

extension Expression {
    fileprivate struct Process {
        fileprivate let path: String

        fileprivate let by: String
        fileprivate let with: [String]?
        fileprivate let function: Processor

        fileprivate var processIsObject: Bool
        fileprivate var withIsArray: Bool
    }
}

extension Expression.Process: Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case by
        case with
    }

    fileprivate init(from decoder: Decoder) throws {
        path = Expression.path(of: decoder.codingPath)

        // The container can bet be a dictionary.
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            processIsObject = true

            // Gets the required `by`.
            if container.contains(.by) {
                guard let value = try? container.decode(String.self, forKey: .by) else {
                    throw Expression.Error(.by, at: path + ".by")
                }
                by = value
            }
            else {
                //throw Expression.Error(.byMissing, at: decoder.codingPath.description)
                throw Expression.Error(.byMissing, at: path)
            }

            // Gets the optional `with`
            if container.contains(.with) {
                if let array = try? container.decode([String].self, forKey: .with) {
                    with = array
                    withIsArray = true
                }
                else if let value = try? container.decode(String.self, forKey: .with) {
                    with = [value]
                    withIsArray = false
                }
                else {
                    throw Expression.Error(.with, at: path + ".with")
                }
            }
            else {
                with = nil
                withIsArray = false
            }
        }

        // Or simply it is a single String.
        else {
            let container = try decoder.singleValueContainer()
            processIsObject = false

            // Gets the process as `by`.
            if let value = try? container.decode(String.self) {
                by = value
            }
            else {
                throw Expression.Error(.process, at: path)
            }

            with = nil
            withIsArray = false
        }

        // Gets processors collection.
        if let pvalue = decoder.userInfo[Expression.processorsKey],
        let processors = pvalue as? Processors,
        let processor = processors[by] {
            function = { (input: ArraySlice<UInt8>, args: [String]?) throws -> ArraySlice<UInt8> in
                let string = try processor(input.toString(), args)
                let bytes = string.toBytes()
                return bytes[bytes.startIndex...]
            }
        }
        else if let processor = defaultProcessors[by] {
            function = processor
        }
        else {
            throw Expression.Error(.processUndefined, at: path + (processIsObject ? ".by" : ""))
        }
    }

    fileprivate func encode(to encoder: Encoder) throws {
        if processIsObject {
            var container = encoder.container(keyedBy: CodingKeys.self)

            // Sets the required `by`.
            try container.encode(by, forKey: .by)

            // Sets the optional `with` as an array of or a single string.
            if self.withIsArray {
                try container.encodeIfPresent(with, forKey: .with)
            }
            else {
                try container.encodeIfPresent(with?[0], forKey: .with)
            }
        }
        else {
            var container = encoder.singleValueContainer()
            try container.encode(self.by)
        }
    }
}

extension Expression.Process {
    fileprivate func extract(_ input: ArraySlice<UInt8>) throws -> ArraySlice<UInt8> {
        let result: ArraySlice<UInt8>
        do {
            result = try function(input, self.with)
        }
        catch {
            throw Expression.Error(.inputUnmatched, at: path)
        }
        return result
    }
}

private let defaultProcessors: [String: Processor] = [
    "append": { input, args in
        guard let array = args else {
            return input
        }
        let bytes = Array(input) + array.joined(separator: "").toBytes()
        return bytes[bytes.startIndex...]
    },
    "prepend": { input, args in
        guard let array = args else {
            return input
        }
        let bytes = array.joined(separator: "").toBytes() + Array(input)
        return bytes[bytes.startIndex...]
    },
    "replace": { input, args in
        guard let arrayOfString = args, arrayOfString.count > 1 else {
            return input
        }

        let array = arrayOfString.map { $0.toBytes() }
        var bytes = input
        var index = 0
        while index + 1 < array.count {
            let separator = array[index]
            let jointer = array[index + 1]
            let parts = bytes.split(separator: separator)
            bytes = Array(parts.joined(separator: jointer))[0...]
            index += 2
        }

        return bytes
    },
    "replaceTo": { input, args in
        guard let arrayOfString = args, arrayOfString.count == 2 else {
            return input
        }
        let bytes = arrayOfString[0].toBytes()[0...]
        let variable = arrayOfString[1].toBytes()
        let parts = bytes.split(separator: variable)
        return Array(parts.joined(separator: input))[0...]
    },
    "unescape": { input, args in
        guard let arrayOfString = args, arrayOfString.count > 0 else {
            return input
        }
        var string = input.toString()
        for arg in arrayOfString {
            if arg == "xml" {
                string = string.unescapedFromXML()
            }
            else if arg == "js" {
                string = string.unescapedFromJS()
            }
        }
        return string.toBytes()[0...]
    }
]

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

//
//  Expression.Slice.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

fileprivate protocol Subexpression {
    func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result
}

extension Expression {
    fileprivate struct Slice {
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
    fileprivate enum CodingKeys: String, CodingKey {
        case has
        case between
        case process
        case value
        case slice
        case array
        case dictionary
    }

    // swiftlint:disable:next function_body_length
    fileprivate init(from decoder: Decoder) throws {
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

    fileprivate func encode(to encoder: Encoder) throws {
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
    fileprivate func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result {
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
    fileprivate enum CodingKeys: String, CodingKey {
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
    fileprivate static func path(of codingKeys: [CodingKey]) -> String {
        // path = decoder.codingPath.map{$0.stringValue}.joined(separator: ".")
        var path = ""
        var prevKey: CodingKey?
        for key in codingKeys {
            if let index = key.intValue {
                path += "[\(index)]"
            }
            else if key is Expression.Dictionary.CodingKeys {
                path += "[\"\(key.stringValue)\"]"
            }
            else {
                // FIXME: workaround for linux bug SR-6294
                if let prevKey = prevKey, "\(prevKey)" == "\(key)" {
                    continue
                }
                prevKey = key
                if !path.isEmpty {
                    path += "."
                }
                path += key.stringValue
            }
        }
        return path
    }
}

//
//  String+unescapedFromJS.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

// swiftlint:disable superfluous_disable_command cyclomatic_complexity function_body_length

extension String {
    fileprivate func unescapedFromJS() -> String {
        var result = ""
        var entity = ""
        var state = JsState.char
        for scalar in self.unicodeScalars {
            let code = scalar.value
            switch state {
            case .char:
                if code == 0x5C { // \
                    state = .slash
                }
                else {
                    result.append(Character(scalar))
                }
            case .slash:
                if let string = jsMap[UInt8(code)] {
                    result.append(string)
                    state = .char
                }
                else if 0x30 <= code && code <= 0x37 { // 0 .. 7
                    entity = hexDigits[UInt8(code)]!
                    state = .octal
                }
                else if code == 0x78 { // x
                    state = .shortHex
                }
                else if code == 0x75 { // u
                    state = .hex
                }
                else {
                    result.append(state.prefix)
                    result.append(Character(scalar))
                    state = .char
                }
            case .octal:
                if 0x30 <= code && code <= 0x37 { // 0 .. 7
                    entity += hexDigits[UInt8(code)]!
                    if entity.count == 3 {
                        result.append(entity.decoded(at: state))
                        entity = ""
                        state = .char
                    }
                }
                else {
                    result.append(entity.decoded(at: state))
                    entity = ""
                    if code == 0x5C {
                        state = .slash
                    }
                    else {
                        result.append(Character(scalar))
                        state = .char
                    }
                }
            case .shortHex:
                if (0x30 <= code && code <= 0x39)
                || (0x41 <= code && code <= 0x46)
                || (0x61 <= code && code <= 0x66) {
                    entity += hexDigits[UInt8(code)]!
                    if entity.count == 2 {
                        result.append(entity.decoded(at: state))
                        entity = ""
                        state = .char
                    }
                }
                else {
                    result.append(state.prefix)
                    result.append(entity)
                    entity = ""
                    if code == 0x5C {
                        state = .slash
                    }
                    else {
                        result.append(Character(scalar))
                        state = .char
                    }
                }
            case .hex:
                if code == 0x7B { // {
                    state = .varHex
                }
                else if (0x30 <= code && code <= 0x39)
                || (0x41 <= code && code <= 0x46)
                || (0x61 <= code && code <= 0x66) {
                    entity = hexDigits[UInt8(code)]!
                    state = .longHex
                }
                else {
                    result.append(state.prefix)
                    result.append(entity)
                    entity = ""
                    if code == 0x5C {
                        state = .slash
                    }
                    else {
                        result.append(Character(scalar))
                        state = .char
                    }
                }
            case .longHex, .varHex:
                if (0x30 <= code && code <= 0x39)
                || (0x41 <= code && code <= 0x46)
                || (0x61 <= code && code <= 0x66) {
                    entity += hexDigits[UInt8(code)]!
                    if state == .longHex && entity.count == 4 {
                        result.append(entity.decoded(at: state))
                        entity = ""
                        state = .char
                    }
                }
                else if state == .varHex && code == 0x7D { // {
                    result.append(entity.decoded(at: state))
                    entity = ""
                    state = .char
                }
                else {
                    result.append(state.prefix)
                    result.append(entity)
                    entity = ""
                    if code == 0x5C {
                        state = .slash
                    }
                    else {
                        result.append(Character(scalar))
                        state = .char
                    }
                }
            }
        }
        if state != .char {
            result.append(state.prefix)
            result.append(entity)
        }
        return result
    }

    private func decoded(at state: JsState) -> String {
        switch state {
        case .octal, .shortHex, .longHex, .varHex:
            guard let value = UInt32(self, radix: state == .octal ? 8 : 16),
            let scalar = UnicodeScalar(value) else {
                return state.prefix + self
            }
            return String(scalar)
        default: // should never hit here
            return state.prefix + self
        }
    }
}

private enum JsState {
    case char
    case slash
    case octal
    case shortHex
    case hex
    case longHex
    case varHex

    var prefix: String {
        switch self {
        case .char: return ""
        case .slash: return "\\"
        case .octal: return "\\"
        case .shortHex: return "\\x"
        case .hex: return "\\u"
        case .longHex: return "\\u"
        case .varHex: return "\\u{"
        }
    }
}

private let jsMap: [UInt8: String] = [
    0x22: "\"",
    0x27: "\'",
    0x2F: "/",
    0x5C: "\\",
    0x62: "\u{8}",
    0x66: "\u{C}",
    0x6E: "\n",
    0x72: "\r",
    0x74: "\t",
    0x76: "\u{b}"
]

private let hexDigits: [UInt8: String] = [
    0x30: "0",
    0x31: "1",
    0x32: "2",
    0x33: "3",
    0x34: "4",
    0x35: "5",
    0x36: "6",
    0x37: "7",
    0x38: "8",
    0x39: "9",
    0x41: "A",
    0x42: "B",
    0x43: "C",
    0x44: "D",
    0x45: "E",
    0x46: "F",
    0x61: "a",
    0x62: "b",
    0x63: "c",
    0x64: "d",
    0x65: "e",
    0x66: "f"
]

//
//  String+unescapedFromXML.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

// swiftlint:disable superfluous_disable_command cyclomatic_complexity

extension String {
    fileprivate func unescapedFromXML() -> String {
        var result = ""
        var entity = ""
        var state = XmlState.char
        for scalar in self.unicodeScalars {
            let code = scalar.value
            switch state {
            case .char:
                if code == 0x26 { // &
                    state = .amp
                }
                else {
                    result.append(Character(scalar))
                }
            case .amp:
                if code == 0x26 { // &
                    result.append(state.prefix)
                }
                else if code == 0x23 { // #
                    state = .number
                }
                else if (0x30 <= code && code <= 0x39)
                || (0x41 <= code && code <= 0x5A)
                || (0x61 <= code && code <= 0x7A) {
                    state = .name
                    entity.append(Character(scalar))
                }
                else {
                    result.append(state.prefix)
                    result.append(Character(scalar))
                    state = .char
                }
            case .number:
                if code == 0x26 { // &
                    result.append(state.prefix)
                    state = .amp
                }
                else if code == 0x58 || code == 0x78 { // X or x
                    state = code == 0x58  ? .HEX : .hex
                }
                else if 0x30 <= code && code <= 0x39 {
                    state = .dec
                    entity.append(Character(scalar))
                }
                else {
                    result.append(state.prefix)
                    result.append(Character(scalar))
                    state = .char
                }
            case .dec, .hex, .HEX, .name:
                if code == 0x26 { // &
                    result.append(state.prefix)
                    result.append(entity)
                    state = .amp
                    entity = ""
                }
                else if code == 0x3B { // ;
                    result.append(entity.decoded(at: state))
                    state = .char
                    entity = ""
                }
                else if (0x30 <= code && code <= 0x39) // dec, hex, name
                || (state != .dec && ((0x41 <= code && code <= 0x46) || (0x61 <= code && code <= 0x66))) // hex
                || (state == .name && ((0x41 <= code && code <= 0x5A) || (0x61 <= code && code <= 0x7A))) { // name
                    entity.append(Character(scalar))
                }
                else {
                    result.append(state.prefix)
                    result.append(entity)
                    result.append(Character(scalar))
                    state = .char
                    entity = ""
                }
            }
        }
        if state != .char {
            result.append(state.prefix)
            result.append(entity)
        }
        return result
    }

    private func decoded(at state: XmlState) -> String {
        switch state {
        case .dec, .hex, .HEX:
            guard let value = UInt32(self, radix: state == .dec ? 10 : 16),
            let scalar = UnicodeScalar(value) else {
                return state.prefix + self + ";"
            }
            return String(scalar)
        case .name:
            return xmlMap[self] ?? (state.prefix + self + ";")
        default: // should never hit here
            return state.prefix + self + ";"
        }
    }
}

private enum XmlState {
    case char
    case amp
    case number
    case dec
    case hex
    case HEX
    case name

    var prefix: String {
        switch self {
        case .char: return ""
        case .amp: return "&"
        case .number: return "&#"
        case .dec: return "&#"
        case .hex: return "&#x"
        case .HEX: return "&#X"
        case .name: return "&"
        }
    }
}

private let xmlMap = [
    "lt": "<",
    "gt": ">",
    "quot": "\"",
    "apos": "'",
    "amp": "&"
]
