import Foundation

/// Represents the 12 notes in Western music
enum Note: Int, CaseIterable, Codable, Identifiable {
    case C = 0
    case CSharp = 1
    case D = 2
    case DSharp = 3
    case E = 4
    case F = 5
    case FSharp = 6
    case G = 7
    case GSharp = 8
    case A = 9
    case ASharp = 10
    case B = 11
    
    var id: Int { rawValue }
    
    /// Display name for the note
    var displayName: String {
        switch self {
        case .C: return "C"
        case .CSharp: return "C♯"
        case .D: return "D"
        case .DSharp: return "D♯"
        case .E: return "E"
        case .F: return "F"
        case .FSharp: return "F♯"
        case .G: return "G"
        case .GSharp: return "G♯"
        case .A: return "A"
        case .ASharp: return "A♯"
        case .B: return "B"
        }
    }
    
    /// Alternate display name using flats
    var flatName: String {
        switch self {
        case .C: return "C"
        case .CSharp: return "D♭"
        case .D: return "D"
        case .DSharp: return "E♭"
        case .E: return "E"
        case .F: return "F"
        case .FSharp: return "G♭"
        case .G: return "G"
        case .GSharp: return "A♭"
        case .A: return "A"
        case .ASharp: return "B♭"
        case .B: return "B"
        }
    }
    
    /// Simple name without accidentals for settings
    var settingsName: String {
        switch self {
        case .C: return "C"
        case .CSharp: return "C#/Db"
        case .D: return "D"
        case .DSharp: return "D#/Eb"
        case .E: return "E"
        case .F: return "F"
        case .FSharp: return "F#/Gb"
        case .G: return "G"
        case .GSharp: return "G#/Ab"
        case .A: return "A"
        case .ASharp: return "A#/Bb"
        case .B: return "B"
        }
    }
}

/// Represents a specific pitch (note + octave)
struct Pitch: Equatable, Codable, Hashable {
    let note: Note
    let octave: Int
    
    /// MIDI note number (A4 = 69)
    var midiNote: Int {
        return (octave + 1) * 12 + note.rawValue
    }
    
    /// Display string like "A4" or "C#3"
    var displayName: String {
        return "\(note.displayName)\(octave)"
    }
    
    /// Create a pitch from a MIDI note number
    static func fromMIDI(_ midiNote: Int) -> Pitch {
        let octave = (midiNote / 12) - 1
        let noteIndex = midiNote % 12
        return Pitch(note: Note(rawValue: noteIndex) ?? .C, octave: octave)
    }
}

/// Represents a string tuning with optional cent offset
struct StringTuning: Codable, Identifiable, Hashable {
    let id: UUID
    let pitch: Pitch
    var centOffset: Double  // User adjustment -50 to +50
    
    init(pitch: Pitch, centOffset: Double = 0) {
        self.id = UUID()
        self.pitch = pitch
        self.centOffset = centOffset
    }
    
    init(note: Note, octave: Int, centOffset: Double = 0) {
        self.id = UUID()
        self.pitch = Pitch(note: note, octave: octave)
        self.centOffset = centOffset
    }
}
