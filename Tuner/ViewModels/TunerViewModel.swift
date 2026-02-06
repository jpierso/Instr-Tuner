import Foundation
import SwiftUI
import SwiftData
import Combine

/// Main view model for the tuner
@MainActor
final class TunerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Tuning state
    @Published private(set) var frequency: Double = 0
    @Published private(set) var pitch: Pitch = Pitch(note: .A, octave: 4)
    @Published private(set) var cents: Double = 0
    @Published private(set) var isValid: Bool = false
    @Published private(set) var inputLevel: Float = 0
    
    // Settings
    @Published var referencePitch: Double = Constants.defaultReferencePitch {
        didSet {
            audioEngine.setReferencePitch(referencePitch)
            saveSettings()
        }
    }
    
    @Published var noteOffsets: [Note: Double] = [:] {
        didSet {
            audioEngine.setNoteOffsets(noteOffsets)
        }
    }
    
    @Published var selectedInstrument: Instrument = TuningPresets.chromatic {
        didSet {
            // Load the active temperament for the new instrument
            if let context = modelContext {
                loadActiveTemperament(for: selectedInstrument.type, from: context)
            }
            saveSettings()
        }
    }
    
    @Published var sensitivity: Double = Constants.defaultSensitivity {
        didSet {
            audioEngine.setSensitivity(sensitivity)
            saveSettings()
        }
    }
    
    // Temperament
    @Published private(set) var activeTemperament: Temperament?
    @Published private(set) var temperamentsForCurrentInstrument: [Temperament] = []
    
    // UI state
    @Published var isRunning: Bool = false
    @Published var error: String?
    @Published var showPermissionAlert: Bool = false
    
    // MARK: - Private Properties
    
    private let audioEngine = AudioEngine()
    private var cancellables = Set<AnyCancellable>()
    private weak var modelContext: ModelContext?
    
    // Smoothed values for display
    private var smoothedCents: Double = 0
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Start the tuner
    func start() {
        audioEngine.start()
    }
    
    /// Stop the tuner
    func stop() {
        audioEngine.stop()
    }
    
    /// Toggle the tuner on/off
    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
    
    /// Reset all note offsets to zero
    func resetNoteOffsets() {
        noteOffsets = [:]
    }
    
    /// Set offset for a specific note
    func setOffset(_ offset: Double, for note: Note) {
        noteOffsets[note] = offset
    }
    
    /// Get offset for a specific note
    func offset(for note: Note) -> Double {
        return noteOffsets[note] ?? 0
    }
    
    /// Get the target string for current pitch (if using instrument mode)
    func targetString(for detectedPitch: Pitch) -> StringTuning? {
        guard !selectedInstrument.strings.isEmpty else { return nil }
        
        // Find the closest string
        return selectedInstrument.strings.min { s1, s2 in
            abs(s1.pitch.midiNote - detectedPitch.midiNote) <
            abs(s2.pitch.midiNote - detectedPitch.midiNote)
        }
    }
    
    /// Check if current pitch is in tune
    var isInTune: Bool {
        return isValid && abs(cents) <= Constants.inTuneThreshold
    }
    
    /// Check if current pitch is close to in tune
    var isClose: Bool {
        return isValid && abs(cents) <= Constants.closeThreshold
    }
    
    /// Tuning direction: -1 = flat, 0 = in tune, 1 = sharp
    var tuningDirection: Int {
        guard isValid else { return 0 }
        if abs(cents) <= Constants.inTuneThreshold {
            return 0
        }
        return cents > 0 ? 1 : -1
    }
    
    // MARK: - Temperament Management
    
    /// Create a new temperament for the current instrument
    func createTemperament(name: String, noteOffsets: [Note: Double], in context: ModelContext) -> Temperament {
        let temperament = Temperament(
            name: name,
            instrumentType: selectedInstrument.type,
            noteOffsets: noteOffsets,
            isActive: false
        )
        context.insert(temperament)
        try? context.save()
        
        // Refresh the list
        loadTemperamentsForCurrentInstrument(from: context)
        
        return temperament
    }
    
    /// Select a temperament as active for the current instrument
    func selectTemperament(_ temperament: Temperament?, in context: ModelContext) {
        // Deactivate all temperaments for this instrument
        for temp in temperamentsForCurrentInstrument {
            temp.isActive = false
        }
        
        // Activate the selected one
        if let temperament = temperament {
            temperament.isActive = true
            activeTemperament = temperament
            noteOffsets = temperament.noteOffsets
        } else {
            activeTemperament = nil
            noteOffsets = [:]
        }
        
        try? context.save()
    }
    
    /// Update an existing temperament
    func updateTemperament(_ temperament: Temperament, name: String, noteOffsets: [Note: Double], in context: ModelContext) {
        temperament.name = name
        temperament.noteOffsets = noteOffsets
        try? context.save()
        
        // If this is the active temperament, update the current offsets
        if temperament.isActive {
            self.noteOffsets = noteOffsets
        }
        
        loadTemperamentsForCurrentInstrument(from: context)
    }
    
    /// Delete a temperament
    func deleteTemperament(_ temperament: Temperament, in context: ModelContext) {
        let wasActive = temperament.isActive
        context.delete(temperament)
        try? context.save()
        
        // If the deleted temperament was active, clear offsets
        if wasActive {
            activeTemperament = nil
            noteOffsets = [:]
        }
        
        loadTemperamentsForCurrentInstrument(from: context)
    }
    
    /// Load temperaments for the current instrument
    func loadTemperamentsForCurrentInstrument(from context: ModelContext) {
        let instrumentType = selectedInstrument.type.rawValue
        let descriptor = FetchDescriptor<Temperament>(
            predicate: #Predicate { $0.instrumentTypeRaw == instrumentType },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        temperamentsForCurrentInstrument = (try? context.fetch(descriptor)) ?? []
    }
    
    /// Load the active temperament for an instrument type
    func loadActiveTemperament(for instrumentType: InstrumentType, from context: ModelContext) {
        let typeRaw = instrumentType.rawValue
        let descriptor = FetchDescriptor<Temperament>(
            predicate: #Predicate { $0.instrumentTypeRaw == typeRaw && $0.isActive == true }
        )
        
        if let active = try? context.fetch(descriptor).first {
            activeTemperament = active
            noteOffsets = active.noteOffsets
        } else {
            activeTemperament = nil
            noteOffsets = [:]
        }
        
        // Also refresh the list
        loadTemperamentsForCurrentInstrument(from: context)
    }
    
    /// Get the notes relevant to the current instrument (for temperament editor)
    var relevantNotesForInstrument: [Note] {
        if selectedInstrument.strings.isEmpty {
            // Chromatic mode - show all notes
            return Note.allCases.map { $0 }
        } else {
            // Get unique notes from the instrument's strings
            let notes = Set(selectedInstrument.strings.map { $0.pitch.note })
            return Note.allCases.filter { notes.contains($0) }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind audio engine state
        audioEngine.$tuningState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateFromTuningState(state)
            }
            .store(in: &cancellables)
        
        audioEngine.$inputLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$inputLevel)
        
        audioEngine.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)
        
        audioEngine.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                    if case .permissionDenied = error {
                        self?.showPermissionAlert = true
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateFromTuningState(_ state: TuningState) {
        frequency = state.frequency
        pitch = state.pitch
        isValid = state.isValid
        
        // Smooth the cents value for stable display
        if state.isValid {
            smoothedCents = smoothedCents * Constants.strobeSmoothingFactor +
                           state.cents * (1 - Constants.strobeSmoothingFactor)
            cents = smoothedCents
        } else {
            cents = 0
        }
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        // Settings are saved via SwiftData when using the settings views
        // This method is a placeholder for triggering saves
    }
    
    /// Load settings from SwiftData (includes migration)
    func loadSettings(from context: ModelContext) {
        self.modelContext = context
        
        let descriptor = FetchDescriptor<UserSettings>()
        
        let settings: UserSettings
        if let existing = try? context.fetch(descriptor).first {
            settings = existing
        } else {
            // Create new settings
            settings = UserSettings()
            context.insert(settings)
            try? context.save()
        }
        
        // Check for and perform migration of legacy note offsets
        performMigrationIfNeeded(settings: settings, context: context)
        
        // Load settings
        referencePitch = settings.referencePitch
        sensitivity = settings.sensitivity
        
        if let instrumentType = InstrumentType(rawValue: settings.selectedInstrumentType) {
            // Set instrument without triggering didSet (which would try to load temperament)
            let instrument = TuningPresets.preset(for: instrumentType)
            
            // Load active temperament for this instrument
            loadActiveTemperament(for: instrumentType, from: context)
            
            // Now set the instrument (this won't reload temperament since we already did)
            selectedInstrument = instrument
        }
        
        // Apply to audio engine
        audioEngine.setReferencePitch(referencePitch)
        audioEngine.setNoteOffsets(noteOffsets)
        audioEngine.setSensitivity(sensitivity)
    }
    
    /// Migrate legacy note offsets to per-instrument temperaments
    private func performMigrationIfNeeded(settings: UserSettings, context: ModelContext) {
        // Check if migration is needed
        guard !settings.migrationCompleted,
              let legacyOffsets = settings.legacyNoteOffsets,
              !legacyOffsets.isEmpty else {
            return
        }
        
        // Get the instrument type that was selected when the legacy offsets were saved
        let instrumentType = InstrumentType(rawValue: settings.selectedInstrumentType) ?? .chromatic
        
        // Create a temperament from the legacy offsets
        let migratedTemperament = Temperament(
            name: "Migrated Settings",
            instrumentType: instrumentType,
            noteOffsets: legacyOffsets,
            isActive: true
        )
        context.insert(migratedTemperament)
        
        // Mark migration as complete
        settings.clearLegacyData()
        
        try? context.save()
        
        print("Migration completed: Created temperament '\(migratedTemperament.name)' for \(instrumentType.rawValue)")
    }
    
    /// Save settings to SwiftData
    func saveSettings(to context: ModelContext) {
        self.modelContext = context
        
        let descriptor = FetchDescriptor<UserSettings>()
        
        let settings: UserSettings
        if let existing = try? context.fetch(descriptor).first {
            settings = existing
        } else {
            settings = UserSettings()
            context.insert(settings)
        }
        
        settings.referencePitch = referencePitch
        settings.selectedInstrumentType = selectedInstrument.type.rawValue
        settings.sensitivity = sensitivity
        
        try? context.save()
    }
}
