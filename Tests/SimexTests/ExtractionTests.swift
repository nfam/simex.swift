// swiftlint:disable superfluous_disable_command line_length file_length
import XCTest
import Foundation
@testable import Simex

class ExtractionTests: XCTestCase {
    static let allTests = [
        ("testHas", testHas),
        ("testBetween", testBetween),
        ("testBetweenPrefix", testBetweenPrefix),
        ("testBetweenSuffix", testBetweenSuffix),
        ("testBetweenTrim", testBetweenTrim),
        ("testBetweenBackward", testBetweenBackward),
        ("testProcess", testProcess),
        ("testProcessUnescape", testProcessUnescape),
        ("testArray", testArray),
        ("testSliceSlice", testSliceSlice),
        ("testDictionary", testDictionary),
        ("testNested", testNested),
        ("testValue", testValue)
    ]

    func testHas() throws {
        // should extract with {"root":{"slice":{"has":"#"}}} from "#0" to \"#0\"
        try test("{\"root\":{\"slice\":{\"has\":\"#\"}}}", input: "#0", output: "\"#0\"")

        // should fail with {"root":{"slice":{"has":"#"}}} from "0", throw $inputUnmatched
        try test("{\"root\":{\"slice\":{\"has\":\"#\"}}}", input: "0", error: .inputUnmatched, at: "root.slice.has")

        // should extract with {"root":{"slice":{"has":"\u0000"}}} from "0 \u{0} 1" to \"0 \\u0000 1\"
        try test("{\"root\":{\"slice\":{\"has\":\"\\u0000\"}}}", input: "0 \u{0} 1", output: "\"0 \\u0000 1\"")
    }

    func testBetween() throws {
        // should extract with {"root":{"between":{"backward":true,"prefix":["0","2"],"suffix":"0","trim":true}}} from " 0 X 2 0 1 " to \"X\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":[\"0\",\"2\"],\"suffix\":\"0\",\"trim\":true}}}", input: " 0 X 2 0 1 ", output: "\"X\"")

        // should extract with {"root":{"between":[{"prefix":["0"],"suffix":"0","trim":true},{"prefix":["X"]}]}} from " 0 X 2 0 1 Y " to \" 2\"
        try test("{\"root\":{\"between\":[{\"prefix\":[\"0\"],\"suffix\":\"0\",\"trim\":true},{\"prefix\":[\"X\"]}]}}", input: " 0 X 2 0 1 Y ", output: "\" 2\"")
    }

    func testBetweenPrefix() throws {
        // should extract with {"root":{"between":{"prefix":""}}} from " 0 1 2 0 1 " to \" 0 1 2 0 1 \"
        try test("{\"root\":{\"between\":{\"prefix\":\"\"}}}", input: " 0 1 2 0 1 ", output: "\" 0 1 2 0 1 \"")

        // should extract with {"root":{"between":{"prefix":"0"}}} from " 0 1 2 0 1 " to \" 1 2 0 1 \"
        try test("{\"root\":{\"between\":{\"prefix\":\"0\"}}}", input: " 0 1 2 0 1 ", output: "\" 1 2 0 1 \"")

        // should extract with {"root":{"between":{"prefix":["0","0"]}}} from " 0 1 2 0 1 " to \" 1 \"
        try test("{\"root\":{\"between\":{\"prefix\":[\"0\",\"0\"]}}}", input: " 0 1 2 0 1 ", output: "\" 1 \"")

        // should fail with {"root":{"between":{"prefix":"#"}}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"prefix\":\"#\"}}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between.prefix")

        // should fail with {"root":{"between":{"prefix":["0","#"]}}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"prefix\":[\"0\",\"#\"]}}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between.prefix[1]")

        // should fail with {"root":{"between":[{"prefix":["0","#"]}]}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":[{\"prefix\":[\"0\",\"#\"]}]}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between[0].prefix[1]")
    }

