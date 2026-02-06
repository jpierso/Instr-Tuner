import Foundation
import SwiftData

/// Built-in instrument types
enum InstrumentType: String, CaseIterable, Codable, Identifiable {
    case acousticGuitar = "Acoustic Guitar"
    case electricGuitar = "Electric Guitar"
    case electricBass = "Electric Bass"
    case banjo = "Banjo"
    case mandolin = "Mandolin"
    case violin = "Violin"
    case pedalSteel = "Pedal Steel"
    case chromatic = "Chromatic"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .acousticGuitar, .electricGuitar:
            return "guitars"
        case .electricBass:
            return "guitars.fill"
        case .banjo:
            return "circle.grid.3x3"
        case .mandolin:
            return "music.note"
        case .violin:
            return "music.quarternote.3"
        case .pedalSteel:
            return "slider.horizontal.3"
        case .chromatic:
            return "waveform"
        }
    }
}

/// Represents an instrument configuration
struct Instrument: Identifiable, Codable {
    let id: UUID
    let type: InstrumentType
    let name: String
    var strings: [StringTuning]
    let isBuiltIn: Bool
    
    init(type: InstrumentType, name: String, strings: [StringTuning], isBuiltIn: Bool = true) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.strings = strings
        self.isBuiltIn = isBuiltIn
    }
}

/// Custom instrument stored in SwiftData
@Model
final class CustomInstrument {
    var id: UUID
    var name: String
    var stringsData: Data  // Encoded [StringTuning]
    var createdAt: Date
    
    init(name: String, strings: [StringTuning]) {
        self.id = UUID()
        self.name = name
        self.stringsData = (try? JSONEncoder().encode(strings)) ?? Data()
        self.createdAt = Date()
    }
    
    var strings: [StringTuning] {
        get {
            (try? JSONDecoder().decode([StringTuning].self, from: stringsData)) ?? []
        }
        set {
            stringsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    func toInstrument() -> Instrument {
        Instrument(
            type: .chromatic,
            name: name,
            strings: strings,
            isBuiltIn: false
        )
    }
}
