import Foundation
import CoreData

class DataImportService {
    let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    func importInitialData() {
        // Check if data already exists
        let fetchRequest: NSFetchRequest<Bar> = Bar.fetchRequest()
        let count = try? persistenceController.container.viewContext.count(for: fetchRequest)
        
        if count == 0 {
            // No data exists, import from JSON
            if let url = Bundle.main.url(forResource: "golden-gai-json-data", withExtension: "json") {
                do {
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
    }
    
    private func importBars(from mapData: [[String]]) {
        let context = persistenceController.container.viewContext
        
        for (rowIndex, row) in mapData.enumerated() {
            for (colIndex, barName) in row.enumerated() {
                if !barName.isEmpty {
                    let bar = Bar(context: context)
                    bar.uuid = UUID().uuidString
                    bar.name = barName
                    bar.isVisited = false
                    bar.locationRow = Int16(rowIndex)
                    bar.locationColumn = Int16(colIndex)
                }
            }
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
