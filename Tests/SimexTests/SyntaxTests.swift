// swiftlint:disable superfluous_disable_command line_length file_length
import XCTest
import Foundation
@testable import Simex

class SyntaxTests: XCTestCase {
    static let allTests = [
        ("testExpression", testExpression),
        ("testValue", testValue),
        ("testSlice", testSlice),
        ("testSliceHas", testSliceHas),
        ("testSliceProcessBy", testSliceProcessBy),
        ("testSliceProcess", testSliceProcess),
        ("testSliceProcessWith", testSliceProcessWith),
        ("testSliceSlice", testSliceSlice),
        ("testSliceNested", testSliceNested),
        ("testSliceBetween", testSliceBetween),
        ("testSliceBetweenBackward", testSliceBetweenBackward),
        ("testSliceBetweenPrefix", testSliceBetweenPrefix),
        ("testSliceBetweenSuffix", testSliceBetweenSuffix),
        ("testSliceBetweenTrim", testSliceBetweenTrim),
        ("testArray", testArray),
        ("testArraySepartor", testArraySepartor),
        ("testArrayOmit", testArrayOmit),
        ("testArrayItem", testArrayItem),
        ("testDictionary", testDictionary),
        ("testDictionaryMember", testDictionaryMember)
    ]

    func testExpression() throws {
        // should fail with {}, and throw $rootMissing
        try test("{}", error: .rootMissing, at: "")

        // should fail with ["array"], and throw $expression
        try test("[\"array\"]", error: .expression, at: "")

        // should fail with {"root":null}, and throw $root
        try test("{\"root\":null}", error: .root, at: "root")

        // should fail with {"root":false}, and throw $root
        try test("{\"root\":false}", error: .root, at: "root")

        // should fail with {"root":true}, and throw $root
        try test("{\"root\":true}", error: .root, at: "root")

        // should fail with {"root":0}, and throw $root
        try test("{\"root\":0}", error: .root, at: "root")

        // should fail with {"root":"string"}, and throw $root
        try test("{\"root\":\"string\"}", error: .root, at: "root")

        // should load with {"root":{}}
        try test("{\"root\":{}}")

        // should fail with {"root":["array"]}, and throw $root
        try test("{\"root\":[\"array\"]}", error: .root, at: "root")
    }

    func testValue() throws {
        // should load with {"root":{"value":null}}
        try test("{\"root\":{\"value\":null}}")

        // should load with {"root":{"value":true}}
        try test("{\"root\":{\"value\":true}}")

        // should load with {"root":{"value":false}}
        try test("{\"root\":{\"value\":false}}")

        // should load with {"root":{"value":1}}
        try test("{\"root\":{\"value\":1}}")

        // should load with {"root":{"value":2}}
        try test("{\"root\":{\"value\":2}}")

        // should load with {"root":{"value":"string"}}
        try test("{\"root\":{\"value\":\"string\"}}")

        // should load with {"root":{"value":["array"]}}
        try test("{\"root\":{\"value\":[\"array\"]}}")

        // should load with {"root":{"value":["array",null,"array"]}}
        try test("{\"root\":{\"value\":[\"array\",null,\"array\"]}}")

        // should load with {"root":{"value":{"name":"value"}}}
        try test("{\"root\":{\"value\":{\"name\":\"value\"}}}")

        // should load with {"root":{"value":{"name":"value","null":null}}}
        try test("{\"root\":{\"value\":{\"name\":\"value\",\"null\":null}}}")
    }

    func testSlice() throws {
        // should fail with {"root":{"slice":null}}, and throw $slice
        try test("{\"root\":{\"slice\":null}}", error: .slice, at: "root.slice")

        // should fail with {"root":{"slice":false}}, and throw $slice
        try test("{\"root\":{\"slice\":false}}", error: .slice, at: "root.slice")

        // should fail with {"root":{"slice":true}}, and throw $slice
        try test("{\"root\":{\"slice\":true}}", error: .slice, at: "root.slice")

        // should fail with {"root":{"slice":0}}, and throw $slice
        try test("{\"root\":{\"slice\":0}}", error: .slice, at: "root.slice")

        // should fail with {"root":{"slice":"string"}}, and throw $slice
        try test("{\"root\":{\"slice\":\"string\"}}", error: .slice, at: "root.slice")

        // should load with {"root":{"slice":{}}}
        try test("{\"root\":{\"slice\":{}}}")

        // should fail with {"root":{"slice":["array"]}}, and throw $slice
        try test("{\"root\":{\"slice\":[\"array\"]}}", error: .slice, at: "root.slice[0]")
    }

