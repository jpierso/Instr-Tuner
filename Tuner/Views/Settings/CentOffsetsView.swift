import SwiftUI

/// View for adjusting per-note cent offsets
struct CentOffsetsView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // Info section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adjust each note's pitch offset for custom temperaments or compensation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Label("Flatter", systemImage: "minus.circle")
                            .font(.caption)
                            .foregroundColor(.cyan)
                        
                        Spacer()
                        
                        Label("Sharper", systemImage: "plus.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Note offset sliders
            Section {
                ForEach(Note.allCases) { note in
                    NoteOffsetRow(
                        note: note,
                        offset: viewModel.offset(for: note),
                        onOffsetChange: { newOffset in
                            viewModel.setOffset(newOffset, for: note)
                        }
                    )
                }
            } header: {
                Text("Note Offsets")
            } footer: {
                Text("Range: \(Int(Constants.minimumCentOffset)) to +\(Int(Constants.maximumCentOffset)) cents")
            }
            
            // Reset button
            Section {
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.resetNoteOffsets()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset All to Zero")
                        Spacer()
                    }
                }
                .disabled(!hasAnyOffset)
            }
        }
        .navigationTitle("Note Offsets")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var hasAnyOffset: Bool {
        viewModel.noteOffsets.values.contains { $0 != 0 }
    }
}

/// Individual row for adjusting a note's cent offset
struct NoteOffsetRow: View {
    let note: Note
    @State private var offset: Double
    let onOffsetChange: (Double) -> Void
    
    init(note: Note, offset: Double, onOffsetChange: @escaping (Double) -> Void) {
        self.note = note
        self._offset = State(initialValue: offset)
        self.onOffsetChange = onOffsetChange
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Note name
                Text(note.settingsName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(width: 70, alignment: .leading)
                
                Spacer()
                
                // Offset value
                Text(formattedOffset)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(offsetColor)
                    .frame(width: 60, alignment: .trailing)
            }
            
            // Slider
            HStack(spacing: 8) {
                // Decrease button
                Button {
                    adjustOffset(by: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
                
                // Slider
                Slider(
                    value: $offset,
                    in: Constants.minimumCentOffset...Constants.maximumCentOffset,
                    step: 1
                )
                .onChange(of: offset) { _, newValue in
                    onOffsetChange(newValue)
                }
                
                // Increase button
                Button {
                    adjustOffset(by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func adjustOffset(by amount: Double) {
        let newValue = max(
            Constants.minimumCentOffset,
            min(Constants.maximumCentOffset, offset + amount)
        )
        withAnimation(.easeInOut(duration: 0.1)) {
            offset = newValue
            onOffsetChange(newValue)
        }
    }
    
    private var formattedOffset: String {
        let rounded = Int(round(offset))
        if rounded > 0 {
            return "+\(rounded)¢"
        } else if rounded < 0 {
            return "\(rounded)¢"
        }
        return "0¢"
    }
    
    private var offsetColor: Color {
        if offset > 0 {
            return .orange
        } else if offset < 0 {
            return .cyan
        }
        return .secondary
    }
}

#Preview {
    NavigationStack {
        CentOffsetsView(viewModel: TunerViewModel())
    }
}
