import Foundation
import Accelerate

/// Result of pitch detection
struct PitchDetectionResult {
    let frequency: Double
    let confidence: Float
    let amplitude: Float
    
    /// Check validity with custom thresholds based on sensitivity
    func isValid(inputThreshold: Float, confidenceThreshold: Float) -> Bool {
        return frequency > 0 &&
               confidence >= confidenceThreshold &&
               amplitude >= inputThreshold
    }
    
    /// Default validity check using default sensitivity
    var isValid: Bool {
        return isValid(
            inputThreshold: Constants.inputLevelThreshold(for: Constants.defaultSensitivity),
            confidenceThreshold: Constants.confidenceThreshold(for: Constants.defaultSensitivity)
        )
    }
}

/// YIN pitch detection algorithm implementation
/// Reference: "YIN, a fundamental frequency estimator for speech and music"
/// by Alain de Cheveigné and Hideki Kawahara
final class PitchDetector {
    
    // MARK: - Properties
    
    private let sampleRate: Double
    private let bufferSize: Int
    private let threshold: Float
    
    // Pre-allocated buffers for YIN algorithm
    private var yinBuffer: [Float]
    private var differenceBuffer: [Float]
    
    // MARK: - Initialization
    
    init(sampleRate: Double = Constants.sampleRate,
         bufferSize: Int = Constants.bufferSize,
         threshold: Float = 0.15) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        self.threshold = threshold
        
        // YIN uses half the buffer size
        let halfBuffer = bufferSize / 2
        self.yinBuffer = [Float](repeating: 0, count: halfBuffer)
        self.differenceBuffer = [Float](repeating: 0, count: halfBuffer)
    }
    
    // MARK: - Public Methods
    
    /// Detect the fundamental frequency in an audio buffer
    /// - Parameters:
    ///   - buffer: Audio samples (mono, Float)
    ///   - inputThreshold: Minimum amplitude to process (based on sensitivity)
    /// - Returns: Detection result with frequency, confidence, and amplitude
    func detectPitch(in buffer: [Float], inputThreshold: Float = 0.002) -> PitchDetectionResult {
        guard buffer.count >= bufferSize else {
            return PitchDetectionResult(frequency: 0, confidence: 0, amplitude: 0)
        }
        
        // Calculate RMS amplitude
        let amplitude = calculateRMS(buffer)
        
        // Skip if signal is too quiet (use provided threshold)
        guard amplitude >= inputThreshold else {
            return PitchDetectionResult(frequency: 0, confidence: 0, amplitude: amplitude)
        }
        
        // Run YIN algorithm
        let (period, confidence) = runYIN(buffer)
        
        // Convert period to frequency
        let frequency: Double
        if period > 0 {
            frequency = sampleRate / Double(period)
        } else {
            frequency = 0
        }
        
        return PitchDetectionResult(
            frequency: frequency,
            confidence: confidence,
            amplitude: amplitude
        )
    }
    
    // MARK: - YIN Algorithm
    
    /// Run the YIN pitch detection algorithm
    /// - Parameter buffer: Audio samples
    /// - Returns: Tuple of (period in samples, confidence 0-1)
    private func runYIN(_ buffer: [Float]) -> (Float, Float) {
        let halfBuffer = bufferSize / 2
        
        // Step 1: Calculate difference function
        calculateDifference(buffer)
        
        // Step 2: Cumulative mean normalized difference
        cumulativeMeanNormalizedDifference()
        
        // Step 3: Absolute threshold
        var tau = 2
        while tau < halfBuffer {
            if yinBuffer[tau] < threshold {
                // Step 4: Parabolic interpolation for sub-sample accuracy
                while tau + 1 < halfBuffer && yinBuffer[tau + 1] < yinBuffer[tau] {
                    tau += 1
                }
                
                let betterTau = parabolicInterpolation(tau)
                let confidence = 1.0 - yinBuffer[tau]
                return (betterTau, confidence)
            }
            tau += 1
        }
        
        // No pitch found - find global minimum as fallback
        var minTau = 2
        var minValue: Float = yinBuffer[2]
        for i in 3..<halfBuffer {
            if yinBuffer[i] < minValue {
                minValue = yinBuffer[i]
                minTau = i
            }
        }
        
        let betterTau = parabolicInterpolation(minTau)
        let confidence = 1.0 - minValue
        
        // Only return if reasonably confident
        if confidence > 0.5 {
            return (betterTau, confidence)
        }
        
        return (0, 0)
    }
    
    /// Step 1: Calculate difference function
    private func calculateDifference(_ buffer: [Float]) {
        let halfBuffer = bufferSize / 2
        
        // Reset buffers
        for i in 0..<halfBuffer {
            differenceBuffer[i] = 0
        }
        
        // Calculate autocorrelation-based difference function
        for tau in 0..<halfBuffer {
            for i in 0..<halfBuffer {
                let delta = buffer[i] - buffer[i + tau]
                differenceBuffer[tau] += delta * delta
            }
        }
    }
    
    /// Step 2: Cumulative mean normalized difference function
    private func cumulativeMeanNormalizedDifference() {
        let halfBuffer = bufferSize / 2
        
        yinBuffer[0] = 1
        
        var runningSum: Float = 0
        
        for tau in 1..<halfBuffer {
            runningSum += differenceBuffer[tau]
            
            if runningSum != 0 {
                yinBuffer[tau] = differenceBuffer[tau] * Float(tau) / runningSum
            } else {
                yinBuffer[tau] = 1
            }
        }
    }
    
    /// Parabolic interpolation for sub-sample accuracy
    private func parabolicInterpolation(_ tau: Int) -> Float {
        let halfBuffer = bufferSize / 2
        
        guard tau > 0 && tau < halfBuffer - 1 else {
            return Float(tau)
        }
        
        let s0 = yinBuffer[tau - 1]
        let s1 = yinBuffer[tau]
        let s2 = yinBuffer[tau + 1]
        
        let adjustment = (s2 - s0) / (2.0 * (2.0 * s1 - s2 - s0))
        
        return Float(tau) + adjustment
    }
    
    // MARK: - Utilities
    
    /// Calculate RMS amplitude of buffer
    private func calculateRMS(_ buffer: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(buffer.count))
        return rms
    }
}
