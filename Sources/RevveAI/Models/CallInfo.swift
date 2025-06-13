import Foundation

public struct CallInfo: Decodable {
    /// The URL of the room to connect to
    public let roomUrl: String
    
    /// The authentication token for the room
    public let token: String
    
    private enum CodingKeys: String, CodingKey {
        case roomUrl = "room_url"
        case token
    }
}

public struct ConnectionDetails: Decodable {
    /// The LiveKit server URL
    public let serverUrl: String
    
    /// The room name to join
    public let roomName: String
    
    /// The participant token for authentication
    public let participantToken: String
    
    /// The participant name/identity
    public let participantName: String
}

public enum RevveAIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case callError(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Received invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .callError(let message):
            return "Call error: \(message)"
        }
    }
}
