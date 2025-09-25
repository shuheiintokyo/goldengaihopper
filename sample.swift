import SwiftUI
import CoreData

@main
struct GoldenPeaceApp: App {
    let persistenceController = PersistenceController.shared
    let dataImportService: DataImportService
    @AppStorage("isLoggedIn") var isLoggedIn = false  // This defaults to false on first install
    
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
                    .onAppear {
                        checkForRemoteUpdates()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        // Check for updates when app comes to foreground
                        checkForRemoteUpdates()
                    }
            } else {
                LoginView()
            }
        }
    }
    
    private func checkForRemoteUpdates() {
        let context = persistenceController.container.viewContext
        
        RemoteDataService.shared.checkForUpdates(context: context) { success in
            if success {
                print("✅ Remote update successful")
                
                // Post notification to refresh UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("BarDataUpdated"),
                    object: nil
                )
            } else {
                print("ℹ️ No updates needed")
            }
        }
    }
}