    func testBetweenSuffix() throws {
        // should extract with {"root":{"between":{"suffix":""}}} from " 0 1 2 0 1 " to \" 0 1 2 0 1 \"
        try test("{\"root\":{\"between\":{\"suffix\":\"\"}}}", input: " 0 1 2 0 1 ", output: "\" 0 1 2 0 1 \"")

        // should extract with {"root":{"between":{"suffix":"1"}}} from " 0 1 2 0 1 " to \" 0 \"
        try test("{\"root\":{\"between\":{\"suffix\":\"1\"}}}", input: " 0 1 2 0 1 ", output: "\" 0 \"")

        // should extract with {"root":{"between":{"suffix":["3","1"]}}} from " 0 1 2 0 1 " to \" 0 \"
        try test("{\"root\":{\"between\":{\"suffix\":[\"3\",\"1\"]}}}", input: " 0 1 2 0 1 ", output: "\" 0 \"")

        // should fail with {"root":{"between":{"suffix":"#"}}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"suffix\":\"#\"}}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between.suffix")

        // should fail with {"root":{"between":{"suffix":["@","#"]}}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"suffix\":[\"@\",\"#\"]}}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between.suffix")
    }

    func testBetweenTrim() throws {
        // should extract with {"root":{"between":{"trim":true}}} from " 0 1 2 0 1 " to \"0 1 2 0 1\"
        try test("{\"root\":{\"between\":{\"trim\":true}}}", input: " 0 1 2 0 1 ", output: "\"0 1 2 0 1\"")
    }

    func testBetweenBackward() throws {
        // should extract with {"root":{"between":{"backward":true,"prefix":"","trim":true}}} from " 0 1 2 3 " to \"0 1 2 3\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":\"\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"0 1 2 3\"")

        // should extract with {"root":{"between":{"backward":true,"prefix":"1"}}} from " 0 1 2 3 " to \" 0 \"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":\"1\"}}}", input: " 0 1 2 3 ", output: "\" 0 \"")

        // should extract with {"root":{"between":{"backward":true,"prefix":"1","trim":true}}} from " 0 1 2 3 " to \"0\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":\"1\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"0\"")

        // should extract with {"root":{"between":{"backward":true,"prefix":"3","trim":true}}} from " 0 1 2 3 " to \"0 1 2\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":\"3\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"0 1 2\"")

        // should extract with {"root":{"between":{"backward":true,"prefix":["3","2"],"trim":true}}} from " 0 1 2 3 " to \"0 1\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":[\"3\",\"2\"],\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"0 1\"")

        // should extract with {"root":{"between":{"backward":true,"prefix":["0",""],"trim":true}}} from "0 1 2 3 " to \"\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":[\"0\",\"\"],\"trim\":true}}}", input: "0 1 2 3 ", output: "\"\"")

        // should extract with {"root":{"between":{"backward":true,"suffix":"","trim":true}}} from " 0 1 2 3 " to \"0 1 2 3\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"suffix\":\"\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"0 1 2 3\"")

        // should extract with {"root":{"between":{"backward":true,"suffix":"1","trim":true}}} from " 0 1 2 3 " to \"2 3\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"suffix\":\"1\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"2 3\"")

        // should extract with {"root":{"between":{"backward":true,"suffix":"0","trim":true}}} from " 0 1 2 3 " to \"1 2 3\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"suffix\":\"0\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"1 2 3\"")

        // should extract with {"root":{"between":{"backward":true,"prefix":["3","2"],"suffix":"0","trim":true}}} from " 0 1 2 3 " to \"1\"
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":[\"3\",\"2\"],\"suffix\":\"0\",\"trim\":true}}}", input: " 0 1 2 3 ", output: "\"1\"")

        // should fail with {"root":{"between":{"backward":true,"prefix":"#"}}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":\"#\"}}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between.prefix")

