import SwiftUI
import CoreData

@main
struct GoldenPeaceApp: App {
    let persistenceController = PersistenceController.shared
    let dataImportService: DataImportService
    
    init() {
        dataImportService = DataImportService(persistenceController: persistenceController)
        // Import initial data when app launches
        dataImportService.importInitialData()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
