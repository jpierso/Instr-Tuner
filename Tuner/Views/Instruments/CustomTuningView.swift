import SwiftUI
import SwiftData

/// View for creating and editing custom tunings
struct CustomTuningView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var tuningName: String = ""
    @State private var strings: [EditableString] = []
    @State private var showingAddString = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // For editing existing tuning
    var existingTuning: CustomInstrument?
    
    init(viewModel: TunerViewModel, existingTuning: CustomInstrument? = nil) {
        self.viewModel = viewModel
        self.existingTuning = existingTuning
        
        if let existing = existingTuning {
            _tuningName = State(initialValue: existing.name)
            _strings = State(initialValue: existing.strings.map { EditableString(from: $0) })
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section {
                    TextField("Tuning Name", text: $tuningName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your tuning a descriptive name like \"Drop D Guitar\" or \"DADGAD\"")
                }
                
                // Strings section
                Section {
                    if strings.isEmpty {
                        Text("No strings added yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach($strings) { $string in
                            EditableStringRow(string: $string)
                        }
                        .onDelete(perform: deleteStrings)
                        .onMove(perform: moveStrings)
                    }
                    
                    Button {
                        addString()
                    } label: {
                        Label("Add String", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("Strings")
                        Spacer()
                        Text("\(strings.count) strings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("Add strings from highest (1st) to lowest. Each string needs a note and octave.")
                }
                
                // Quick presets section
                Section {
                    Button("Start from Guitar (Standard)") {
                        loadPreset(TuningPresets.acousticGuitar)
                    }
                    
                    Button("Start from Bass (Standard)") {
                        loadPreset(TuningPresets.electricBass)
                    }
                    
                    Button("Start from Violin") {
                        loadPreset(TuningPresets.violin)
                    }
                } header: {
                    Text("Quick Start")
                }
            }
            .navigationTitle(existingTuning != nil ? "Edit Tuning" : "New Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTuning()
                    }
                    .disabled(!isValid)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                    }
                }
            }
            .alert("Invalid Tuning", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func addString() {
        let newString = EditableString(
            note: .E,
            octave: 4,
            centOffset: 0
        )
        withAnimation {
            strings.append(newString)
        }
    }
    
    private func deleteStrings(at offsets: IndexSet) {
        withAnimation {
            strings.remove(atOffsets: offsets)
        }
    }
    
    private func moveStrings(from source: IndexSet, to destination: Int) {
        withAnimation {
            strings.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    private func loadPreset(_ instrument: Instrument) {
        withAnimation {
            tuningName = "\(instrument.name) (Custom)"
            strings = instrument.strings.map { EditableString(from: $0) }
        }
    }
    
    private func saveTuning() {
        guard validate() else { return }
        
        let stringTunings = strings.map { $0.toStringTuning() }
        
        if let existing = existingTuning {
            existing.name = tuningName.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.strings = stringTunings
        } else {
            let newTuning = CustomInstrument(
                name: tuningName.trimmingCharacters(in: .whitespacesAndNewlines),
                strings: stringTunings
            )
            modelContext.insert(newTuning)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        !tuningName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !strings.isEmpty
    }
    
    private func validate() -> Bool {
        let trimmedName = tuningName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationMessage = "Please enter a name for your tuning."
            showingValidationAlert = true
            return false
        }
        
        if strings.isEmpty {
            validationMessage = "Please add at least one string to your tuning."
            showingValidationAlert = true
            return false
        }
        
        return true
    }
}

/// Editable string for the form
struct EditableString: Identifiable {
    let id = UUID()
    var note: Note
    var octave: Int
    var centOffset: Double
    
    init(note: Note, octave: Int, centOffset: Double) {
        self.note = note
        self.octave = octave
        self.centOffset = centOffset
    }
    
    init(from stringTuning: StringTuning) {
        self.note = stringTuning.pitch.note
        self.octave = stringTuning.pitch.octave
        self.centOffset = stringTuning.centOffset
    }
    
    func toStringTuning() -> StringTuning {
        StringTuning(note: note, octave: octave, centOffset: centOffset)
    }
}

/// Row for editing a single string
struct EditableStringRow: View {
    @Binding var string: EditableString
    
    var body: some View {
        HStack(spacing: 16) {
            // Note picker
            Picker("Note", selection: $string.note) {
                ForEach(Note.allCases) { note in
                    Text(note.displayName).tag(note)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 70)
            
            // Octave stepper
            HStack(spacing: 4) {
                Text("Octave:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Stepper(value: $string.octave, in: 0...8) {
                    Text("\(string.octave)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 20)
                }
            }
            
            Spacer()
            
            // Frequency preview
            Text(frequencyText)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
    }
    
    private var frequencyText: String {
        let freq = TuningMath.frequency(
            note: string.note,
            octave: string.octave
        )
        return String(format: "%.1f Hz", freq)
    }
}

#Preview {
    CustomTuningView(viewModel: TunerViewModel())
}
