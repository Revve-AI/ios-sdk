import Foundation

class APIClient {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    
    init(apiKey: String, baseURL: URL, session: URLSession? = nil) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json"
            ]
            self.session = URLSession(configuration: config)
        }
    }
    
    func createCall(assistantId: String,
                   metadata: [String: String]?,
                   completion: @escaping (Result<CallInfo, Error>) -> Void) {
        
        let url = baseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("inbound-web-calls")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add metadata to request body if provided
        if let metadata = metadata, !metadata.isEmpty {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: ["metadata": metadata], options: [])
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(RevveAIError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(RevveAIError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusCode = httpResponse.statusCode
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(RevveAIError.apiError("Status code: \(statusCode), message: \(errorMessage)")))
                return
            }
            
            guard let data = data else {
                completion(.failure(RevveAIError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // Log the raw JSON string for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[RevveAI] Raw server response: \(jsonString)")
                }
                
                let callInfo = try decoder.decode(CallInfo.self, from: data)
                
                // Log the parsed CallInfo
                print("[RevveAI] Parsed CallInfo:")
                print("  - Room URL: \(callInfo.roomUrl)")
                print("  - Token: \(callInfo.token)")
                
                completion(.success(callInfo))
            } catch {
                print("[RevveAI] Failed to decode response: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func getConnectionDetails(assistantId: String,
                             metadata: [String: String]?,
                             completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        
        let url = baseURL
            .appendingPathComponent("api/voice-agents")
            .appendingPathComponent(assistantId)
            .appendingPathComponent("web-calls")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add metadata to request body if provided
        if let metadata = metadata, !metadata.isEmpty {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: ["metadata": metadata], options: [])
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(RevveAIError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(RevveAIError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusCode = httpResponse.statusCode
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(RevveAIError.apiError("Status code: \(statusCode), message: \(errorMessage)")))
                return
            }
            
            guard let data = data else {
                completion(.failure(RevveAIError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // Log the raw JSON string for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[RevveAI] Raw server response: \(jsonString)")
                }
                
                let connectionDetails = try decoder.decode(ConnectionDetails.self, from: data)
                
                // Log the parsed ConnectionDetails
                print("[RevveAI] Parsed ConnectionDetails:")
                print("  - Server URL: \(connectionDetails.serverUrl)")
                print("  - Room Name: \(connectionDetails.roomName)")
                print("  - Participant Token: \(connectionDetails.participantToken)")
                print("  - Participant Name: \(connectionDetails.participantName)")
                
                completion(.success(connectionDetails))
            } catch {
                print("[RevveAI] Failed to decode response: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
