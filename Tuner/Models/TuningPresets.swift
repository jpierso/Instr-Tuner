import Foundation

/// Preset tunings for all supported instruments
enum TuningPresets {
    
    // MARK: - Chromatic (no strings, detects any note)
    
    static let chromatic = Instrument(
        type: .chromatic,
        name: "Chromatic",
        strings: [],
        isBuiltIn: true
    )
    
    // MARK: - Guitar (Standard E tuning: E2-A2-D3-G3-B3-E4)
    
    static let acousticGuitar = Instrument(
        type: .acousticGuitar,
        name: "Acoustic Guitar",
        strings: [
            StringTuning(note: .E, octave: 4),   // 1st string (highest)
            StringTuning(note: .B, octave: 3),   // 2nd string
            StringTuning(note: .G, octave: 3),   // 3rd string
            StringTuning(note: .D, octave: 3),   // 4th string
            StringTuning(note: .A, octave: 2),   // 5th string
            StringTuning(note: .E, octave: 2),   // 6th string (lowest)
        ],
        isBuiltIn: true
    )
    
    static let electricGuitar = Instrument(
        type: .electricGuitar,
        name: "Electric Guitar",
        strings: [
            StringTuning(note: .E, octave: 4),
            StringTuning(note: .B, octave: 3),
            StringTuning(note: .G, octave: 3),
            StringTuning(note: .D, octave: 3),
            StringTuning(note: .A, octave: 2),
            StringTuning(note: .E, octave: 2),
        ],
        isBuiltIn: true
    )
    
    // MARK: - Bass (Standard tuning: E1-A1-D2-G2)
    
    static let electricBass = Instrument(
        type: .electricBass,
        name: "Electric Bass",
        strings: [
            StringTuning(note: .G, octave: 2),   // 1st string (highest)
            StringTuning(note: .D, octave: 2),   // 2nd string
            StringTuning(note: .A, octave: 1),   // 3rd string
            StringTuning(note: .E, octave: 1),   // 4th string (lowest)
        ],
        isBuiltIn: true
    )
    
    // MARK: - Banjo (5-string, Open G: G4-D3-G3-B3-D4)
    
    static let banjo = Instrument(
        type: .banjo,
        name: "Banjo (5-string)",
        strings: [
            StringTuning(note: .D, octave: 4),   // 1st string
            StringTuning(note: .B, octave: 3),   // 2nd string
            StringTuning(note: .G, octave: 3),   // 3rd string
            StringTuning(note: .D, octave: 3),   // 4th string
            StringTuning(note: .G, octave: 4),   // 5th string (short string)
        ],
        isBuiltIn: true
    )
    
    // MARK: - Mandolin (Standard tuning: G3-D4-A4-E5)
    
    static let mandolin = Instrument(
        type: .mandolin,
        name: "Mandolin",
        strings: [
            StringTuning(note: .E, octave: 5),   // 1st course (highest)
            StringTuning(note: .A, octave: 4),   // 2nd course
            StringTuning(note: .D, octave: 4),   // 3rd course
            StringTuning(note: .G, octave: 3),   // 4th course (lowest)
        ],
        isBuiltIn: true
    )
    
    // MARK: - Violin (Standard tuning: G3-D4-A4-E5)
    
    static let violin = Instrument(
        type: .violin,
        name: "Violin",
        strings: [
            StringTuning(note: .E, octave: 5),   // 1st string (highest)
            StringTuning(note: .A, octave: 4),   // 2nd string
            StringTuning(note: .D, octave: 4),   // 3rd string
            StringTuning(note: .G, octave: 3),   // 4th string (lowest)
        ],
        isBuiltIn: true
    )
    
    // MARK: - All Presets
    
    static let allPresets: [Instrument] = [
        chromatic,
        acousticGuitar,
        electricGuitar,
        electricBass,
        banjo,
        mandolin,
        violin
    ]
    
    static func preset(for type: InstrumentType) -> Instrument {
        switch type {
        case .chromatic: return chromatic
        case .acousticGuitar: return acousticGuitar
        case .electricGuitar: return electricGuitar
        case .electricBass: return electricBass
        case .banjo: return banjo
        case .mandolin: return mandolin
        case .violin: return violin
        }
    }
}

/// Common reference pitch presets
enum ReferencePitchPreset: Double, CaseIterable, Identifiable {
    case baroque = 415.0        // Baroque pitch
    case verdi = 432.0          // "Verdi tuning"
    case standard = 440.0       // ISO standard
    case orchestraLow = 442.0   // Common European orchestral
    case orchestraHigh = 444.0  // Some orchestras
    
    var id: Double { rawValue }
    
    var displayName: String {
        switch self {
        case .baroque: return "A = 415 Hz (Baroque)"
        case .verdi: return "A = 432 Hz (Verdi)"
        case .standard: return "A = 440 Hz (Standard)"
        case .orchestraLow: return "A = 442 Hz (Orchestra)"
        case .orchestraHigh: return "A = 444 Hz (Orchestra+)"
        }
    }
    
    var shortName: String {
        return "A = \(Int(rawValue)) Hz"
    }
}
