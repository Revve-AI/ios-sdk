import Foundation
@testable import RevveAI

struct TestUtilities {
    static let sampleConnectionDetails = ConnectionDetails(
        serverUrl: "wss://test.livekit.cloud",
        roomName: "test-room-123",
        participantToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test",
        participantName: "test-participant"
    )
    
    static let sampleConnectionDetailsJSON = """
    {
        "server_url": "wss://test.livekit.cloud",
        "room_name": "test-room-123",
        "participant_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test",
        "participant_name": "test-participant"
    }
    """.data(using: .utf8)!
    
    static let malformedJSON = """
    {
        "server_url": "wss://test.livekit.cloud",
        "missing_required_field": true
    }
    """.data(using: .utf8)!
    
    static let errorResponseJSON = """
    {
        "error": "Assistant not found",
        "code": 404
    }
    """.data(using: .utf8)!
    
    static func createHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
    
    static func createMockAPIClient() -> APIClient {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        
        return APIClient(
            apiKey: "test-key", 
            baseURL: URL(string: "https://test.revve.ai")!, 
            session: mockSession
        )
    }
}