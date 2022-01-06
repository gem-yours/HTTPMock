HTTPMock is a simple HTTP request mocking library.


- [QuickStart](#quickstart)
- [Install](#install)


# Quickstart
 change response like this
``` swift
try HTTPMock.default.mock(url: URL(string: "http://localhost/")!, statusCode: 500, httpVersion: "HTTP/2", headerFields: ["Cache-control": "no-store"], payload: "response".data(using: .utf8))
    }
```
 or
``` swift
 HTTPMock.default.handle({request in
    let response = HTTPURLResponse(url: URL(string: "http://localhost/")!, statusCode: 200, httpVersion: "HTTP/2", headerFields: ["Cache-control": "no-store"])!
    return (response, "response".data(using: .utf8))
})
```
then request by following code
``` swift
URLSession(configuration: HTTPMock.defausessionConfiguration)
    .dataTask(with: request) { payload, response, error in
        // something
    }
    .resume()

```


# install
- swift Package Manager
``` swift 
dependencies: [
    .package(url: "https://github.com/gem-yours/HTTPMock.git", .upToNextMajor(from: "1.0.0"))
]
```