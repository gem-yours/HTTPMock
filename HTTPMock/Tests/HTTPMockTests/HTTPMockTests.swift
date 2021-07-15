import XCTest
@testable import HTTPMock

final class HTTPMockTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HTTPMock().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
