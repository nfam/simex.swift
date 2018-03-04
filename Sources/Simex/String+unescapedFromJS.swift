//
//  String+unescapedFromJS.swift
//  Simex
//
//  Created by Ninh on 9/02/2015.
//  Copyright © 2015 Ninh. All rights reserved.
//

// swiftlint:disable superfluous_disable_command cyclomatic_complexity function_body_length

extension String {
    internal func unescapedFromJS() -> String {
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
