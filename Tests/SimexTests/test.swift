import Foundation
import Simex
import XCTest

let processors: Processors = [
    "int": { input, args in
        guard let radix = Int(args?[0] ?? "10", radix: 10) else {
            throw TestError(description: "Invalid radix for process \"int\"")
        }
        let index = input.index { char in
            return !["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].contains(char)
        }
        let text = input[input.startIndex ..< index]
        guard let value = Int(text, radix: radix) else {
            throw TestError(description: "Invalid input for process \"int\"")
        }
        return String(value)
    },
    "float": { input, _ in
        let index = input.index { char in
            return !["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."].contains(char)
        } ?? input.endIndex
        let text = input[input.startIndex ..< index]
        guard let value = Double(text) else {
            throw TestError(description: "Invalid input for process \"int\"")
        }
        return String(value)
    }
]

struct TestError: Error, CustomStringConvertible {
    let description: String
}

func test(
    _ json: String,
    input: String?  = nil,
    output: String? = nil,
    error errorType: Expression.ErrorType? = nil,
    at location: String? = nil,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    guard let data = json.data(using: .utf8) else {
        return
    }

    let sortedKeysRaw = UInt(1 << 1)
    let jsonOptions = JSONSerialization.WritingOptions(rawValue: sortedKeysRaw)
    let outputFormatting = JSONEncoder.OutputFormatting(rawValue: sortedKeysRaw)

    let jsonObject = try JSONSerialization.jsonObject(with: data)
    let serialized = try JSONSerialization.data(withJSONObject: jsonObject, options: jsonOptions)
    let serializedString = String(data: serialized, encoding: .utf8)!

    let encoder = JSONEncoder()
    encoder.outputFormatting = outputFormatting

    let decoder = JSONDecoder()
    decoder.userInfo[Expression.processorsKey] = processors

    if let input = input {
        if let errorType = errorType {
            do {
                let expression = try decoder.decode(Expression.self, from: data)
                _ = try expression.extract(input)
                XCTFail("Should fail extracting.", file: file, line: line)
            }
            catch let error as Expression.Error {
                XCTAssertEqual(error.type, errorType, file: file, line: line)
            }
        }
        else if let output = output {
            do {
                let expression = try decoder.decode(Expression.self, from: data)
                let result = try expression.extract(input)

                let resultString: String
                if let string = result.string {
                    let dict = Expression.Result.dictionary(["1": result])
                    var encoded: Data? = nil
                    do {
                        encoded = try encoder.encode(dict)
                    }
                    catch {
                        print(error)
                    }

                    if let encoded = encoded {
                        let data = encoded[5 ..< encoded.endIndex - 1]
                        resultString = String(data: data, encoding: .utf8)!
                    }
                    else {
                        resultString = "\"" + string + "\""
                    }
                }
                else {
                    let encoded = try encoder.encode(result)
                    resultString = String(data: encoded, encoding: .utf8)!
                }

                XCTAssertEqual(resultString, output, file: file, line: line)
            }
            catch {
                XCTFail("Should not encounter error. \(error)", file: file, line: line)
            }
        }
    }
    else if let errorType = errorType {
        do {
            _ = try decoder.decode(Expression.self, from: data)
            XCTFail("Should fail decoding", file: file, line: line)
        }
        catch let error as Expression.Error {
            XCTAssertEqual(error.type, errorType, file: file, line: line)
// FIXME: There is a bug with codingPath in Linux, disable this first.
#if os(OSX)
            if let location = location {
                if location != "" {
                    XCTAssertEqual(error.at, "@ " + location, file: file, line: line)
                    XCTAssertTrue(error.description.hasSuffix("\n@ " + location), file: file, line: line)
                    XCTAssertTrue(error.debugDescription.hasSuffix("\n@ " + location), file: file, line: line)
                }
                else {
                    XCTAssertEqual(error.at, location, file: file, line: line)
                }
            }
#endif
        }
    }
    else {
        do {
            let expression = try decoder.decode(Expression.self, from: data)
            let encoded = try encoder.encode(expression)
            let encodedString = String(data: encoded, encoding: .utf8)!

            XCTAssertEqual(encodedString, serializedString, file: file, line: line)
        }
        catch {
            XCTFail("Should not encounter error. \(error)", file: file, line: line)
        }
    }
}
