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
    internal struct Process {
        fileprivate let path: String

        fileprivate let by: String
        fileprivate let with: [String]?
        fileprivate let function: Processor

        fileprivate var processIsObject: Bool
        fileprivate var withIsArray: Bool
    }
}

extension Expression.Process: Codable {
    internal enum CodingKeys: String, CodingKey {
        case by
        case with
    }

    internal init(from decoder: Decoder) throws {
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

    internal func encode(to encoder: Encoder) throws {
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
    internal func extract(_ input: ArraySlice<UInt8>) throws -> ArraySlice<UInt8> {
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
