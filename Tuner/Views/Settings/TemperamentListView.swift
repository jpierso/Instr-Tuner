import SwiftUI
import SwiftData

/// View for managing temperaments for the current instrument
struct TemperamentListView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCreateSheet = false
    @State private var temperamentToEdit: Temperament?
    @State private var temperamentToDelete: Temperament?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            // Info section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.selectedInstrument.type.icon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedInstrument.name)
                            .font(.headline)
                        
                        if let active = viewModel.activeTemperament {
                            Text("Active: \(active.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No temperament selected (Equal)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Equal temperament (default)
            Section {
                Button {
                    viewModel.selectTemperament(nil, in: modelContext)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equal Temperament")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Standard tuning with no offsets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.activeTemperament == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Default")
            }
            
            // Custom temperaments
            Section {
                if viewModel.temperamentsForCurrentInstrument.isEmpty {
                    Text("No custom temperaments yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.temperamentsForCurrentInstrument) { temperament in
                        TemperamentRow(
                            temperament: temperament,
                            isActive: temperament.isActive,
                            onSelect: {
                                viewModel.selectTemperament(temperament, in: modelContext)
                            },
                            onEdit: {
                                temperamentToEdit = temperament
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                temperamentToDelete = temperament
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                temperamentToEdit = temperament
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("Create New Temperament", systemImage: "plus.circle")
                }
            } header: {
                Text("Custom Temperaments")
            } footer: {
                Text("Create custom temperaments with specific note offsets for this instrument.")
            }
        }
        .navigationTitle("Temperaments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTemperamentsForCurrentInstrument(from: modelContext)
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack {
                TemperamentEditorView(
                    viewModel: viewModel,
                    mode: .create
                )
            }
        }
        .sheet(item: $temperamentToEdit) { temperament in
            NavigationStack {
                TemperamentEditorView(
                    viewModel: viewModel,
                    mode: .edit(temperament)
                )
            }
        }
        .alert("Delete Temperament", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                temperamentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let temperament = temperamentToDelete {
                    viewModel.deleteTemperament(temperament, in: modelContext)
                }
                temperamentToDelete = nil
            }
        } message: {
            if let temperament = temperamentToDelete {
                Text("Are you sure you want to delete '\(temperament.name)'? This cannot be undone.")
            }
        }
    }
}

/// Row displaying a temperament option
struct TemperamentRow: View {
    let temperament: Temperament
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(temperament.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(offsetSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var offsetSummary: String {
        let offsets = temperament.noteOffsets
        if offsets.isEmpty {
            return "No offsets"
        }
        
        let nonZeroCount = offsets.values.filter { $0 != 0 }.count
        if nonZeroCount == 0 {
            return "No offsets"
        }
        
        return "\(nonZeroCount) note\(nonZeroCount == 1 ? "" : "s") adjusted"
    }
}

#Preview {
    NavigationStack {
        TemperamentListView(viewModel: TunerViewModel())
    }
}
