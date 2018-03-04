//
//  Expression.Dictionary.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

extension Expression {
    internal struct Dictionary {
        fileprivate let path: String

        fileprivate let members: [String: (slice: [Slice?], isArray: Bool)]
    }
}

extension Expression.Dictionary: Codable {
    internal struct CodingKeys: CodingKey {
        var intValue: Int?
        var stringValue: String

        internal init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
        internal init?(stringValue: String) { self.stringValue = stringValue }
    }

    internal init(from decoder: Decoder) throws {
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

    internal func encode(to encoder: Encoder) throws {
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
    internal func extract(_ input: ArraySlice<UInt8>) throws -> Expression.Result {
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
