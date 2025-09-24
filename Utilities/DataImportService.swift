import Foundation
import CoreData

class DataImportService {
    let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    func importInitialData() {
        // Import from JSON regardless of existing data
        if let url = Bundle.main.url(forResource: "golden-gai-json-data", withExtension: "json") {
            do {
                // First, delete all existing bars
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Bar.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try persistenceController.container.viewContext.execute(deleteRequest)
                
                // Then import fresh data
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(GoldenGaiData.self, from: data)
                
                // Import the map data
                importBars(from: jsonData.map)
                
                // Save context
                try persistenceController.container.viewContext.save()
            } catch {
                print("Error importing data: \(error)")
            }
        }
    }
    
    private func importBars(from mapData: [[String]]) {
        let context = persistenceController.container.viewContext
        
        // First, delete all existing bars to start fresh
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Bar.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            context.reset() // Reset context to ensure a clean state
            
            // Create a set to track unique bar names we've processed
            var processedBarNames = Set<String>()
            
            // First pass: create a unique Bar entity for each unique name
            for (rowIndex, row) in mapData.enumerated() {
                for (colIndex, barName) in row.enumerated() {
                    if !barName.isEmpty && !processedBarNames.contains(barName) {
                        // Create a new Bar entity only if we haven't seen this name before
                        let bar = Bar(context: context)
                        bar.uuid = UUID().uuidString
                        bar.name = barName
                        bar.isVisited = false
                        bar.locationRow = Int16(rowIndex)
                        bar.locationColumn = Int16(colIndex)
                        
                        // Mark this name as processed
                        processedBarNames.insert(barName)
                        print("Created bar: \(barName) at row \(rowIndex), col \(colIndex)")
                    }
                }
            }
            
            // Save the context to persist changes
            try context.save()
        } catch {
            print("Error during bar import: \(error)")
        }
    }
}

// JSON Structure
struct GoldenGaiData: Codable {
    let metadata: Metadata
    let map: [[String]]
    
    struct Metadata: Codable {
        let title: String
        let date: String
    }
}
