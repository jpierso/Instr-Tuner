import AVFoundation

/// Manages the AVAudioSession configuration for the tuner
final class AudioSessionManager {
    
    // MARK: - Singleton
    
    static let shared = AudioSessionManager()
    
    // MARK: - Properties
    
    private let session = AVAudioSession.sharedInstance()
    
    var isConfigured: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Configure the audio session for tuning
    /// - Throws: Audio session configuration errors
    func configure() throws {
        // Set category favoring ambient pickup (less restrictive processing than .measurement)
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker]
        )
        
        // Prefer the built-in microphone for ambient capture when available
        if let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            try? session.setPreferredInput(builtInMic)
        }
        
        // On supported systems, prefer an omnidirectional polar pattern for ambient sound
        if session.isInputGainSettable {
            // Avoid extreme gain; system manages AGC. Leave as-is or set a moderate value if needed.
        }
        
        // Request buffer duration; can be tuned. Low values reduce latency but aren't required for ambient pickup.
        try session.setPreferredIOBufferDuration(0.005) // 5ms
        
        // Request preferred sample rate
        try session.setPreferredSampleRate(Constants.sampleRate)
        
        // Activate the session
        try session.setActive(true)
        
        // Prefer omnidirectional data source (if supported) for broader ambient capture
        if let input = session.inputDataSources?.first(where: { $0.supportedPolarPatterns?.contains(.omnidirectional) == true }) {
            try? input.setPreferredPolarPattern(.omnidirectional)
            try? session.setInputDataSource(input)
        }
        
        isConfigured = true
        
        // Log actual settings
        print("Audio Session configured:")
        print("  Sample Rate: \(session.sampleRate) Hz")
        print("  IO Buffer Duration: \(session.ioBufferDuration * 1000) ms")
        print("  Input Channels: \(session.inputNumberOfChannels)")
    }
    
    /// Deactivate the audio session
    func deactivate() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            isConfigured = false
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    /// Request microphone permission
    /// - Parameter completion: Called with the permission result
    func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            @unknown default:
                completion(false)
            }
        } else {
            switch session.recordPermission {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                session.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            @unknown default:
                completion(false)
            }
        }
    }
    
    /// Check if microphone permission is granted
    var hasPermission: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return session.recordPermission == .granted
        }
    }
    
    /// Get the current sample rate
    var sampleRate: Double {
        return session.sampleRate
    }
    
    // MARK: - Interruption Handling
    
    /// Set up interruption observers
    func setupInterruptionHandling(
        onInterruption: @escaping () -> Void,
        onResume: @escaping () -> Void
    ) {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                onInterruption()
            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        onResume()
                    }
                }
            @unknown default:
                break
            }
        }
    }
}

