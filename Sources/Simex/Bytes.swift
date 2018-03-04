//
//  Bytes.swift
//  Simex
//
//  Created by Ninh on 11/02/2016.
//  Copyright © 2016 Ninh. All rights reserved.
//

internal typealias Bytes = [UInt8]

extension String {
    /// UTF8 Array representation of string
    internal func toBytes() -> Bytes {
        return Array(utf8)
    }
}

extension Sequence where Iterator.Element == UInt8 {
    /// Converts a slice of bytes to string.
    internal func toString() -> String {
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
    internal func index<T>(of items: T) -> Index? where
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
    internal func lastIndex<T>(of items: T) -> Index? where
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
    internal func split(separator: [UInt8]) -> [ArraySlice<UInt8>] {
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