    func testSliceHas() throws {
        // should fail with {"root":{"has":null}}, and throw $has
        try test("{\"root\":{\"has\":null}}", error: .has, at: "root.has")

        // should fail with {"root":{"has":false}}, and throw $has
        try test("{\"root\":{\"has\":false}}", error: .has, at: "root.has")

        // should fail with {"root":{"has":true}}, and throw $has
        try test("{\"root\":{\"has\":true}}", error: .has, at: "root.has")

        // should fail with {"root":{"has":0}}, and throw $has
        try test("{\"root\":{\"has\":0}}", error: .has, at: "root.has")

        // should load with {"root":{"has":"string"}}
        try test("{\"root\":{\"has\":\"string\"}}")

        // should fail with {"root":{"has":{}}}, and throw $has
        try test("{\"root\":{\"has\":{}}}", error: .has, at: "root.has")

        // should fail with {"root":{"has":["array"]}}, and throw $has
        try test("{\"root\":{\"has\":[\"array\"]}}", error: .has, at: "root.has")
    }

    func testSliceProcessBy() throws {
        // should fail with {"root":{"process":{}}}, and throw $byMissing
        try test("{\"root\":{\"process\":{}}}", error: .byMissing, at: "root.process")

        // should fail with {"root":{"process":{"by":null}}}, and throw $by
        try test("{\"root\":{\"process\":{\"by\":null}}}", error: .by, at: "root.process.by")

        // should fail with {"root":{"process":{"by":false}}}, and throw $by
        try test("{\"root\":{\"process\":{\"by\":false}}}", error: .by, at: "root.process.by")

        // should fail with {"root":{"process":{"by":true}}}, and throw $by
        try test("{\"root\":{\"process\":{\"by\":true}}}", error: .by, at: "root.process.by")

        // should fail with {"root":{"process":{"by":0}}}, and throw $by
        try test("{\"root\":{\"process\":{\"by\":0}}}", error: .by, at: "root.process.by")

        // should load with {"root":{"process":{"by":"int"}}}
        try test("{\"root\":{\"process\":{\"by\":\"int\"}}}")

        // should load with {"root":{"process":{"by":"append"}}}
        try test("{\"root\":{\"process\":{\"by\":\"append\"}}}")

        // should fail with {"root":{"process":{"by":"nofunction"}}}, and throw $processUndefined
        try test("{\"root\":{\"process\":{\"by\":\"nofunction\"}}}", error: .processUndefined, at: "root.process.by")

        // should fail with {"root":{"process":{"by":{}}}}, and throw $by
        try test("{\"root\":{\"process\":{\"by\":{}}}}", error: .by, at: "root.process.by")

        // should fail with {"root":{"process":{"by":["array"]}}}, and throw $by
        try test("{\"root\":{\"process\":{\"by\":[\"array\"]}}}", error: .by, at: "root.process.by")
    }

