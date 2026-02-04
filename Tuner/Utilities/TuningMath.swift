import Foundation

/// Mathematical utilities for tuning calculations
enum TuningMath {
    
    // MARK: - Constants
    
    /// Standard reference pitch (A4)
    static let standardA4: Double = 440.0
    
    /// MIDI note number for A4
    static let a4MidiNote: Int = 69
    
    /// Number of cents per octave
    static let centsPerOctave: Double = 1200.0
    
    /// Number of semitones per octave
    static let semitonesPerOctave: Int = 12
    
    // MARK: - Frequency Calculations
    
    /// Calculate the frequency of a pitch given a reference pitch for A4
    /// - Parameters:
    ///   - pitch: The target pitch
    ///   - referencePitch: The reference frequency for A4 (default 440 Hz)
    /// - Returns: The frequency in Hz
    static func frequency(for pitch: Pitch, referencePitch: Double = standardA4) -> Double {
        let midiNote = pitch.midiNote
        let semitoneDistance = Double(midiNote - a4MidiNote)
        return referencePitch * pow(2.0, semitoneDistance / 12.0)
    }
    
    /// Calculate the frequency of a note at a given octave
    /// - Parameters:
    ///   - note: The note
    ///   - octave: The octave number
    ///   - referencePitch: The reference frequency for A4
    /// - Returns: The frequency in Hz
    static func frequency(note: Note, octave: Int, referencePitch: Double = standardA4) -> Double {
        return frequency(for: Pitch(note: note, octave: octave), referencePitch: referencePitch)
    }
    
    // MARK: - Pitch Detection
    
    /// Detect the nearest pitch to a given frequency
    /// - Parameters:
    ///   - frequency: The detected frequency in Hz
    ///   - referencePitch: The reference frequency for A4
    /// - Returns: A tuple containing the nearest pitch and the cents deviation
    static func nearestPitch(to frequency: Double, referencePitch: Double = standardA4) -> (pitch: Pitch, cents: Double) {
        guard frequency > 0 else {
            return (Pitch(note: .A, octave: 4), 0)
        }
        
        // Calculate semitones from A4
        let semitones = 12.0 * log2(frequency / referencePitch)
        
        // Round to nearest semitone to get MIDI note
        let roundedSemitones = round(semitones)
        let midiNote = Int(roundedSemitones) + a4MidiNote
        
        // Calculate cents deviation
        let cents = (semitones - roundedSemitones) * 100.0
        
        // Convert MIDI note to pitch
        let pitch = Pitch.fromMIDI(midiNote)
        
        return (pitch, cents)
    }
    
    /// Calculate cents deviation between a detected frequency and a target frequency
    /// - Parameters:
    ///   - detected: The detected frequency in Hz
    ///   - target: The target frequency in Hz
    /// - Returns: The deviation in cents (positive = sharp, negative = flat)
    static func cents(detected: Double, target: Double) -> Double {
        guard detected > 0 && target > 0 else { return 0 }
        return centsPerOctave * log2(detected / target)
    }
    
    /// Calculate cents deviation from a target pitch
    /// - Parameters:
    ///   - frequency: The detected frequency in Hz
    ///   - targetPitch: The target pitch
    ///   - referencePitch: The reference frequency for A4
    ///   - noteOffset: Additional cent offset for the note
    /// - Returns: The deviation in cents (positive = sharp, negative = flat)
    static func cents(
        frequency: Double,
        targetPitch: Pitch,
        referencePitch: Double = standardA4,
        noteOffset: Double = 0
    ) -> Double {
        let targetFrequency = self.frequency(for: targetPitch, referencePitch: referencePitch)
        let adjustedTarget = targetFrequency * pow(2.0, noteOffset / centsPerOctave)
        return cents(detected: frequency, target: adjustedTarget)
    }
    
    // MARK: - Validation
    
    /// Check if a frequency is within the audible/tunable range
    /// - Parameter frequency: The frequency to check
    /// - Returns: True if the frequency is valid for tuning
    static func isValidFrequency(_ frequency: Double) -> Bool {
        // Reasonable range for stringed instruments: ~20 Hz to ~5000 Hz
        return frequency >= 20.0 && frequency <= 5000.0
    }
    
    /// Check if the detected pitch is close to a target pitch
    /// - Parameters:
    ///   - detected: The detected pitch
    ///   - target: The target pitch
    ///   - tolerance: Maximum semitone distance (default 1)
    /// - Returns: True if within tolerance
    static func isNearTarget(detected: Pitch, target: Pitch, tolerance: Int = 1) -> Bool {
        return abs(detected.midiNote - target.midiNote) <= tolerance
    }
    
    // MARK: - Display Helpers
    
    /// Format cents deviation for display
    /// - Parameter cents: The cents value
    /// - Returns: A formatted string like "+5" or "-12"
    static func formatCents(_ cents: Double) -> String {
        let rounded = Int(round(cents))
        if rounded > 0 {
            return "+\(rounded)"
        } else {
            return "\(rounded)"
        }
    }
    
    /// Format frequency for display
    /// - Parameter frequency: The frequency in Hz
    /// - Returns: A formatted string like "440.0 Hz"
    static func formatFrequency(_ frequency: Double) -> String {
        return String(format: "%.1f Hz", frequency)
    }
}
