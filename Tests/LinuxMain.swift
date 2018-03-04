import XCTest
@testable import SimexTests

XCTMain([
    testCase(ResultTests.allTests),
    testCase(SyntaxTests.allTests),
    testCase(ExtractionTests.allTests),
])
