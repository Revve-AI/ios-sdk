import Foundation

class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (Data?, URLResponse?, Error?)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let (data, response, error) = MockURLProtocol.mockResponses[url] else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockError", code: 0, userInfo: nil))
            return
        }
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        // Nothing to do
    }
    
    static func setMockResponse(for url: URL, data: Data?, response: URLResponse?, error: Error?) {
        mockResponses[url] = (data, response, error)
    }
    
    static func clearMockResponses() {
        mockResponses.removeAll()
    }
}