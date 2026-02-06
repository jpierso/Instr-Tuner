import SwiftUI
import SwiftData

@main
struct TunerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CustomInstrument.self,
            UserSettings.self,
            Temperament.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed — delete the old store and retry
            print("ModelContainer failed, deleting old store: \(error)")
            let url = modelConfiguration.url
            let fileManager = FileManager.default
            for suffix in ["", "-wal", "-shm"] {
                let path = url.absoluteString + suffix
                if let fileUrl = URL(string: path) {
                    try? fileManager.removeItem(at: fileUrl)
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