    func testSliceProcess() throws {
        // should fail with {"root":{"process":null}}, and throw $process
        try test("{\"root\":{\"process\":null}}", error: .process, at: "root.process")

        // should fail with {"root":{"process":false}}, and throw $process
        try test("{\"root\":{\"process\":false}}", error: .process, at: "root.process")

        // should fail with {"root":{"process":true}}, and throw $process
        try test("{\"root\":{\"process\":true}}", error: .process, at: "root.process")

        // should fail with {"root":{"process":0}}, and throw $process
        try test("{\"root\":{\"process\":0}}", error: .process, at: "root.process")

        // should fail with {"root":{"process":"nofunction"}}, and throw $processUndefined
        try test("{\"root\":{\"process\":\"nofunction\"}}", error: .processUndefined, at: "root.process")

        // should load with {"root":{"process":"int"}}
        try test("{\"root\":{\"process\":\"int\"}}")

        // should fail with {"root":{"process":{}}}, and throw $byMissing
        try test("{\"root\":{\"process\":{}}}", error: .byMissing, at: "root.process")

        // should load with {"root":{"process":["int"]}}
        try test("{\"root\":{\"process\":[\"int\"]}}")

        // should fail with {"root":{"process":[1]}}, and throw $process
        try test("{\"root\":{\"process\":[1]}}", error: .process, at: "root.process[0]")

        // should fail with {"root":{"process":["int",true]}}, and throw $process
        try test("{\"root\":{\"process\":[\"int\",true]}}", error: .process, at: "root.process[1]")

        // should load with {"root":{"process":"append"}}
        try test("{\"root\":{\"process\":\"append\"}}")

        // should load with {"root":{"process":"prepend"}}
        try test("{\"root\":{\"process\":\"prepend\"}}")

        // should load with {"root":{"process":"replace"}}
        try test("{\"root\":{\"process\":\"replace\"}}")
    }

    func testSliceProcessWith() throws {
        // should fail with {"root":{"process":{"by":"append","with":null}}}, and throw $with
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":null}}}", error: .with, at: "root.process.with")

