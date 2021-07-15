import Foundation



public class HTTPMock {
    static let `default` = HTTPMock()

    private var responses = [URL: [String: (HTTPURLResponse, Data?)]]()
    private var handler: ((URLRequest) throws -> (HTTPURLResponse, Data?))? = nil

    /// Pass this configuration to URLSession for mocking URLSession
    public var sessionConfiguration: URLSessionConfiguration {
        get {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [URLProtocolMock.self]
            return configuration
        }
    }

    /// Determine mock behavior by given parameters.
    /// This method initialized HTTPURLResponse.
    /// - Parameters:
    ///   - url: request url
    ///   - method: http method; name must be uppercase letter
    ///   - statusCode: http response code
    ///   - httpVersion: http version
    ///   - headerFields: response header
    ///   - payload: resposne payload
    /// - Throws: When failed to initialized HTTPURLResponse, throw fatalError
    public func mock(url: URL, method: String = "GET", statusCode: Int = 200, httpVersion: String = "HTTP/1.1", headerFields: [String: String]? = nil, payload: Data? = nil) throws {
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields) else {
            fatalError("Cannot initialize HTTPURLResponse given parameters.")
        }
        if responses[url] == nil {
            responses[url] = [String: (HTTPURLResponse, Data?)]()
        }
        responses[url]?[method] = (response, payload)
    }

    /// Determine mock behavior of any requests.
    /// This handler doesn't take precedence over the mock method.
    /// - Parameter handler: get any request and return response
    public func handle(_ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data?)) {
        self.handler = handler
    }

    /// Reset mock behavior.
    public func reset() {
        responses = [URL: [String: (HTTPURLResponse, Data?)]]()
        handler = nil
    }

    private init() {
        URLProtocolMock.requestHandler = { [weak self] request in
            if let url = request.url, let method = request.httpMethod,
               let responsesForUrl = self?.responses[url],
               let response = responsesForUrl[method] {
                return (response.0, response.1)
            }
            if let handler = self?.handler {
                return try handler(request)
            }
            return (HTTPURLResponse(), nil as Data?)
        }
    }
}


/// mock http request via URLProtocol
public class URLProtocolMock: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    public override func startLoading() {
        guard let handler = URLProtocolMock.requestHandler else {
            return
        }

        guard let client = client else {
            return
        }

        do {
            let (response, data) = try handler(request)
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client.urlProtocol(self, didLoad: data)
            }

            client.urlProtocolDidFinishLoading(self)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }
    }

    public override func stopLoading() {

    }

    public override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
}
