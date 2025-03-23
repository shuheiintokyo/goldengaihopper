import SwiftUI
import CoreData

@main
struct GoldenPeaceApp: App {
    let persistenceController = PersistenceController.shared
    let dataImportService: DataImportService
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    init() {
        dataImportService = DataImportService(persistenceController: persistenceController)
        // Import initial data when app launches
        dataImportService.importInitialData()
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView()
            }
        }
    }
}
