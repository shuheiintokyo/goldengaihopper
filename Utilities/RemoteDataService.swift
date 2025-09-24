import Foundation
import CoreData

// MARK: - Remote Data Service
class RemoteDataService {
    static let shared = RemoteDataService()
    private let remoteDataURL = "https://shuheiintokyo.github.io/golden-gai-data"
    private let localCacheKey = "cachedBarData"
    private let lastUpdateKey = "lastDataUpdate"
    
    private init() {}
    
    // Check for updates on app launch or periodically
    func checkForUpdates(context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: remoteDataURL) else {
            completion(false)
            return
        }
        
        // Add version check to avoid unnecessary downloads
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Check if data has been modified
            if let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
                let lastUpdate = UserDefaults.standard.string(forKey: self.lastUpdateKey)
                
                if lastUpdate != lastModified {
                    self.downloadAndUpdateData(context: context) { success in
                        if success {
                            UserDefaults.standard.set(lastModified, forKey: self.lastUpdateKey)
                        }
                        DispatchQueue.main.async {
                            completion(success)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false) // No update needed
                    }
                }
            }
        }.resume()
    }
    
    private func downloadAndUpdateData(context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: remoteDataURL) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let remoteData = try decoder.decode(RemoteBarData.self, from: data)
                
                // Cache the data locally
                UserDefaults.standard.set(data, forKey: self.localCacheKey)
                
                // Update Core Data
                self.updateBars(with: remoteData, context: context)
                completion(true)
                
            } catch {
                print("Error decoding remote data: \(error)")
                completion(false)
            }
        }.resume()
    }
    
    private func updateBars(with remoteData: RemoteBarData, context: NSManagedObjectContext) {
        context.perform {
            // Update bar names based on remote data
            for update in remoteData.barUpdates {
                let fetchRequest: NSFetchRequest<Bar> = Bar.fetchRequest()
                
                // Try to find by UUID first (most reliable)
                if let uuid = update.uuid {
                    fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
                } else if let oldName = update.oldName {
                    // Fallback to name and location
                    fetchRequest.predicate = NSPredicate(
                        format: "name == %@ AND locationRow == %d AND locationColumn == %d",
                        oldName, update.row, update.column
                    )
                }
                
                do {
                    let bars = try context.fetch(fetchRequest)
                    if let bar = bars.first {
                        // Update the bar name
                        if let newName = update.newName {
                            bar.name = newName
                        }
                        
                        // Update status if provided
                        if let isClosed = update.isClosed, isClosed {
                            bar.name = "[CLOSED] \(bar.name ?? "")"
                        }
                    }
                } catch {
                    print("Error updating bar: \(error)")
                }
            }
            
            // Save changes
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // Load cached data if offline
    func loadCachedData() -> RemoteBarData? {
        guard let data = UserDefaults.standard.data(forKey: localCacheKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(RemoteBarData.self, from: data)
        } catch {
            print("Error loading cached data: \(error)")
            return nil
        }
    }
}

// MARK: - Data Models for Remote Updates
struct RemoteBarData: Codable {
    let version: String
    let lastUpdated: String
    let barUpdates: [BarUpdate]
    let translations: [String: String]? // Optional updated translations
}

struct BarUpdate: Codable {
    let uuid: String?
    let oldName: String?
    let newName: String?
    let row: Int16
    let column: Int16
    let isClosed: Bool?
    let notes: String?
}

// MARK: - Updated App Delegate or Scene Delegate
extension GoldenPeaceApp {
    func checkForDataUpdates() {
        let context = PersistenceController.shared.container.viewContext
        
        RemoteDataService.shared.checkForUpdates(context: context) { updated in
            if updated {
                print("Bar data updated successfully")
                // Post notification to refresh UI if needed
                NotificationCenter.default.post(
                    name: NSNotification.Name("BarDataUpdated"),
                    object: nil
                )
            }
        }
    }
}

// MARK: - User Edit Feature (Optional)
extension Bar {
    func submitNameChange(newName: String, completion: @escaping (Bool) -> Void) {
        // This would send the suggested change to your server for review
        guard let uuid = self.uuid else {
            completion(false)
            return
        }
        
        let suggestion = BarNameSuggestion(
            barUUID: uuid,
            currentName: self.name ?? "",
            suggestedName: newName,
            row: Int(self.locationRow),
            column: Int(self.locationColumn),
            timestamp: Date(),
            deviceID: getDeviceIdentifier()
        )
        
        // Send to your server for moderation
        // This is just an example - implement your actual API call
        submitSuggestion(suggestion) { success in
            completion(success)
        }
    }
}

struct BarNameSuggestion: Codable {
    let barUUID: String
    let currentName: String
    let suggestedName: String
    let row: Int
    let column: Int
    let timestamp: Date
    let deviceID: String
}

private func submitSuggestion(_ suggestion: BarNameSuggestion, completion: @escaping (Bool) -> Void) {
    // Implement API call to your server
    // The server would collect suggestions and you could review them
    completion(true) // Placeholder
}

private func getDeviceIdentifier() -> String {
    return generateFallbackID()
}

private func generateFallbackID() -> String {
    // Check if we already have a stored device ID
    let key = "AppDeviceIdentifier"
    if let existingID = UserDefaults.standard.string(forKey: key) {
        return existingID
    }
    
    // Generate a new UUID and store it
    let newID = UUID().uuidString
    UserDefaults.standard.set(newID, forKey: key)
    return newID
}


