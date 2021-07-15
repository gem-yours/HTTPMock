import XCTest
import SwiftParamTest
@testable import HTTPMock

final class HTTPMockTests: XCTestCase {
    let untilTimeout: Double = 3
    let baseUrl = URL(string: "http://localhost/")!
    let payload =  "Response".data(using: .utf8)!


    func testMockingByMock() {
        let mock = request { (url, method, statusCode, httpVersion, headerFields, payload) in
            try! HTTPMock.default.mock(url: url, method: method, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields, payload: payload)
        }
        assert(to: mock, expect: [
            expect(testCase(url: baseUrl.appendingPathComponent("0"), method: "GET", statusCode: 200)),
            expect(testCase(url: baseUrl.appendingPathComponent("0"), method: "GET", statusCode: 200)),
            expect(testCase(url: baseUrl.appendingPathComponent("1"), method: "PUT", statusCode: 201)),
            expect(testCase(url: baseUrl.appendingPathComponent("2"), method: "GET", statusCode: 200, httpVersion: "HTTP/2")),
            expect(testCase(url: baseUrl.appendingPathComponent("3"), method: "PUT", statusCode: 200, headerFields: ["Content-Length": "0"])),
        ])
    }


    func testMockingByHandle() throws {
        let handle = request { (url, method, statusCode, httpVersion, headerFields, payload) in
            HTTPMock.default.handle({request in
                let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)!
                return (response, self.payload)
            })
        }

        assert(to: handle, expect: [
            expect(testCase(url: baseUrl.appendingPathComponent("0"), method: "GET", statusCode: 200)),
            expect(testCase(url: baseUrl.appendingPathComponent("0"), method: "GET", statusCode: 200)),
            expect(testCase(url: baseUrl.appendingPathComponent("1"), method: "PUT", statusCode: 201)),
            expect(testCase(url: baseUrl.appendingPathComponent("2"), method: "GET", statusCode: 200, httpVersion: "HTTP/2")),
            expect(testCase(url: baseUrl.appendingPathComponent("3"), method: "PUT", statusCode: 200, headerFields: ["Content-Length": "0"])),
        ])
    }


    func testMockTakesPrecedenceOverHandleWhenBothUsedAtSameTime() {
        let mockAndHandle = request { (url, method, statusCode, httpVersion, headerFields, payload) in
            try! HTTPMock.default.mock(url: url, method: method, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields, payload: payload)

            HTTPMock.default.handle({request in
                // fail test when using handle result,
                let response = HTTPURLResponse(url: self.baseUrl, statusCode: 0, httpVersion: "", headerFields: nil)!
                return (response, self.payload)
            })
        }
        assert(to: mockAndHandle, expect: [
            expect(testCase(url: baseUrl.appendingPathComponent("0"), method: "GET", statusCode: 200)),
            expect(testCase(url: baseUrl.appendingPathComponent("0"), method: "GET", statusCode: 200)),
            expect(testCase(url: baseUrl.appendingPathComponent("1"), method: "PUT", statusCode: 201)),
            expect(testCase(url: baseUrl.appendingPathComponent("2"), method: "GET", statusCode: 200, httpVersion: "HTTP/2")),
            expect(testCase(url: baseUrl.appendingPathComponent("3"), method: "PUT", statusCode: 200, headerFields: ["Content-Length": "0"])),
        ])

    }


    func request(_ mocking: @escaping (URL, String, Int, String, [String : String]?, Data?) -> Void) -> ((URL, String, Int, String, [String : String]?, Data?)) -> Response? {
        {  (arg) -> Response? in
            let (url, method, statusCode, httpVersion, headerFields, payload) = arg
            mocking(url, method, statusCode, httpVersion, headerFields, payload)

            let semaphore = DispatchSemaphore(value: 0)
            var result: Response?
            var request = URLRequest(url: url)
            request.httpMethod = method
            URLSession(configuration: HTTPMock.default.sessionConfiguration)
                .dataTask(with: request) { payload, response, error in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        return
                    }
                    result = Response(metadata: httpResponse, payload: payload)
                    semaphore.signal()
                }
                .resume()
            let timeoutResult = semaphore.wait(timeout: .now() + self.untilTimeout)
            switch timeoutResult {
                case .success:
                    return result
                case .timedOut:
                    return nil
            }
        }
    }


    func testCase(url: URL, method: String, statusCode: Int, httpVersion: String = "HTTP/1.1", headerFields: [String: String]? = nil) -> Row1<(URL, String, Int, String, [String: String]?, Data?), Response?> {
        (url, method, statusCode, httpVersion, headerFields, payload) ==>
            Response(metadata: HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)!, payload: payload)
    }
}


struct Response: Equatable {
    let metadata: HTTPURLResponse
    let payload: Data?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.payload == rhs.payload &&
            lhs.metadata.statusCode == rhs.metadata.statusCode &&
            NSDictionary(dictionary: lhs.metadata.allHeaderFields).isEqual(to: rhs.metadata.allHeaderFields) &&
            lhs.metadata.expectedContentLength == rhs.metadata.expectedContentLength &&
            lhs.metadata.textEncodingName == rhs.metadata.textEncodingName &&
            lhs.metadata.textEncodingName == rhs.metadata.textEncodingName &&
            lhs.metadata.url == rhs.metadata.url
    }
}
