import SwiftUI

struct ContentView: View {
    @StateObject private var tunerViewModel = TunerViewModel()
    @State private var showSettings = false
    @State private var showInstruments = false
    
    var body: some View {
        NavigationStack {
            TunerView(viewModel: tunerViewModel)
                .navigationTitle("Tuner")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showInstruments = true
                        } label: {
                            Image(systemName: "guitars")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(viewModel: tunerViewModel)
                }
                .sheet(isPresented: $showInstruments) {
                    InstrumentPickerView(viewModel: tunerViewModel)
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