        // should fail with {"root":{"between":{"backward":true,"prefix":["0","#"]}}} from " 0 1 2 4 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":[\"0\",\"#\"]}}}", input: " 0 1 2 4 ", error: .inputUnmatched, at: "root.between.prefix[1]")

        // should fail with {"root":{"between":{"backward":true,"prefix":["0","#"]}}} from "0 1 2 4 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"backward\":true,\"prefix\":[\"0\",\"#\"]}}}", input: "0 1 2 4 ", error: .inputUnmatched, at: "root.between.prefix[1]")

        // should fail with {"root":{"between":{"backward":true,"suffix":"4 "}}} from " 0 1 2 3 ", throw $inputUnmatched
        try test("{\"root\":{\"between\":{\"backward\":true,\"suffix\":\"4 \"}}}", input: " 0 1 2 3 ", error: .inputUnmatched, at: "root.between.suffix")
    }

    func testProcess() throws {
        // should extract with {"root":{"process":"int"}} from "1.1" to \"1\"
        try test("{\"root\":{\"process\":\"int\"}}", input: "1.1", output: "\"1\"")

        // should fail with {"root":{"process":"int"}} from "th", throw $inputUnmatched
        try test("{\"root\":{\"process\":\"int\"}}", input: "th", error: .inputUnmatched, at: "root.process")

        // should extract with {"root":{"process":"float"}} from "1.1" to \"1.1\"
        try test("{\"root\":{\"process\":\"float\"}}", input: "1.1", output: "\"1.1\"")

        // should fail with {"root":{"process":"float"}} from "th", throw $inputUnmatched
        try test("{\"root\":{\"process\":\"float\"}}", input: "th", error: .inputUnmatched, at: "root.process")

        // should fail with {"root":{"slice":{"process":"float"}}} from "th", throw $inputUnmatched
        try test("{\"root\":{\"slice\":{\"process\":\"float\"}}}", input: "th", error: .inputUnmatched, at: "root.slice.process")

        // should extract with {"root":{"slice":{"process":{"by":"append"}}}} from "0123" to \"0123\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"append\"}}}}", input: "0123", output: "\"0123\"")

        // should extract with {"root":{"slice":{"process":{"by":"prepend"}}}} from "0123" to \"0123\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"prepend\"}}}}", input: "0123", output: "\"0123\"")

        // should extract with {"root":{"slice":{"process":{"by":"replace"}}}} from "0123" to \"0123\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"replace\"}}}}", input: "0123", output: "\"0123\"")

        // should extract with {"root":{"slice":{"process":{"by":"replaceTo"}}}} from "0123" to \"0123\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"replaceTo\"}}}}", input: "0123", output: "\"0123\"")

        // should extract with {"root":{"slice":{"process":{"by":"append","with":"0"}}}} from "0123" to \"01230\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"append\",\"with\":\"0\"}}}}", input: "0123", output: "\"01230\"")

        // should extract with {"root":{"slice":{"process":{"by":"prepend","with":"-"}}}} from "0123" to \"-0123\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"prepend\",\"with\":\"-\"}}}}", input: "0123", output: "\"-0123\"")

        // should extract with {"root":{"slice":{"process":{"by":"replace","with":["1","-"]}}}} from "0123" to \"0-23\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"replace\",\"with\":[\"1\",\"-\"]}}}}", input: "0123", output: "\"0-23\"")

        // should extract with {"root":{"slice":{"process":{"by":"replaceTo","with":["text-{x}-0","{x}"]}}}} from "value" to \"text-value-0\"
        try test("{\"root\":{\"slice\":{\"process\":{\"by\":\"replaceTo\",\"with\":[\"text-{x}-0\",\"{x}\"]}}}}", input: "value", output: "\"text-value-0\"")

        // should extract with {"root":{"slice":{"process":[{"by":"append","with":"0"},{"by":"prepend","with":"-"}]}}} from "0123" to \"-01230\"
        try test("{\"root\":{\"slice\":{\"process\":[{\"by\":\"append\",\"with\":\"0\"},{\"by\":\"prepend\",\"with\":\"-\"}]}}}", input: "0123", output: "\"-01230\"")

        // should fail with {"root":{"slice":{"process":[{"by":"prepend","with":"*"},"int"]}}} from "12", throw $inputUnmatched
        try test("{\"root\":{\"slice\":{\"process\":[{\"by\":\"prepend\",\"with\":\"*\"},\"int\"]}}}", input: "12", error: .inputUnmatched, at: "root.slice.process[1]")
    }

    func testProcessUnescape() throws {
        // should extract with {"root":{"process":{"by":"unescape","with":"xml"}}} from "&apos;" to \"'\"
        try test("{\"root\":{\"process\":{\"by\":\"unescape\",\"with\":\"xml\"}}}", input: "&apos;", output: "\"'\"")

        // should extract with {"root":{"process":{"by":"unescape","with":"xml"}}} from "&apos;&lt;&gt;&quot;&amp;&copy;&#8710;&#xAE;" to \"'<>\\\"&&copy;∆®\"
        try test("{\"root\":{\"process\":{\"by\":\"unescape\",\"with\":\"xml\"}}}", input: "&apos;&lt;&gt;&quot;&amp;&copy;&#8710;&#xAE;", output: "\"'<>\\\"&&copy;∆®\"")

        // should extract with {"root":{"process":{"by":"unescape","with":"js"}}} from "\\0\\b\\f\\n\\r\\t\\v\\'\\\\\\\" \\123\\040\\54\\4 \\xAC \\u00A9 \\u{A9} \\u{2F804}" to \"\\u0000\\b\\f\\n\\r\\t\\u000b'\\\\\\\" S ,\\u0004 ¬ © © \u{2F804}\"
        try test("{\"root\":{\"process\":{\"by\":\"unescape\",\"with\":\"js\"}}}", input: "\\0\\b\\f\\n\\r\\t\\v\\'\\\\\\\" \\123\\040\\54\\4 \\xAC \\u00A9 \\u{A9} \\u{2F804}", output: "\"\\u0000\\b\\f\\n\\r\\t\\u000b'\\\\\\\" S ,\\u0004 ¬ © © \u{2F804}\"")

        // should extract with {"root":{"process":{"by":"unescape","with":"xml"}}} from "a&&#&#x&#X&lt;&" to \"a&&#&#x&#X<&\"
        try test("{\"root\":{\"process\":{\"by\":\"unescape\",\"with\":\"xml\"}}}", input: "a&&#&#x&#X&lt;&", output: "\"a&&#&#x&#X<&\"")

        // should extract with {"root":{"process":{"by":"unescape","with":"js"}}} from "\\43\\xA6\\xA\\xBV\\u\\uA\\ua0\\x" to \"#¦\\\\xA\\\\xBV\\\\u\\\\uA\\\\ua0\\\\x\"
        try test("{\"root\":{\"process\":{\"by\":\"unescape\",\"with\":\"js\"}}}", input: "\\43\\xA6\\xA\\xBV\\u\\uA\\ua0\\x", output: "\"#¦\\\\xA\\\\xBV\\\\u\\\\uA\\\\ua0\\\\x\"")
    }

    func testArray() throws {
        // should extract with {"root":{"array":{"separator":" "}}} from " 0 " to [\"\",\"0\",\"\"]
        try test("{\"root\":{\"array\":{\"separator\":\" \"}}}", input: " 0 ", output: "[\"\",\"0\",\"\"]")

        // should extract with {"root":{"array":{"separator":" ","omit":true}}} from " 0 " to [\"0\"]
        try test("{\"root\":{\"array\":{\"separator\":\" \",\"omit\":true}}}", input: " 0 ", output: "[\"0\"]")

        // should extract with {"root":{"array":{"separator":" "}}} from " 0 1 2 3 " to [\"\",\"0\",\"1\",\"2\",\"3\",\"\"]
        try test("{\"root\":{\"array\":{\"separator\":\" \"}}}", input: " 0 1 2 3 ", output: "[\"\",\"0\",\"1\",\"2\",\"3\",\"\"]")

        // should extract with {"root":{"array":{"separator":" ","omit":true}}} from " 0 1 2 3 " to [\"0\",\"1\",\"2\",\"3\"]
        try test("{\"root\":{\"array\":{\"separator\":\" \",\"omit\":true}}}", input: " 0 1 2 3 ", output: "[\"0\",\"1\",\"2\",\"3\"]")

        // should extract with {"root":{"array":{"separator":" "}}} from " 0  1  2  3 " to [\"\",\"0\",\"\",\"1\",\"\",\"2\",\"\",\"3\",\"\"]
        try test("{\"root\":{\"array\":{\"separator\":\" \"}}}", input: " 0  1  2  3 ", output: "[\"\",\"0\",\"\",\"1\",\"\",\"2\",\"\",\"3\",\"\"]")

        // should extract with {"root":{"array":{"separator":" ","omit":true}}} from " 0  1  2  3 " to [\"0\",\"1\",\"2\",\"3\"]
        try test("{\"root\":{\"array\":{\"separator\":\" \",\"omit\":true}}}", input: " 0  1  2  3 ", output: "[\"0\",\"1\",\"2\",\"3\"]")

        // should extract with {"root":{"array":{"separator":[" ","|"]}}} from " 0|1|2|3 " to [\"\",\"0\",\"1\",\"2\",\"3\",\"\"]
        try test("{\"root\":{\"array\":{\"separator\":[\" \",\"|\"]}}}", input: " 0|1|2|3 ", output: "[\"\",\"0\",\"1\",\"2\",\"3\",\"\"]")

        // should fail with {"root":{"array":{"separator":"|","item":{"has":"#"}}}} from "#0|#1|#2|3", throw $inputUnmatched
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":{\"has\":\"#\"}}}}", input: "#0|#1|#2|3", error: .inputUnmatched, at: "root.array.item.has")

        // should fail with {"root":{"array":{"separator":"|","item":[{"has":"."},{"has":"#"}]}}} from "#0|#1|#2|3", throw $inputUnmatched
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":[{\"has\":\".\"},{\"has\":\"#\"}]}}}", input: "#0|#1|#2|3", error: .inputUnmatched, at: "root.array.item[0].has\n@ root.array.item[1].has")

        // should extract with {"root":{"array":{"separator":[" ","|"],"item":[{"has":"#"},null]}}} from " #0|#1|#2|3 " to [\"#0\",\"#1\",\"#2\"]
        try test("{\"root\":{\"array\":{\"separator\":[\" \",\"|\"],\"item\":[{\"has\":\"#\"},null]}}}", input: " #0|#1|#2|3 ", output: "[\"#0\",\"#1\",\"#2\"]")

        // should extract with {"root":{"array":{"separator":"|","omit":true,"item":[{"between":{"prefix":"#"}},null]}}} from " #0|$|#|#2" to [\"0\",\"\",\"2\"]
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"omit\":true,\"item\":[{\"between\":{\"prefix\":\"#\"}},null]}}}", input: " #0|$|#|#2", output: "[\"0\",\"\",\"2\"]")
    }

    func testSliceSlice() throws {
        // should extract with {"root":{"slice":{"has":"#","value":"X"}}} from "#0" to \"X\"
        try test("{\"root\":{\"slice\":{\"has\":\"#\",\"value\":\"X\"}}}", input: "#0", output: "\"X\"")

        // should extract with {"root":{"slice":[{"has":"#","value":"X"},{"has":"$","value":"M"}]}} from "$X" to \"M\"
        try test("{\"root\":{\"slice\":[{\"has\":\"#\",\"value\":\"X\"},{\"has\":\"$\",\"value\":\"M\"}]}}", input: "$X", output: "\"M\"")

        // should fail with {"root":{"slice":{"has":"#"}}} from "0", throw $inputUnmatched
        try test("{\"root\":{\"slice\":{\"has\":\"#\"}}}", input: "0", error: .inputUnmatched, at: "root.slice.has")

        // should fail with {"root":{"slice":[{"has":"#","value":"X"},{"has":"$","value":"M"}]}} from "KX", throw $inputUnmatched
        try test("{\"root\":{\"slice\":[{\"has\":\"#\",\"value\":\"X\"},{\"has\":\"$\",\"value\":\"M\"}]}}", input: "KX", error: .inputUnmatched, at: "root.slice[0].has\n@ root.slice[1].has")
    }

    func testDictionary() throws {
        // should extract with {"root":{"dictionary":{"name":{}}}} from " 0 " to {\"name\":\" 0 \"}
        try test("{\"root\":{\"dictionary\":{\"name\":{}}}}", input: " 0 ", output: "{\"name\":\" 0 \"}")

        // should extract with {"root":{"dictionary":{"name":{"between":{"trim":true}}}}} from " 0 " to {\"name\":\"0\"}
        try test("{\"root\":{\"dictionary\":{\"name\":{\"between\":{\"trim\":true}}}}}", input: " 0 ", output: "{\"name\":\"0\"}")

        // should extract with {"root":{"dictionary":{"n0":{"between":{"prefix":"n0:","suffix":" "}},"n1":{"between":{"prefix":"n1:","suffix":"#","trim":true}}}}} from " n0:0 n1: 1# " to {\"n0\":\"0\",\"n1\":\"1\"}
        try test("{\"root\":{\"dictionary\":{\"n0\":{\"between\":{\"prefix\":\"n0:\",\"suffix\":\" \"}},\"n1\":{\"between\":{\"prefix\":\"n1:\",\"suffix\":\"#\",\"trim\":true}}}}}", input: " n0:0 n1: 1# ", output: "{\"n0\":\"0\",\"n1\":\"1\"}")

        // should extract with {"root":{"dictionary":{"n0":{"between":{"prefix":"n0:","suffix":" "}},"n1":[{"between":{"prefix":"n1:","suffix":"$"}},null]}}} from " n0:0 n1: 1# " to {\"n0\":\"0\"}
        try test("{\"root\":{\"dictionary\":{\"n0\":{\"between\":{\"prefix\":\"n0:\",\"suffix\":\" \"}},\"n1\":[{\"between\":{\"prefix\":\"n1:\",\"suffix\":\"$\"}},null]}}}", input: " n0:0 n1: 1# ", output: "{\"n0\":\"0\"}")

        // should extract with {"root":{"dictionary":{"n0":{"between":{"prefix":"n0:","suffix":" "}},"n1":[{"between":{"prefix":"n1:","suffix":"$"}},{"between":{"prefix":"n1:","suffix":"#"}}]}}} from " n0:0 n1: 1# " to {\"n0\":\"0\",\"n1\":\" 1\"}
        try test("{\"root\":{\"dictionary\":{\"n0\":{\"between\":{\"prefix\":\"n0:\",\"suffix\":\" \"}},\"n1\":[{\"between\":{\"prefix\":\"n1:\",\"suffix\":\"$\"}},{\"between\":{\"prefix\":\"n1:\",\"suffix\":\"#\"}}]}}}", input: " n0:0 n1: 1# ", output: "{\"n0\":\"0\",\"n1\":\" 1\"}")

        // should fail with {"root":{"dictionary":{"n0":{"between":{"prefix":"n0:","suffix":" "}},"n1":[{"between":{"prefix":"n1:","suffix":"$"}},{"between":{"prefix":"n2:","suffix":"#"}}]}}} from " n0:0 n1: 1# ", throw $inputUnmatched
        try test("{\"root\":{\"dictionary\":{\"n0\":{\"between\":{\"prefix\":\"n0:\",\"suffix\":\" \"}},\"n1\":[{\"between\":{\"prefix\":\"n1:\",\"suffix\":\"$\"}},{\"between\":{\"prefix\":\"n2:\",\"suffix\":\"#\"}}]}}}", input: " n0:0 n1: 1# ", error: .inputUnmatched, at: "root.dictionary[\"n1\"][0].between.suffix\n@ root.dictionary[\"n1\"][1].between.prefix")

        // should fail with {"root":{"dictionary":{"name":{"has":"#"}}}} from " 0 ", throw $inputUnmatched
        try test("{\"root\":{\"dictionary\":{\"name\":{\"has\":\"#\"}}}}", input: " 0 ", error: .inputUnmatched, at: "root.dictionary[\"name\"].has")

        // should fail with {"root":{"dictionary":{"name":{"has":"#"}}}} from " 0 ", throw $inputUnmatched
        try test("{\"root\":{\"dictionary\":{\"name\":{\"has\":\"#\"}}}}", input: " 0 ", error: .inputUnmatched, at: "root.dictionary[\"name\"].has")
    }

    func testNested() throws {
        // should extract with {"root":{"array":{"separator":"|","item":{"between":{"prefix":"#"}}}}} from "#0|#1.X|#2" to [\"0\",\"1.X\",\"2\"]
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":{\"between\":{\"prefix\":\"#\"}}}}}", input: "#0|#1.X|#2", output: "[\"0\",\"1.X\",\"2\"]")

        // should extract with {"root":{"array":{"separator":"|","item":{"array":{"separator":"."}}}}} from "#0|#1.X|#2" to [[\"#0\"],[\"#1\",\"X\"],[\"#2\"]]
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":{\"array\":{\"separator\":\".\"}}}}}", input: "#0|#1.X|#2", output: "[[\"#0\"],[\"#1\",\"X\"],[\"#2\"]]")

        // should extract with {"root":{"array":{"separator":"|","item":{"dictionary":{"name":{"has":"n:"}}}}}} from "n:0|n:1|n:2" to [{\"name\":\"n:0\"},{\"name\":\"n:1\"},{\"name\":\"n:2\"}]
        try test("{\"root\":{\"array\":{\"separator\":\"|\",\"item\":{\"dictionary\":{\"name\":{\"has\":\"n:\"}}}}}}", input: "n:0|n:1|n:2", output: "[{\"name\":\"n:0\"},{\"name\":\"n:1\"},{\"name\":\"n:2\"}]")
    }

    func testValue() throws {
        // should extract with {"root":{"slice":{"value":{"array":[null,false,1,1,"string",null],"bool":true,"dictionary":{"array":[null,false,1,1,"string",null],"bool":true,"int":5,"null":null,"number":5,"string":"string"},"int":5,"null":null,"number":5,"string":"string"}}}} from "ABC" to {\"array\":[null,false,1,1,\"string\",null],\"bool\":true,\"dictionary\":{\"array\":[null,false,1,1,\"string\",null],\"bool\":true,\"int\":5,\"null\":null,\"number\":5,\"string\":\"string\"},\"int\":5,\"null\":null,\"number\":5,\"string\":\"string\"}
        try test("{\"root\":{\"slice\":{\"value\":{\"array\":[null,false,1,1,\"string\",null],\"bool\":true,\"dictionary\":{\"array\":[null,false,1,1,\"string\",null],\"bool\":true,\"int\":5,\"null\":null,\"number\":5,\"string\":\"string\"},\"int\":5,\"null\":null,\"number\":5,\"string\":\"string\"}}}}", input: "ABC", output: "{\"array\":[null,false,1,1,\"string\",null],\"bool\":true,\"dictionary\":{\"array\":[null,false,1,1,\"string\",null],\"bool\":true,\"int\":5,\"null\":null,\"number\":5,\"string\":\"string\"},\"int\":5,\"null\":null,\"number\":5,\"string\":\"string\"}")
    }
}
