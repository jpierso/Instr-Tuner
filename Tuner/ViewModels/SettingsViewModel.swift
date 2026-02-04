import Foundation
import SwiftUI
import SwiftData

/// View model for settings-related functionality
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var referencePitch: Double = Constants.defaultReferencePitch
    @Published var noteOffsets: [Note: Double] = [:]
    @Published var selectedInstrumentType: InstrumentType = .chromatic
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Load settings from a model context
    func load(from context: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()
        
        if let settings = try? context.fetch(descriptor).first {
            referencePitch = settings.referencePitch
            noteOffsets = settings.noteOffsets
            
            if let type = InstrumentType(rawValue: settings.selectedInstrumentType) {
                selectedInstrumentType = type
            }
        }
    }
    
    /// Save settings to a model context
    func save(to context: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()
        
        let settings: UserSettings
        if let existing = try? context.fetch(descriptor).first {
            settings = existing
        } else {
            settings = UserSettings()
            context.insert(settings)
        }
        
        settings.referencePitch = referencePitch
        settings.noteOffsets = noteOffsets
        settings.selectedInstrumentType = selectedInstrumentType.rawValue
        
        try? context.save()
    }
    
    /// Reset reference pitch to standard
    func resetReferencePitch() {
        referencePitch = Constants.defaultReferencePitch
    }
    
    /// Reset all note offsets to zero
    func resetNoteOffsets() {
        noteOffsets = [:]
    }
    
    /// Set offset for a specific note
    func setOffset(_ offset: Double, for note: Note) {
        if offset == 0 {
            noteOffsets.removeValue(forKey: note)
        } else {
            noteOffsets[note] = offset
        }
    }
    
    /// Get offset for a specific note
    func offset(for note: Note) -> Double {
        return noteOffsets[note] ?? 0
    }
    
    /// Check if any custom offsets are set
    var hasCustomOffsets: Bool {
        !noteOffsets.isEmpty && noteOffsets.values.contains { $0 != 0 }
    }
}
