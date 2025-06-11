import Foundation
import PipecatClientIOS
import PipecatClientIOSDaily
import RevveAI

@MainActor
class CallContainerModel: NSObject, ObservableObject, RTVIClientDelegate, RevveAIDelegate {
    // MARK: - RevveAI
    private var revveAI: RevveAI?
    
    @Published var voiceClientStatus: String = TransportState.disconnected.description
    @Published var isInCall: Bool = false
    @Published var isBotReady: Bool = false
    @Published var timerCount = 0
    
    @Published var isMicEnabled: Bool = false
    
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false
    
    @Published
    var remoteAudioLevel: Float = 0
    @Published
    var localAudioLevel: Float = 0
    
    private var meetingTimer: Timer?
    
    var rtviClientIOS: RTVIClient?
    
    @Published var selectedMic: MediaDeviceId? = nil {
        didSet {
            guard let selectedMic else { return } // don't store nil
            var settings = SettingsManager.getSettings()
            settings.selectedMic = selectedMic.id
            SettingsManager.updateSettings(settings: settings)
        }
    }
    @Published var availableMics: [MediaDeviceInfo] = []
    
    init() {
        // Changing the log level
        PipecatClientIOS.setLogLevel(.warn)
    }
    
    @MainActor
    func connect(assistantId: String) {
        let assistantId = assistantId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !assistantId.isEmpty else {
            self.showError(message: "Need to fill the assistantId. For more info visit: https://revve.ai")
            return
        }
        
        // Initialize RevveAI client
        revveAI = RevveAI(apiKey: "your-api-key-here") // Replace with actual API key
        revveAI?.delegate = self
        
        // Start the call
        revveAI?.start(assistantId: assistantId) { [weak self] result in
            switch result {
            case .success:
                // Call started successfully, delegate methods will handle the rest
                break
            case .failure(let error):
                self?.showError(message: error.localizedDescription)
            }
        }
        
        self.saveCredentials(assistantId: assistantId)
    }
    
    @MainActor
    func disconnect() {
        revveAI?.stop { [weak self] result in
            switch result {
            case .success:
                // Call ended successfully
                break
            case .failure(let error):
                self?.showError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - RevveAIDelegate
    
    func revveAIDidStartCall(_ revveAI: RevveAI) {
        // Handle call started
    }
    
    func revveAIDidEndCall(_ revveAI: RevveAI) {
        // Handle call ended
    }
    
    func revveAI(_ revveAI: RevveAI, didFailWithError error: Error) {
        showError(message: error.localizedDescription)
    }
    
    // MARK: - Error Handling
    
    func showError(message: String) {
        self.toastMessage = message
        self.showToast = true
        // Hide the toast after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showToast = false
            self.toastMessage = nil
        }
    }
    
    @MainActor
    func toggleMicInput() {
        self.rtviClientIOS?.enableMic(enable: !self.isMicEnabled) { result in
            switch result {
            case .success():
                self.isMicEnabled = self.rtviClientIOS?.isMicEnabled ?? false
            case .failure(let error):
                self.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func startTimer(withExpirationTime expirationTime: Int) {
        let currentTime = Int(Date().timeIntervalSince1970)
        self.timerCount = expirationTime - currentTime
        self.meetingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.timerCount -= 1
            }
        }
    }
    
    private func stopTimer() {
        self.meetingTimer?.invalidate()
        self.meetingTimer = nil
        self.timerCount = 0
    }
    
    func saveCredentials(backendURL: String) {
        var currentSettings = SettingsManager.getSettings()
        currentSettings.backendURL = backendURL
        // Saving the settings
        SettingsManager.updateSettings(settings: currentSettings)
    }
    
    @MainActor
    func selectMic(_ mic: MediaDeviceId) {
        self.selectedMic = mic
        self.rtviClientIOS?.updateMic(micId: mic, completion: nil)
    }
}

extension CallContainerModel:RTVIClientDelegate {
    
    private func handleEvent(eventName: String, eventValue: Any? = nil) {
        if let value = eventValue {
            print("RTVI Demo, received event:\(eventName), value:\(value)")
        } else {
            print("RTVI Demo, received event: \(eventName)")
        }
    }
    
    func onTransportStateChanged(state: TransportState) {
        Task { @MainActor in
            self.handleEvent(eventName: "onTransportStateChanged", eventValue: state)
            self.voiceClientStatus = state.description
            self.isInCall = ( state == .connecting || state == .connected || state == .ready || state == .authenticating )
        }
    }
    
    func onBotReady(botReadyData: BotReadyData) {
        Task { @MainActor in
            self.handleEvent(eventName: "onBotReady.")
            self.isBotReady = true
            if let expirationTime = self.rtviClientIOS?.expiry() {
                self.startTimer(withExpirationTime: expirationTime)
            }
        }
    }
    
    func onConnected() {
        Task { @MainActor in
            self.isMicEnabled = self.rtviClientIOS?.isMicEnabled ?? false
        }
    }
    
    func onDisconnected() {
        Task { @MainActor in
            self.stopTimer()
            self.isBotReady = false
        }
    }
    
    func onRemoteAudioLevel(level: Float, participant: Participant) {
        Task { @MainActor in
            self.remoteAudioLevel = level
        }
    }
    
    func onUserAudioLevel(level: Float) {
        Task { @MainActor in
            self.localAudioLevel = level
        }
    }
    
    func onUserTranscript(data: Transcript) {
        Task { @MainActor in
            if (data.final ?? false) {
                self.handleEvent(eventName: "onUserTranscript", eventValue: data.text)
            }
        }
    }
    
    func onBotTranscript(data: String) {
        Task { @MainActor in
            self.handleEvent(eventName: "onBotTranscript", eventValue: data)
        }
    }
    
    func onError(message: String) {
        Task { @MainActor in
            self.handleEvent(eventName: "onError", eventValue: message)
            self.showError(message: message)
        }
    }
    
    func onTracksUpdated(tracks: Tracks) {
        Task { @MainActor in
            self.handleEvent(eventName: "onTracksUpdated", eventValue: tracks)
        }
    }
    
    func onAvailableMicsUpdated(mics: [MediaDeviceInfo]) {
        Task { @MainActor in
            self.availableMics = mics
        }
    }
    
    func onMicUpdated(mic: MediaDeviceInfo?) {
        Task { @MainActor in
            self.selectedMic = mic?.id
        }
    }
}
