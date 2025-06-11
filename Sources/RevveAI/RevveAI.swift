import Foundation
import AVFoundation
import PipecatClientIOS
import PipecatClientIOSDaily

public protocol RevveAIDelegate: AnyObject {
    func revveAIDidStartCall(_ revveAI: RevveAI)
    func revveAIDidEndCall(_ revveAI: RevveAI)
    func revveAI(_ revveAI: RevveAI, didFailWithError error: Error)
}

@MainActor
public class RevveAI {
    public weak var delegate: RevveAIDelegate?
    
    private let apiKey: String
    /// The base URL for API requests.
    /// Defaults to "https://app.revve.ai" if not specified during initialization.
    public let baseURL: URL
    private let apiClient: APIClient
    private var rtviClient: RTVIClient?
    private var isActive = false
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    
    /// Initialize RevveAI with your API key and optional custom base URL
    /// - Parameters:
    ///   - apiKey: Your RevveAI API key
    ///   - baseURL: Base URL for the API. Defaults to "https://app.revve.ai".
    ///     Use this to specify a custom hostname for development or testing environments.
    ///     Example: `URL(string: "http://localhost:3000")`
    /// - Note: The baseURL should include the scheme (http/https) and hostname,
    ///   but no trailing slash.
    public init(apiKey: String, baseURL: URL = URL(string: "https://app.revve.ai")!) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.apiClient = APIClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    /// Start a call with the specified assistant
    /// - Parameters:
    ///   - assistantId: The ID of the assistant to call
    ///   - metadata: Optional metadata to include with the call
    ///   - completion: Completion handler with the result of the operation
    public func start(assistantId: String, 
                    metadata: [String: String]? = nil, 
                    completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            // Request microphone permission
            requestMicrophonePermission { [weak self] granted in
                guard let self = self else { return }
                
                guard granted else {
                    completion(.failure(RevveAIError.callError("Microphone access is required")))
                    return
                }
                
                // Configure audio session
                self.configureAudioSession()
                
                // Initialize RTVIClient directly without API call
                self.initializeRTVIClient(assistantId: assistantId, completion: completion)
            }
        }
    }
    
    /// End the current call
    /// - Parameter completion: Completion handler called when the call has ended
    @MainActor
    public func stop(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard isActive else {
            completion?(.failure(RevveAIError.callError("No active call to end")))
            return
        }
        
        rtviClient?.disconnect(completion: { [weak self] _ in
            Task { @MainActor in
                await self?.cleanup()
                completion?(.success(()))
            }
        })
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func initializeRTVIClient(assistantId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Configure RTVIClient with the specified parameters
        let rtviClientParams = RTVIClientParams(
            baseUrl: baseURL.absoluteString,
            headers: [["Authorization": "Bearer \(apiKey)"]],
            endpoints: RTVIURLEndpoints(
                connect: "/api/voice-agents/\(assistantId)/web-calls",
                action: ""
            )
        )
        
        let rtviClientOptions = RTVIClientOptions(
            enableMic: true,
            enableCam: false,
            params: rtviClientParams,
            services: [:],
            config: nil,
            customHeaders: nil,
            customBodyParams: nil
        )
        
        let transport = DailyTransport(options: rtviClientOptions)
        let rtviClient = RTVIClient(
            baseUrl: baseURL.absoluteString,
            transport: transport,
            options: rtviClientOptions
        )
        
        self.rtviClient = rtviClient
        
        // Start the client
        Task { @MainActor in
            do {
                try await rtviClient.start()
                self.isActive = true
                self.delegate?.revveAIDidStartCall(self)
                completion(.success(()))
            } catch {
                await self.cleanup()
                self.delegate?.revveAI(self, didFailWithError: error)
                completion(.failure(error))
            }
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    @MainActor
    private func cleanup() async {
        isActive = false
        
        // Release the RTVIClient if it exists
        if let rtviClient = rtviClient {
            await rtviClient.release()
            self.rtviClient = nil
        }
        
        // Deactivate audio session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        // Notify delegate
        delegate?.revveAIDidEndCall(self)
    }
    
    deinit {
        // Since deinit cannot be async, we'll create a detached task to handle cleanup
        // but we can't wait for it to complete in deinit
        Task { @MainActor in
            await cleanup()
        }
    }
}
