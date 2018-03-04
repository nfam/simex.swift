//
//  String+unescapedFromXML.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

// swiftlint:disable superfluous_disable_command cyclomatic_complexity

extension String {
    internal func unescapedFromXML() -> String {
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
