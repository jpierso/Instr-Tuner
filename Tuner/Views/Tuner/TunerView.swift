import SwiftUI

/// Main tuner view combining strobe, note display, and controls
struct TunerView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section: Reference pitch display
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                // Main strobe display with note overlay
                strobeSection(geometry: geometry)
                
                Spacer()
                
                // Cents and frequency display
                tuningInfoSection
                
                // Tuning indicator bar
                TuningIndicatorView(
                    cents: viewModel.cents,
                    isValid: viewModel.isValid,
                    isInTune: viewModel.isInTune
                )
                .padding(.horizontal, 40)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom section: Input level and start/stop
                bottomSection
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.black)
        .onAppear {
            viewModel.loadSettings(from: modelContext)
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .alert("Microphone Access Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to use the tuner.")
        }
    }
    
    // MARK: - Subviews
    
    private var topBar: some View {
        HStack {
            // Instrument name
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedInstrument.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                if !viewModel.selectedInstrument.strings.isEmpty {
                    Text(stringNames)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Reference pitch
            VStack(alignment: .trailing, spacing: 2) {
                Text("A = \(Int(viewModel.referencePitch)) Hz")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                
                if viewModel.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Listening")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
            }
        }
    }
    
    private func strobeSection(geometry: GeometryProxy) -> some View {
        var strobeSize = min(geometry.size.width - 40, geometry.size.height * 0.45)
        if !strobeSize.isFinite || strobeSize < 0 {
            strobeSize = 0
        }
        
        return ZStack {
            // Strobe visualization
            StrobeView(
                cents: viewModel.cents,
                isValid: viewModel.isValid,
                isInTune: viewModel.isInTune
            )
            .frame(width: strobeSize, height: strobeSize)
            
            // Note display in center of strobe
            VStack(spacing: 8) {
                NoteDisplayView(
                    pitch: viewModel.pitch,
                    isValid: viewModel.isValid,
                    isInTune: viewModel.isInTune
                )
                
                // Target string indicator (for instrument mode)
                if let targetString = viewModel.targetString(for: viewModel.pitch) {
                    Text("String: \(targetString.pitch.displayName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
    
    private var tuningInfoSection: some View {
        VStack(spacing: 8) {
            CentsDisplayView(
                cents: viewModel.cents,
                isValid: viewModel.isValid,
                isInTune: viewModel.isInTune
            )
            
            FrequencyDisplayView(
                frequency: viewModel.frequency,
                isValid: viewModel.isValid
            )
        }
    }
    
    private var bottomSection: some View {
        HStack {
            // Input level meter
            VStack(alignment: .leading, spacing: 4) {
                Text("INPUT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                
                InputLevelView(
                    level: viewModel.inputLevel,
                    isRunning: viewModel.isRunning
                )
                .frame(width: 120)
            }
            
            Spacer()
            
            // Start/Stop button
            Button {
                viewModel.toggle()
            } label: {
                Image(systemName: viewModel.isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(viewModel.isRunning ? .red : .green)
            }
            
            Spacer()
            
            // In-tune indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("STATUS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                }
            }
            .frame(width: 120, alignment: .trailing)
        }
    }
    
    // MARK: - Helpers
    
    private var stringNames: String {
        viewModel.selectedInstrument.strings
            .map { $0.pitch.note.displayName }
            .joined(separator: " ")
    }
    
    private var statusColor: Color {
        if !viewModel.isValid {
            return .gray
        }
        if viewModel.isInTune {
            return .green
        }
        if viewModel.isClose {
            return .yellow
        }
        return .orange
    }
    
    private var statusText: String {
        if !viewModel.isValid {
            return "No Signal"
        }
        if viewModel.isInTune {
            return "In Tune"
        }
        if viewModel.cents > 0 {
            return "Sharp"
        }
        return "Flat"
    }
}

#Preview {
    TunerView(viewModel: TunerViewModel())
}

