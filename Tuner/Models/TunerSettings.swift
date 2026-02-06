import Foundation
import SwiftData

// MARK: - Temperament Model

/// A named temperament preset with per-note offsets, associated with an instrument type
@Model
final class Temperament {
    var id: UUID
    var name: String                    // e.g., "Equal", "Just Intonation", "My Guitar Setup"
    var instrumentTypeRaw: String       // InstrumentType.rawValue
    var noteOffsetsData: Data           // Encoded [Int: Double] for Note rawValue to cents
    var isActive: Bool                  // Whether this is the active temperament for the instrument
    var createdAt: Date
    
    init(name: String, instrumentType: InstrumentType, noteOffsets: [Note: Double] = [:], isActive: Bool = false) {
        self.id = UUID()
        self.name = name
        self.instrumentTypeRaw = instrumentType.rawValue
        self.noteOffsetsData = Data()
        self.isActive = isActive
        self.createdAt = Date()
        self.noteOffsets = noteOffsets
    }
    
    /// The instrument type this temperament belongs to
    var instrumentType: InstrumentType {
        get { InstrumentType(rawValue: instrumentTypeRaw) ?? .chromatic }
        set { instrumentTypeRaw = newValue.rawValue }
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
    }
}

// MARK: - User Settings Model

/// User settings stored in SwiftData
@Model
final class UserSettings {
    var id: UUID
    var referencePitch: Double          // Default 440.0 Hz
    var selectedInstrumentType: String
    var sensitivity: Double             // 0.0 to 1.0, default 0.5
    var lastUpdated: Date
    
    // Legacy field - kept for migration, will be removed after migration
    var legacyNoteOffsetsData: Data?
    var migrationCompleted: Bool
    
    init() {
        self.id = UUID()
        self.referencePitch = 440.0
        self.selectedInstrumentType = InstrumentType.chromatic.rawValue
        self.sensitivity = Constants.defaultSensitivity
        self.lastUpdated = Date()
        self.legacyNoteOffsetsData = nil
        self.migrationCompleted = true
    }
    
    /// Legacy per-note cent offsets (for migration only)
    var legacyNoteOffsets: [Note: Double]? {
        get {
            guard let data = legacyNoteOffsetsData,
                  let decoded = try? JSONDecoder().decode([Int: Double].self, from: data) else {
                return nil
            }
            var result: [Note: Double] = [:]
            for (key, value) in decoded {
                if let note = Note(rawValue: key) {
                    result[note] = value
                }
            }
            return result.isEmpty ? nil : result
        }
    }
    
    /// Clear legacy data after migration
    func clearLegacyData() {
        legacyNoteOffsetsData = nil
        migrationCompleted = true
        lastUpdated = Date()
    }
}

// MARK: - In-Memory Settings Snapshot

/// In-memory tuner settings for the view model
struct TunerSettingsSnapshot {
    var referencePitch: Double = 440.0
    var noteOffsets: [Note: Double] = [:]
    var selectedInstrument: Instrument = TuningPresets.chromatic
    var activeTemperamentId: UUID?
    var activeTemperamentName: String?
    
    func offset(for note: Note) -> Double {
        return noteOffsets[note] ?? 0.0
    }
}
