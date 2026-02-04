import Foundation

/// App-wide constants
enum Constants {
    
    // MARK: - Audio
    
    /// Sample rate for audio processing
    static let sampleRate: Double = 44100.0
    
    /// Buffer size for audio processing (larger = more accurate, but more latency)
    static let bufferSize: Int = 4096
    
    /// Default minimum RMS level to consider as valid audio input
    static let defaultMinimumInputLevel: Float = 0.002
    
    /// Default confidence threshold for pitch detection (0-1)
    static let defaultConfidenceThreshold: Float = 0.6
    
    // MARK: - Sensitivity
    
    /// Sensitivity range (0.0 = least sensitive, 1.0 = most sensitive)
    static let minSensitivity: Double = 0.0
    static let maxSensitivity: Double = 1.0
    static let defaultSensitivity: Double = 0.5
    
    /// Maps sensitivity (0-1) to input level threshold
    /// Higher sensitivity = lower threshold = detects quieter sounds
    static func inputLevelThreshold(for sensitivity: Double) -> Float {
        // Sensitivity 0.0 -> threshold 0.02 (least sensitive)
        // Sensitivity 0.5 -> threshold 0.002 (default)
        // Sensitivity 1.0 -> threshold 0.0005 (most sensitive)
        let minThreshold: Float = 0.0005
        let maxThreshold: Float = 0.02
        let t = Float(1.0 - sensitivity)
        return minThreshold + (maxThreshold - minThreshold) * t * t
    }
    
    /// Maps sensitivity (0-1) to confidence threshold
    /// Higher sensitivity = lower confidence required
    static func confidenceThreshold(for sensitivity: Double) -> Float {
        // Sensitivity 0.0 -> confidence 0.85 (strict)
        // Sensitivity 0.5 -> confidence 0.6 (default)
        // Sensitivity 1.0 -> confidence 0.4 (lenient)
        let minConfidence: Float = 0.4
        let maxConfidence: Float = 0.85
        return maxConfidence - Float(sensitivity) * (maxConfidence - minConfidence)
    }
    
    // MARK: - Tuning
    
    /// Minimum reference pitch (A4)
    static let minimumReferencePitch: Double = 415.0
    
    /// Maximum reference pitch (A4)
    static let maximumReferencePitch: Double = 466.0
    
    /// Default reference pitch (A4)
    static let defaultReferencePitch: Double = 440.0
    
    /// Minimum cent offset
    static let minimumCentOffset: Double = -50.0
    
    /// Maximum cent offset
    static let maximumCentOffset: Double = 50.0
    
    /// Cents threshold for "in tune" indication
    static let inTuneThreshold: Double = 2.0
    
    /// Cents threshold for "close" indication
    static let closeThreshold: Double = 5.0
    
    // MARK: - UI
    
    /// Animation frame rate target
    static let targetFrameRate: Double = 60.0
    
    /// Strobe rotation factor (degrees per cent per frame)
    static let strobeRotationFactor: Double = 6.0
    
    /// Strobe smoothing factor (0-1, higher = smoother but slower response)
    static let strobeSmoothingFactor: Double = 0.3
    
    /// Input level meter smoothing
    static let levelMeterSmoothing: Float = 0.3
}
