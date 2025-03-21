import CoreData

typealias GoldenGaiGrid = [[String]]

struct GoldenGaiImporter {
    static func importData(from jsonData: Data, context: NSManagedObjectContext) throws {
        let decoder = JSONDecoder()
        let grid = try decoder.decode(GoldenGaiGrid.self, from: jsonData)
        
        // Delete existing bars
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Bar.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        
        // Import new data
        for (row, columns) in grid.enumerated() {
            for (column, name) in columns.enumerated() {
                if !name.isEmpty {
                    let bar = Bar(context: context)
                    bar.name = name
                    bar.locationRow = Int16(row)
                    bar.locationColumn = Int16(column)
                    bar.uuid = UUID().uuidString
                    bar.isVisited = false
                }
            }
        }
        
        try context.save()
    }
} 