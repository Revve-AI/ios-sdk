import Foundation

class APIClient {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: config)
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
                let callInfo = try decoder.decode(CallInfo.self, from: data)
                completion(.success(callInfo))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
