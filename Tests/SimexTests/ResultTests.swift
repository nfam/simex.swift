import XCTest
@testable import Simex

class ResultTests: XCTestCase {
    static let allTests = [
        ("testResult", testResult)
    ]

    internal func testResult() {
        let string = "string"
        XCTAssertEqual(Expression.Result.string(string).string, string)

        let array = [Expression.Result.string("0"), Expression.Result.string("1")]
        let resultArray = Expression.Result.array(array)
        XCTAssertNotNil(resultArray.array)
        XCTAssertEqual(resultArray[0]?.string, "0")
        XCTAssertNil(resultArray[2])
        XCTAssertNil(resultArray["0"])

        let dictionary = ["0": Expression.Result.string("0"), "1": Expression.Result.string("1")]
        let resultDictionary = Expression.Result.dictionary(dictionary)
        XCTAssertNotNil(resultDictionary.dictionary)
        XCTAssertEqual(resultDictionary["1"]?.string, "1")
        XCTAssertNil(resultDictionary[0])
        XCTAssertNil(resultDictionary["2"])
    }
}
