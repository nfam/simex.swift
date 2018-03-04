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

        internal init(_ type: ErrorType, at location: String) {
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
