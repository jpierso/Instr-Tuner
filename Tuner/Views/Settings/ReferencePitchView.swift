import SwiftUI

/// View for adjusting the reference pitch (A4 frequency)
struct ReferencePitchView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var sliderValue: Double = 440.0
    
    var body: some View {
        List {
            // Preset buttons
            Section {
                ForEach(ReferencePitchPreset.allCases) { preset in
                    Button {
                        withAnimation {
                            sliderValue = preset.rawValue
                            viewModel.referencePitch = preset.rawValue
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.shortName)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                                
                                Text(presetDescription(preset))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if abs(viewModel.referencePitch - preset.rawValue) < 0.5 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Presets")
            }
            
            // Fine adjustment slider
            Section {
                VStack(spacing: 16) {
                    // Current value display
                    HStack {
                        Text("A =")
                            .font(.system(size: 24, weight: .medium))
                        
                        Text(String(format: "%.1f", sliderValue))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                        
                        Text("Hz")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    // Slider
                    VStack(spacing: 8) {
                        Slider(
                            value: $sliderValue,
                            in: Constants.minimumReferencePitch...Constants.maximumReferencePitch,
                            step: 0.1
                        ) {
                            Text("Reference Pitch")
                        } minimumValueLabel: {
                            Text("\(Int(Constants.minimumReferencePitch))")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("\(Int(Constants.maximumReferencePitch))")
                                .font(.caption)
                        }
                        .onChange(of: sliderValue) { _, newValue in
                            viewModel.referencePitch = newValue
                        }
                        
                        // Fine adjustment buttons
                        HStack(spacing: 20) {
                            Button {
                                adjustPitch(by: -1.0)
                            } label: {
                                Label("-1 Hz", systemImage: "minus.circle")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                adjustPitch(by: -0.1)
                            } label: {
                                Label("-0.1", systemImage: "minus")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                adjustPitch(by: 0.1)
                            } label: {
                                Label("+0.1", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                adjustPitch(by: 1.0)
                            } label: {
                                Label("+1 Hz", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Fine Adjustment")
            } footer: {
                Text("Drag the slider or use the buttons for precise adjustment between \(Int(Constants.minimumReferencePitch))-\(Int(Constants.maximumReferencePitch)) Hz.")
            }
            
            // Reset button
            Section {
                Button(role: .destructive) {
                    withAnimation {
                        sliderValue = Constants.defaultReferencePitch
                        viewModel.referencePitch = Constants.defaultReferencePitch
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Standard (A = 440 Hz)")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Reference Pitch")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sliderValue = viewModel.referencePitch
        }
    }
    
    private func adjustPitch(by amount: Double) {
        let newValue = max(
            Constants.minimumReferencePitch,
            min(Constants.maximumReferencePitch, sliderValue + amount)
        )
        withAnimation {
            sliderValue = newValue
            viewModel.referencePitch = newValue
        }
    }
    
    private func presetDescription(_ preset: ReferencePitchPreset) -> String {
        switch preset {
        case .baroque:
            return "Historical baroque pitch"
        case .verdi:
            return "Scientific/Verdi tuning"
        case .standard:
            return "ISO international standard"
        case .orchestraLow:
            return "European orchestral standard"
        case .orchestraHigh:
            return "Bright orchestral tuning"
        }
    }
}

#Preview {
    NavigationStack {
        ReferencePitchView(viewModel: TunerViewModel())
    }
}
