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
                
                // Import the map data with merge logic
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
            
            // Step 1: Collect all bar positions
            var barPositions: [(name: String, row: Int, col: Int)] = []
            
            for (rowIndex, row) in mapData.enumerated() {
                for (colIndex, barName) in row.enumerated() {
                    // Skip empty cells, but include vacant placeholders
                    if !barName.isEmpty {
                        barPositions.append((name: barName, row: rowIndex, col: colIndex))
                    }
                }
            }
            
            // Step 2: Track which positions have been merged
            var mergedPositions = Set<String>() // Format: "row-col"
            
            // Step 3: Process each position
            for i in 0..<barPositions.count {
                let posKey = "\(barPositions[i].row)-\(barPositions[i].col)"
                
                // Skip if already merged
                if mergedPositions.contains(posKey) {
                    continue
                }
                
                let currentBar = barPositions[i]
                var horizontalSpan = 1
                var verticalSpan = 1
                
                // Look for duplicate name that's adjacent
                for j in (i+1)..<barPositions.count {
                    let otherBar = barPositions[j]
                    let otherPosKey = "\(otherBar.row)-\(otherBar.col)"
                    
                    // Skip if already merged
                    if mergedPositions.contains(otherPosKey) {
                        continue
                    }
                    
                    // Check if names match
                    if currentBar.name == otherBar.name {
                        // Check horizontal adjacency: same row, columns next to each other
                        if currentBar.row == otherBar.row &&
                           abs(currentBar.col - otherBar.col) == 1 {
                            horizontalSpan = 2
                            mergedPositions.insert(otherPosKey)
                            print("🔲 Horizontal merge: \(currentBar.name) at (\(currentBar.row), \(currentBar.col)) + (\(otherBar.row), \(otherBar.col))")
                            break
                        }
                        
                        // Check vertical adjacency: same column, rows next to each other
                        if currentBar.col == otherBar.col &&
                           abs(currentBar.row - otherBar.row) == 1 {
                            verticalSpan = 2
                            mergedPositions.insert(otherPosKey)
                            print("🔲 Vertical merge: \(currentBar.name) at (\(currentBar.row), \(currentBar.col)) + (\(otherBar.row), \(otherBar.col))")
                            break
                        }
                    }
                }
                
                // Create the bar entity
                let bar = Bar(context: context)
                bar.uuid = UUID().uuidString
                bar.name = currentBar.name
                bar.isVisited = false
                bar.locationRow = Int16(currentBar.row)
                bar.locationColumn = Int16(currentBar.col)
                bar.cellSpanHorizontal = Int16(horizontalSpan)
                bar.cellSpanVertical = Int16(verticalSpan)
                
                if horizontalSpan > 1 || verticalSpan > 1 {
                    print("✨ Created merged bar: \(currentBar.name) at (\(currentBar.row), \(currentBar.col)) - \(horizontalSpan)x\(verticalSpan)")
                } else {
                    print("Created bar: \(currentBar.name) at row \(currentBar.row), col \(currentBar.col)")
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
