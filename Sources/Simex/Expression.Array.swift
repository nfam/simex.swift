//
//  Expression.Array.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    internal struct Array {
        fileprivate let path: String

        fileprivate let separator: [Bytes]
        fileprivate let omit: Bool?
        fileprivate let item: [Slice?]?

        fileprivate let separatorIsArray: Bool
        fileprivate let itemIsArray: Bool
    }
}

extension Expression.Array: Codable {
    internal enum CodingKeys: String, CodingKey {
        case separator
        case omit
        case item
    }

    internal init(from decoder: Decoder) throws {
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

    internal func encode(to encoder: Encoder) throws {
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
    internal func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result {
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
