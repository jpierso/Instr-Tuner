import SwiftUI

/// Main settings view
struct SettingsView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                // Reference Pitch Section
                Section {
                    NavigationLink {
                        ReferencePitchView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("Reference Pitch", systemImage: "tuningfork")
                            Spacer()
                            Text("A = \(Int(viewModel.referencePitch)) Hz")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Tuning")
                } footer: {
                    Text("Standard concert pitch is A = 440 Hz. Baroque music often uses A = 415 Hz.")
                }
                
                // Note Offsets Section
                Section {
                    NavigationLink {
                        CentOffsetsView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("Note Offsets", systemImage: "slider.horizontal.3")
                            Spacer()
                            if hasCustomOffsets {
                                Text("Custom")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Default")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } footer: {
                    Text("Adjust individual note pitches for temperament or personal preference.")
                }
                
                // Microphone Sensitivity Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Microphone Sensitivity", systemImage: "mic.fill")
                            Spacer()
                            Text(sensitivityLabel)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.1")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Slider(
                                value: $viewModel.sensitivity,
                                in: Constants.minSensitivity...Constants.maxSensitivity,
                                step: 0.1
                            )
                            .tint(.blue)
                            
                            Image(systemName: "speaker.wave.3")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        // Sensitivity indicator
                        HStack(spacing: 4) {
                            ForEach(0..<10, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index < Int(viewModel.sensitivity * 10) ? sensitivityColor : Color.secondary.opacity(0.2))
                                    .frame(height: 8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Input")
                } footer: {
                    Text("Increase sensitivity if the tuner has difficulty hearing your instrument. Decrease if there's too much background noise.")
                }
                
                // Current Instrument Section
                Section {
                    HStack {
                        Label("Current Instrument", systemImage: viewModel.selectedInstrument.type.icon)
                        Spacer()
                        Text(viewModel.selectedInstrument.name)
                            .foregroundColor(.secondary)
                    }
                    
                    if !viewModel.selectedInstrument.strings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Strings")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                ForEach(viewModel.selectedInstrument.strings) { string in
                                    VStack(spacing: 2) {
                                        Text(string.pitch.note.displayName)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("\(string.pitch.octave)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 36)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Instrument")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveSettings(to: modelContext)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var hasCustomOffsets: Bool {
        !viewModel.noteOffsets.isEmpty && viewModel.noteOffsets.values.contains { $0 != 0 }
    }
    
    private var sensitivityLabel: String {
        switch viewModel.sensitivity {
        case 0..<0.3:
            return "Low"
        case 0.3..<0.7:
            return "Medium"
        default:
            return "High"
        }
    }
    
    private var sensitivityColor: Color {
        switch viewModel.sensitivity {
        case 0..<0.3:
            return .blue
        case 0.3..<0.7:
            return .green
        default:
            return .orange
        }
    }
}

#Preview {
    SettingsView(viewModel: TunerViewModel())
}
