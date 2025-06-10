import Foundation

public struct CallInfo: Decodable {
    public let id: String
    public let orgId: String
    public let type: String
    public let transport: TransportInfo
    public let webCallUrl: String
    public let status: String
    public let assistantId: String
    public let createdAt: String
    public let updatedAt: String
    
    public struct TransportInfo: Decodable {
        public let provider: String
        public let assistantVideoEnabled: Bool
        public let callUrl: String
    }
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
