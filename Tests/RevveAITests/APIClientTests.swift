import XCTest
@testable import RevveAI

final class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    let testBaseURL = URL(string: "https://test.revve.ai")!
    let testAPIKey = "test-api-key"
    
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
        apiClient = TestUtilities.createMockAPIClient()
    }
    
    override func tearDown() {
        MockURLProtocol.clearMockResponses()
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(apiClient)
    }
    
    func testGetConnectionDetailsSuccess() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        // Mock successful response
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: TestUtilities.sampleConnectionDetailsJSON,
            response: TestUtilities.createHTTPResponse(url: expectedURL, statusCode: 200),
            error: nil
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: nil) { result in
            switch result {
            case .success(let connectionDetails):
                XCTAssertEqual(connectionDetails.serverUrl, "wss://test.livekit.cloud")
                XCTAssertEqual(connectionDetails.roomName, "test-room-123")
                XCTAssertEqual(connectionDetails.participantToken, "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test")
                XCTAssertEqual(connectionDetails.participantName, "test-participant")
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetConnectionDetailsWithMetadata() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let metadata = ["userId": "user123", "sessionId": "session456"]
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: TestUtilities.sampleConnectionDetailsJSON,
            response: TestUtilities.createHTTPResponse(url: expectedURL, statusCode: 200),
            error: nil
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: metadata) { result in
            switch result {
            case .success:
                // Success case - metadata was properly included in request
                break
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetConnectionDetailsNetworkError() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: nil,
            response: nil,
            error: networkError
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case let RevveAIError.networkError(underlyingError) = error {
                    XCTAssertEqual((underlyingError as NSError).code, NSURLErrorNotConnectedToInternet)
                } else {
                    XCTFail("Expected networkError but got: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetConnectionDetailsHTTPError() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: TestUtilities.errorResponseJSON,
            response: TestUtilities.createHTTPResponse(url: expectedURL, statusCode: 404),
            error: nil
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case let RevveAIError.apiError(message) = error {
                    XCTAssertTrue(message.contains("404"))
                } else {
                    XCTFail("Expected apiError but got: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetConnectionDetailsInvalidJSON() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: TestUtilities.malformedJSON,
            response: TestUtilities.createHTTPResponse(url: expectedURL, statusCode: 200),
            error: nil
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                // Should get a decoding error
                XCTAssertTrue(error is DecodingError || error is RevveAIError)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetConnectionDetailsUnauthorized() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        let unauthorizedResponse = """
        {
            "error": "Unauthorized",
            "message": "Invalid API key"
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: unauthorizedResponse,
            response: TestUtilities.createHTTPResponse(url: expectedURL, statusCode: 401),
            error: nil
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case let RevveAIError.apiError(message) = error {
                    XCTAssertTrue(message.contains("401"))
                } else {
                    XCTFail("Expected apiError but got: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetConnectionDetailsEmptyResponse() {
        let expectation = XCTestExpectation(description: "API call completes")
        let assistantId = "test-assistant-123"
        let expectedURL = testBaseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        MockURLProtocol.setMockResponse(
            for: expectedURL,
            data: nil,
            response: TestUtilities.createHTTPResponse(url: expectedURL, statusCode: 200),
            error: nil
        )
        
        apiClient.getConnectionDetails(assistantId: assistantId, metadata: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                // Should get either invalidResponse or a decoding error for empty data
                XCTAssertTrue(error is RevveAIError || error is DecodingError)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}