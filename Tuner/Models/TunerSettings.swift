import Foundation
import SwiftData

/// User settings stored in SwiftData
@Model
final class UserSettings {
    var id: UUID
    var referencePitch: Double  // Default 440.0 Hz
    var noteOffsetsData: Data   // Encoded [Int: Double] for Note rawValue to cents
    var selectedInstrumentType: String
    var sensitivity: Double     // 0.0 to 1.0, default 0.5
    var lastUpdated: Date
    
    init() {
        self.id = UUID()
        self.referencePitch = 440.0
        self.noteOffsetsData = Data()
        self.selectedInstrumentType = InstrumentType.chromatic.rawValue
        self.sensitivity = Constants.defaultSensitivity
        self.lastUpdated = Date()
    }
    
    /// Per-note cent offsets
    var noteOffsets: [Note: Double] {
        get {
            guard let decoded = try? JSONDecoder().decode([Int: Double].self, from: noteOffsetsData) else {
                return [:]
            }
            var result: [Note: Double] = [:]
            for (key, value) in decoded {
                if let note = Note(rawValue: key) {
                    result[note] = value
                }
            }
            return result
        }
        set {
            var encoded: [Int: Double] = [:]
            for (note, value) in newValue {
                encoded[note.rawValue] = value
            }
            noteOffsetsData = (try? JSONEncoder().encode(encoded)) ?? Data()
            lastUpdated = Date()
        }
    }
    
    /// Get offset for a specific note
    func offset(for note: Note) -> Double {
        return noteOffsets[note] ?? 0.0
    }
    
    /// Set offset for a specific note
    func setOffset(_ offset: Double, for note: Note) {
        var offsets = noteOffsets
        offsets[note] = offset
        noteOffsets = offsets
    }
    
    /// Reset all offsets to zero
    func resetOffsets() {
        noteOffsetsData = Data()
        lastUpdated = Date()
    }
}

/// In-memory tuner settings for the view model
struct TunerSettingsSnapshot {
    var referencePitch: Double = 440.0
    var noteOffsets: [Note: Double] = [:]
    var selectedInstrument: Instrument = TuningPresets.chromatic
    
    func offset(for note: Note) -> Double {
        return noteOffsets[note] ?? 0.0
    }
}
