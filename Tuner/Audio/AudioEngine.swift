import AVFoundation
import Combine
import Accelerate

/// Represents the current tuning state
struct TuningState {
    let frequency: Double
    let pitch: Pitch
    let cents: Double
    let confidence: Float
    let amplitude: Float
    let isValid: Bool
    
    static let empty = TuningState(
        frequency: 0,
        pitch: Pitch(note: .A, octave: 4),
        cents: 0,
        confidence: 0,
        amplitude: 0,
        isValid: false
    )
}

/// Audio engine that captures microphone input and performs pitch detection
final class AudioEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var tuningState: TuningState = .empty
    @Published private(set) var inputLevel: Float = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var error: AudioEngineError?
    
    // MARK: - Properties
    
    private let engine = AVAudioEngine()
    private var pitchDetector: PitchDetector!
    private let sessionManager = AudioSessionManager.shared
    
    private var referencePitch: Double = Constants.defaultReferencePitch
    private var noteOffsets: [Note: Double] = [:]
    private var sensitivity: Double = Constants.defaultSensitivity
    
    // Computed thresholds based on sensitivity
    private var inputThreshold: Float {
        Constants.inputLevelThreshold(for: sensitivity)
    }
    
    private var confidenceThreshold: Float {
        Constants.confidenceThreshold(for: sensitivity)
    }
    
    // Buffer for accumulating samples
    private var sampleBuffer: [Float] = []
    private let bufferSize = Constants.bufferSize
    
    // Smoothing for display
    private var smoothedLevel: Float = 0
    
    // MARK: - Initialization
    
    init() {
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start the audio engine
    func start() {
        guard !isRunning else { return }
        
        // Request permission first
        sessionManager.requestPermission { [weak self] granted in
            guard granted else {
                self?.error = .permissionDenied
                return
            }
            
            self?.startEngine()
        }
    }
    
    /// Stop the audio engine
    func stop() {
        guard isRunning else { return }
        
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        
        isRunning = false
        tuningState = .empty
        inputLevel = 0
    }
    
    /// Update the reference pitch
    func setReferencePitch(_ pitch: Double) {
        self.referencePitch = pitch
    }
    
    /// Update note offsets
    func setNoteOffsets(_ offsets: [Note: Double]) {
        self.noteOffsets = offsets
    }
    
    /// Update sensitivity (0.0 to 1.0)
    func setSensitivity(_ value: Double) {
        self.sensitivity = max(0, min(1, value))
    }
    
    // MARK: - Private Methods
    
    private func startEngine() {
        do {
            // Configure audio session
            try sessionManager.configure()
            
            // Set up audio tap
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            print("Requested sampleRate:", Constants.sampleRate)
            print("Session sampleRate:", sessionManager.sampleRate)
            print("Input node sampleRate:", format.sampleRate)
            
            // Initialize pitch detector with the actual hardware sample rate
            self.pitchDetector = PitchDetector(
                sampleRate: format.sampleRate,
                bufferSize: Constants.bufferSize
            )
            
            // Verify format
            guard format.sampleRate > 0 else {
                error = .invalidFormat
                return
            }
            
            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }
            
            // Start the engine
            try engine.start()
            
            isRunning = true
            error = nil
            
            // Set up interruption handling
            sessionManager.setupInterruptionHandling(
                onInterruption: { [weak self] in
                    self?.stop()
                },
                onResume: { [weak self] in
                    self?.start()
                }
            )
            
        } catch {
            self.error = .engineStartFailed(error)
            print("Audio engine start failed: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // Accumulate samples
        sampleBuffer.append(contentsOf: samples)
        
        // Process when we have enough samples
        while sampleBuffer.count >= bufferSize {
            let processingBuffer = Array(sampleBuffer.prefix(bufferSize))
            sampleBuffer.removeFirst(bufferSize)
            
            // Detect pitch with current sensitivity threshold
            let result = pitchDetector.detectPitch(in: processingBuffer, inputThreshold: inputThreshold)
            
            // Update on main thread
            DispatchQueue.main.async { [weak self] in
                self?.updateState(with: result)
            }
        }
        
        // Update input level (smoothed)
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.smoothedLevel = self.smoothedLevel * Constants.levelMeterSmoothing +
                                 rms * (1 - Constants.levelMeterSmoothing)
            self.inputLevel = self.smoothedLevel
        }
    }
    
    private func updateState(with result: PitchDetectionResult) {
        guard result.isValid(inputThreshold: inputThreshold, confidenceThreshold: confidenceThreshold) else {
            tuningState = TuningState(
                frequency: 0,
                pitch: tuningState.pitch,
                cents: 0,
                confidence: result.confidence,
                amplitude: result.amplitude,
                isValid: false
            )
            return
        }
        
        // Get nearest pitch and cents
        let (pitch, baseCents) = TuningMath.nearestPitch(
            to: result.frequency,
            referencePitch: referencePitch
        )
        
        // Apply note offset
        let noteOffset = noteOffsets[pitch.note] ?? 0
        let adjustedCents = baseCents - noteOffset
        
        tuningState = TuningState(
            frequency: result.frequency,
            pitch: pitch,
            cents: adjustedCents,
            confidence: result.confidence,
            amplitude: result.amplitude,
            isValid: true
        )
    }
}

// MARK: - Error Types

enum AudioEngineError: Error, LocalizedError {
    case permissionDenied
    case invalidFormat
    case engineStartFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required for the tuner to work."
        case .invalidFormat:
            return "Audio format is not supported."
        case .engineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        }
    }
}

