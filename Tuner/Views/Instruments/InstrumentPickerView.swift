import SwiftUI
import SwiftData

/// View for selecting an instrument preset
struct InstrumentPickerView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \CustomInstrument.createdAt, order: .reverse)
    private var customInstruments: [CustomInstrument]
    
    @State private var showingCreateTuning = false
    
    var body: some View {
        NavigationStack {
            List {
                // Built-in instruments
                Section {
                    ForEach(TuningPresets.allPresets) { instrument in
                        InstrumentRow(
                            instrument: instrument,
                            isSelected: viewModel.selectedInstrument.type == instrument.type,
                            onSelect: {
                                selectInstrument(instrument)
                            }
                        )
                    }
                } header: {
                    Text("Standard Tunings")
                }
                
                // Custom instruments
                Section {
                    ForEach(customInstruments) { custom in
                        let instrument = custom.toInstrument()
                        InstrumentRow(
                            instrument: instrument,
                            isSelected: false,
                            onSelect: {
                                selectInstrument(instrument)
                            }
                        )
                    }
                    .onDelete(perform: deleteCustomInstruments)
                    
                    Button {
                        showingCreateTuning = true
                    } label: {
                        Label("Create Custom Tuning", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Custom Tunings")
                } footer: {
                    if customInstruments.isEmpty {
                        Text("Create your own tuning configurations for alternate tunings or custom instruments.")
                    }
                }
            }
            .navigationTitle("Instruments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveSettings(to: modelContext)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTuning) {
                CustomTuningView(viewModel: viewModel)
            }
        }
    }
    
    private func selectInstrument(_ instrument: Instrument) {
        withAnimation {
            viewModel.selectedInstrument = instrument
        }
        dismiss()
    }
    
    private func deleteCustomInstruments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(customInstruments[index])
        }
    }
}

/// Row displaying an instrument option
struct InstrumentRow: View {
    let instrument: Instrument
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: instrument.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                
                // Name and strings
                VStack(alignment: .leading, spacing: 4) {
                    Text(instrument.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !instrument.strings.isEmpty {
                        Text(stringDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Detects any note")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var stringDescription: String {
        instrument.strings
            .map { $0.pitch.displayName }
            .joined(separator: " - ")
    }
}

/// Detail view for a selected instrument
struct InstrumentDetailView: View {
    let instrument: Instrument
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Type")
                    Spacer()
                    Text(instrument.type.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            
            if !instrument.strings.isEmpty {
                Section {
                    ForEach(Array(instrument.strings.enumerated()), id: \.element.id) { index, string in
                        HStack {
                            Text("String \(index + 1)")
                            Spacer()
                            Text(string.pitch.displayName)
                                .font(.system(.body, design: .monospaced))
                            
                            Text(TuningMath.formatFrequency(
                                TuningMath.frequency(for: string.pitch)
                            ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Strings")
                }
            }
        }
        .navigationTitle(instrument.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InstrumentPickerView(viewModel: TunerViewModel())
}
