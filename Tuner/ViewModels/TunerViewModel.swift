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
            saveSettings()
        }
    }
    
    @Published var selectedInstrument: Instrument = TuningPresets.chromatic {
        didSet {
            saveSettings()
        }
    }
    
    @Published var sensitivity: Double = Constants.defaultSensitivity {
        didSet {
            audioEngine.setSensitivity(sensitivity)
            saveSettings()
        }
    }
    
    // UI state
    @Published var isRunning: Bool = false
    @Published var error: String?
    @Published var showPermissionAlert: Bool = false
    
    // MARK: - Private Properties
    
    private let audioEngine = AudioEngine()
    private var cancellables = Set<AnyCancellable>()
    
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
    
    /// Load settings from SwiftData
    func loadSettings(from context: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()
        
        if let settings = try? context.fetch(descriptor).first {
            referencePitch = settings.referencePitch
            noteOffsets = settings.noteOffsets
            sensitivity = settings.sensitivity
            
            if let instrumentType = InstrumentType(rawValue: settings.selectedInstrumentType) {
                selectedInstrument = TuningPresets.preset(for: instrumentType)
            }
        }
        
        // Apply to audio engine
        audioEngine.setReferencePitch(referencePitch)
        audioEngine.setNoteOffsets(noteOffsets)
        audioEngine.setSensitivity(sensitivity)
    }
    
    /// Save settings to SwiftData
    func saveSettings(to context: ModelContext) {
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
        settings.selectedInstrumentType = selectedInstrument.type.rawValue
        settings.sensitivity = sensitivity
        
        try? context.save()
    }
}