        // should fail with {"root":{"process":{"by":"append","with":false}}}, and throw $with
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":false}}}", error: .with, at: "root.process.with")

        // should fail with {"root":{"process":{"by":"append","with":true}}}, and throw $with
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":true}}}", error: .with, at: "root.process.with")

        // should fail with {"root":{"process":{"by":"append","with":0}}}, and throw $with
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":0}}}", error: .with, at: "root.process.with")

        // should load with {"root":{"process":{"by":"append","with":"string"}}}
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":\"string\"}}}")

        // should fail with {"root":{"process":{"by":"append","with":{}}}}, and throw $with
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":{}}}}", error: .with, at: "root.process.with")

        // should load with {"root":{"process":{"by":"append","with":["string"]}}}
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":[\"string\"]}}}")

        // should fail with {"root":{"process":{"by":"append","with":[0]}}}, and throw $with
        try test("{\"root\":{\"process\":{\"by\":\"append\",\"with\":[0]}}}", error: .with, at: "root.process.with")
    }

    func testSliceSlice() throws {
        // should load with {"root":{"slice":{}}}
        try test("{\"root\":{\"slice\":{}}}")

        // should fail with {"root":{"slice":[]}}, and throw $slice
        try test("{\"root\":{\"slice\":[]}}", error: .slice, at: "root.slice")

        // should load with {"root":{"slice":[{}]}}
        try test("{\"root\":{\"slice\":[{}]}}")

        // should fail with {"root":{"slice":[{},null]}}, and throw $slice
        try test("{\"root\":{\"slice\":[{},null]}}", error: .slice, at: "root.slice[1]")

        // should fail with {"root":{"slice":[{},0]}}, and throw $slice
        try test("{\"root\":{\"slice\":[{},0]}}", error: .slice, at: "root.slice[1]")
    }

    func testSliceNested() throws {
        // should load with {"root":{"value":{}}}
        try test("{\"root\":{\"value\":{}}}")

        // should load with {"root":{"slice":{}}}
        try test("{\"root\":{\"slice\":{}}}")

        // should load with {"root":{"array":{"separator":"|"}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\"}}}")

        // should load with {"root":{"dictionary":{}}}
        try test("{\"root\":{\"dictionary\":{}}}")

        // should fail with {"root":{"value":0,"slice":0}}, and throw $subexpressions
        try test("{\"root\":{\"value\":0,\"slice\":0}}", error: .subexpressions, at: "root")

        // should fail with {"root":{"value":0,"array":0}}, and throw $subexpressions
        try test("{\"root\":{\"value\":0,\"array\":0}}", error: .subexpressions, at: "root")

        // should fail with {"root":{"value":0,"dictionary":0}}, and throw $subexpressions
        try test("{\"root\":{\"value\":0,\"dictionary\":0}}", error: .subexpressions, at: "root")

        // should fail with {"root":{"slice":0,"array":0}}, and throw $subexpressions
        try test("{\"root\":{\"slice\":0,\"array\":0}}", error: .subexpressions, at: "root")

        // should fail with {"root":{"slice":0,"dictionary":0}}, and throw $subexpressions
        try test("{\"root\":{\"slice\":0,\"dictionary\":0}}", error: .subexpressions, at: "root")

        // should fail with {"root":{"slice":0,"array":0,"dictionary":0}}, and throw $subexpressions
        try test("{\"root\":{\"slice\":0,\"array\":0,\"dictionary\":0}}", error: .subexpressions, at: "root")

        // should fail with {"root":{"array":0,"dictionary":0}}, and throw $subexpressions
        try test("{\"root\":{\"array\":0,\"dictionary\":0}}", error: .subexpressions, at: "root")
    }

    func testSliceBetween() throws {
        // should fail with {"root":{"between":null}}, and throw $between
        try test("{\"root\":{\"between\":null}}", error: .between, at: "root.between")

        // should fail with {"root":{"between":false}}, and throw $between
        try test("{\"root\":{\"between\":false}}", error: .between, at: "root.between")

        // should fail with {"root":{"between":true}}, and throw $between
        try test("{\"root\":{\"between\":true}}", error: .between, at: "root.between")

        // should fail with {"root":{"between":0}}, and throw $between
        try test("{\"root\":{\"between\":0}}", error: .between, at: "root.between")

        // should fail with {"root":{"between":"string"}}, and throw $between
        try test("{\"root\":{\"between\":\"string\"}}", error: .between, at: "root.between")

        // should load with {"root":{"between":{}}}
        try test("{\"root\":{\"between\":{}}}")

        // should fail with {"root":{"between":["array"]}}, and throw $between
        try test("{\"root\":{\"between\":[\"array\"]}}", error: .between, at: "root.between[0]")

        // should load with {"root":{"between":[{}]}}
        try test("{\"root\":{\"between\":[{}]}}")

        // should fail with {"root":{"between":[{},null]}}, and throw $between
        try test("{\"root\":{\"between\":[{},null]}}", error: .between, at: "root.between[1]")

        // should fail with {"root":{"between":[{},"array"]}}, and throw $between
        try test("{\"root\":{\"between\":[{},\"array\"]}}", error: .between, at: "root.between[1]")
    }

    func testSliceBetweenBackward() throws {
        // should fail with {"root":{"between":{"backward":null}}}, and throw $backward
        try test("{\"root\":{\"between\":{\"backward\":null}}}", error: .backward, at: "root.between.backward")

        // should load with {"root":{"between":{"backward":false}}}
        try test("{\"root\":{\"between\":{\"backward\":false}}}")

        // should load with {"root":{"between":{"backward":true}}}
        try test("{\"root\":{\"between\":{\"backward\":true}}}")

        // should fail with {"root":{"between":{"backward":0}}}, and throw $backward
        try test("{\"root\":{\"between\":{\"backward\":0}}}", error: .backward, at: "root.between.backward")

        // should fail with {"root":{"between":{"backward":"string"}}}, and throw $backward
        try test("{\"root\":{\"between\":{\"backward\":\"string\"}}}", error: .backward, at: "root.between.backward")

        // should fail with {"root":{"between":{"backward":{}}}}, and throw $backward
        try test("{\"root\":{\"between\":{\"backward\":{}}}}", error: .backward, at: "root.between.backward")

        // should fail with {"root":{"between":{"backward":["array"]}}}, and throw $backward
        try test("{\"root\":{\"between\":{\"backward\":[\"array\"]}}}", error: .backward, at: "root.between.backward")
    }

    func testSliceBetweenPrefix() throws {
        // should fail with {"root":{"between":{"prefix":null}}}, and throw $prefix
        try test("{\"root\":{\"between\":{\"prefix\":null}}}", error: .prefix, at: "root.between.prefix")

        // should fail with {"root":{"between":{"prefix":false}}}, and throw $prefix
        try test("{\"root\":{\"between\":{\"prefix\":false}}}", error: .prefix, at: "root.between.prefix")

        // should fail with {"root":{"between":{"prefix":true}}}, and throw $prefix
        try test("{\"root\":{\"between\":{\"prefix\":true}}}", error: .prefix, at: "root.between.prefix")

        // should fail with {"root":{"between":{"prefix":0}}}, and throw $prefix
        try test("{\"root\":{\"between\":{\"prefix\":0}}}", error: .prefix, at: "root.between.prefix")

        // should load with {"root":{"between":{"prefix":"string"}}}
        try test("{\"root\":{\"between\":{\"prefix\":\"string\"}}}")

        // should fail with {"root":{"between":{"prefix":{}}}}, and throw $prefix
        try test("{\"root\":{\"between\":{\"prefix\":{}}}}", error: .prefix, at: "root.between.prefix")

        // should load with {"root":{"between":{"prefix":["string"]}}}
        try test("{\"root\":{\"between\":{\"prefix\":[\"string\"]}}}")

        // should fail with {"root":{"between":{"prefix":[0]}}}, and throw $prefix
        try test("{\"root\":{\"between\":{\"prefix\":[0]}}}", error: .prefix, at: "root.between.prefix")
    }

    func testSliceBetweenSuffix() throws {
        // should fail with {"root":{"between":{"suffix":null}}}, and throw $suffix
        try test("{\"root\":{\"between\":{\"suffix\":null}}}", error: .suffix, at: "root.between.suffix")

        // should fail with {"root":{"between":{"suffix":false}}}, and throw $suffix
        try test("{\"root\":{\"between\":{\"suffix\":false}}}", error: .suffix, at: "root.between.suffix")

        // should fail with {"root":{"between":{"suffix":true}}}, and throw $suffix
        try test("{\"root\":{\"between\":{\"suffix\":true}}}", error: .suffix, at: "root.between.suffix")

        // should fail with {"root":{"between":{"suffix":0}}}, and throw $suffix
        try test("{\"root\":{\"between\":{\"suffix\":0}}}", error: .suffix, at: "root.between.suffix")

        // should load with {"root":{"between":{"suffix":"string"}}}
        try test("{\"root\":{\"between\":{\"suffix\":\"string\"}}}")

        // should fail with {"root":{"between":{"suffix":{}}}}, and throw $suffix
        try test("{\"root\":{\"between\":{\"suffix\":{}}}}", error: .suffix, at: "root.between.suffix")

        // should load with {"root":{"between":{"suffix":["string"]}}}
        try test("{\"root\":{\"between\":{\"suffix\":[\"string\"]}}}")

        // should fail with {"root":{"between":{"suffix":[0]}}}, and throw $suffix
        try test("{\"root\":{\"between\":{\"suffix\":[0]}}}", error: .suffix, at: "root.between.suffix")
    }

    func testSliceBetweenTrim() throws {
        // should fail with {"root":{"between":{"trim":null}}}, and throw $trim
        try test("{\"root\":{\"between\":{\"trim\":null}}}", error: .trim, at: "root.between.trim")

        // should load with {"root":{"between":{"trim":false}}}
        try test("{\"root\":{\"between\":{\"trim\":false}}}")

        // should load with {"root":{"between":{"trim":true}}}
        try test("{\"root\":{\"between\":{\"trim\":true}}}")

        // should fail with {"root":{"between":{"trim":0}}}, and throw $trim
        try test("{\"root\":{\"between\":{\"trim\":0}}}", error: .trim, at: "root.between.trim")

        // should fail with {"root":{"between":{"trim":"string"}}}, and throw $trim
        try test("{\"root\":{\"between\":{\"trim\":\"string\"}}}", error: .trim, at: "root.between.trim")

        // should fail with {"root":{"between":{"trim":{}}}}, and throw $trim
        try test("{\"root\":{\"between\":{\"trim\":{}}}}", error: .trim, at: "root.between.trim")

        // should fail with {"root":{"between":{"trim":["array"]}}}, and throw $trim
        try test("{\"root\":{\"between\":{\"trim\":[\"array\"]}}}", error: .trim, at: "root.between.trim")
    }

    func testArray() throws {
        // should fail with {"root":{"array":null}}, and throw $array
        try test("{\"root\":{\"array\":null}}", error: .array, at: "root.array")

        // should fail with {"root":{"array":false}}, and throw $array
        try test("{\"root\":{\"array\":false}}", error: .array, at: "root.array")

        // should fail with {"root":{"array":true}}, and throw $array
        try test("{\"root\":{\"array\":true}}", error: .array, at: "root.array")

        // should fail with {"root":{"array":0}}, and throw $array
        try test("{\"root\":{\"array\":0}}", error: .array, at: "root.array")

        // should fail with {"root":{"array":"string"}}, and throw $array
        try test("{\"root\":{\"array\":\"string\"}}", error: .array, at: "root.array")

        // should fail with {"root":{"array":{}}}, and throw $separatorMissing
        try test("{\"root\":{\"array\":{}}}", error: .separatorMissing, at: "root.array")

        // should load with {"root":{"array":{"separator":"|"}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\"}}}")

        // should fail with {"root":{"array":["array"]}}, and throw $array
        try test("{\"root\":{\"array\":[\"array\"]}}", error: .array, at: "root.array")
    }

    func testArraySepartor() throws {
        // should fail with {"root":{"array":{"separator":null}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":null}}}", error: .separator, at: "root.array.separator")

        // should fail with {"root":{"array":{"separator":false}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":false}}}", error: .separator, at: "root.array.separator")

        // should fail with {"root":{"array":{"separator":true}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":true}}}", error: .separator, at: "root.array.separator")

        // should fail with {"root":{"array":{"separator":0}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":0}}}", error: .separator, at: "root.array.separator")

        // should load with {"root":{"array":{"separator":"string"}}}
        try test("{\"root\":{\"array\":{\"separator\":\"string\"}}}")

        // should fail with {"root":{"array":{"separator":""}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":\"\"}}}", error: .separator, at: "root.array.separator")

        // should fail with {"root":{"array":{"separator":{}}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":{}}}}", error: .separator, at: "root.array.separator")

        // should load with {"root":{"array":{"separator":["array"]}}}
        try test("{\"root\":{\"array\":{\"separator\":[\"array\"]}}}")

        // should fail with {"root":{"array":{"separator":["array",""]}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":[\"array\",\"\"]}}}", error: .separator, at: "root.array.separator")

        // should fail with {"root":{"array":{"separator":["array",0]}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":[\"array\",0]}}}", error: .separator, at: "root.array.separator")

        // should fail with {"root":{"array":{"separator":[]}}}, and throw $separator
        try test("{\"root\":{\"array\":{\"separator\":[]}}}", error: .separator, at: "root.array.separator")
    }

    func testArrayOmit() throws {
        // should fail with {"root":{"array":{"separator":"|","omit":null}}}, and throw $omit
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":null}}}", error: .omit, at: "root.array.omit")

        // should load with {"root":{"array":{"separator":"|","omit":false}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":false}}}")

        // should load with {"root":{"array":{"separator":"|","omit":true}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":true}}}")

        // should fail with {"root":{"array":{"separator":"|","omit":0}}}, and throw $omit
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":0}}}", error: .omit, at: "root.array.omit")

        // should fail with {"root":{"array":{"separator":"|","omit":"string"}}}, and throw $omit
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":\"string\"}}}", error: .omit, at: "root.array.omit")

        // should fail with {"root":{"array":{"separator":"|","omit":""}}}, and throw $omit
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":\"\"}}}", error: .omit, at: "root.array.omit")

        // should fail with {"root":{"array":{"separator":"|","omit":{}}}}, and throw $omit
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":{}}}}", error: .omit, at: "root.array.omit")

        // should fail with {"root":{"array":{"separator":"|","omit":["array"]}}}, and throw $omit
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":[\"array\"]}}}", error: .omit, at: "root.array.omit")
    }

    func testArrayItem() throws {
        // should fail with {"root":{"array":{"separator":"|","item":null}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":null}}}", error: .item, at: "root.array.item")

        // should fail with {"root":{"array":{"separator":"|","item":false}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":false}}}", error: .item, at: "root.array.item")

        // should fail with {"root":{"array":{"separator":"|","item":true}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":true}}}", error: .item, at: "root.array.item")

        // should fail with {"root":{"array":{"separator":"|","item":0}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":0}}}", error: .item, at: "root.array.item")

        // should fail with {"root":{"array":{"separator":"|","item":"string"}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":\"string\"}}}", error: .item, at: "root.array.item")

        // should fail with {"root":{"array":{"separator":"|","item":"empty"}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":\"empty\"}}}", error: .item, at: "root.array.item")

        // should fail with {"root":{"array":{"separator":"|","item":"invalid"}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":\"invalid\"}}}", error: .item, at: "root.array.item")

        // should load with {"root":{"array":{"separator":"|","item":{}}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":{}}}}")

        // should fail with {"root":{"array":{"separator":"|","item":[]}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":[]}}}", error: .item, at: "root.array.item")

        // should load with {"root":{"array":{"separator":"|","item":[null]}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":[null]}}}")

        // should load with {"root":{"array":{"separator":"|","item":[{},{}]}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":[{},{}]}}}")

        // should load with {"root":{"array":{"separator":"|","item":[{},null]}}}
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":[{},null]}}}")

        // should fail with {"root":{"array":{"separator":"|","item":[{},"array"]}}}, and throw $item
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":[{},\"array\"]}}}", error: .item, at: "root.array.item[1]")
    }

    func testDictionary() throws {
        // should fail with {"root":{"dictionary":null}}, and throw $dictionary
        try test("{\"root\":{\"dictionary\":null}}", error: .dictionary, at: "root.dictionary")

        // should fail with {"root":{"dictionary":false}}, and throw $dictionary
        try test("{\"root\":{\"dictionary\":false}}", error: .dictionary, at: "root.dictionary")

        // should fail with {"root":{"dictionary":true}}, and throw $dictionary
        try test("{\"root\":{\"dictionary\":true}}", error: .dictionary, at: "root.dictionary")

        // should fail with {"root":{"dictionary":0}}, and throw $dictionary
        try test("{\"root\":{\"dictionary\":0}}", error: .dictionary, at: "root.dictionary")

        // should fail with {"root":{"dictionary":"string"}}, and throw $dictionary
        try test("{\"root\":{\"dictionary\":\"string\"}}", error: .dictionary, at: "root.dictionary")

        // should load with {"root":{"dictionary":{}}}
        try test("{\"root\":{\"dictionary\":{}}}")

        // should fail with {"root":{"dictionary":["array"]}}, and throw $dictionary
        try test("{\"root\":{\"dictionary\":[\"array\"]}}", error: .dictionary, at: "root.dictionary")
    }

    func testDictionaryMember() throws {
        // should fail with {"root":{"dictionary":{"name":null}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":null}}}", error: .member, at: "root.dictionary[\"name\"]")

        // should fail with {"root":{"dictionary":{"name":false}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":false}}}", error: .member, at: "root.dictionary[\"name\"]")

        // should fail with {"root":{"dictionary":{"name":true}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":true}}}", error: .member, at: "root.dictionary[\"name\"]")

        // should fail with {"root":{"dictionary":{"name":0}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":0}}}", error: .member, at: "root.dictionary[\"name\"]")

        // should fail with {"root":{"dictionary":{"name":"string"}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":\"string\"}}}", error: .member, at: "root.dictionary[\"name\"]")

        // should load with {"root":{"dictionary":{"name":{}}}}
        try test("{\"root\":{\"dictionary\":{\"name\":{}}}}")

        // should fail with {"root":{"dictionary":{"name":[]}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":[]}}}", error: .member, at: "root.dictionary[\"name\"]")

        // should load with {"root":{"dictionary":{"name":[{}]}}}
        try test("{\"root\":{\"dictionary\":{\"name\":[{}]}}}")

        // should load with {"root":{"dictionary":{"name":[{},null]}}}
        try test("{\"root\":{\"dictionary\":{\"name\":[{},null]}}}")

        // should fail with {"root":{"dictionary":{"name":[{},null,"array"]}}}, and throw $member
        try test("{\"root\":{\"dictionary\":{\"name\":[{},null,\"array\"]}}}", error: .member, at: "root.dictionary[\"name\"][2]")
    }
}
