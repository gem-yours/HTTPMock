import XCTest

import HTTPMockTests

var tests = [XCTestCaseEntry]()
tests += HTTPMockTests.allTests()
XCTMain(tests)
