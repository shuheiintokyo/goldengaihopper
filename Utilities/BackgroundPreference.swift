import Foundation
import CoreData
import UIKit

// MARK: - Background Manager Service
class BackgroundManager: ObservableObject {
    static let shared = BackgroundManager()
    
    @Published var contentViewBackground: String = "ContentBackground"
    @Published var barListViewBackground: String = "BarListBackground"
    
    private init() {
        loadBackgroundPreferences()
    }
    
    func loadBackgroundPreferences() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<BackgroundPreference> = BackgroundPreference.fetchRequest()
        
        do {
            let preferences = try context.fetch(request)
            
            for preference in preferences {
                switch preference.viewName {
                case "ContentView":
                    if preference.isCustomImage {
                        contentViewBackground = "custom_content_\(preference.objectID.uriRepresentation().absoluteString.suffix(8))"
                    } else {
                        contentViewBackground = preference.imageName ?? "ContentBackground"
                    }
                case "BarListView":
                    if preference.isCustomImage {
                        barListViewBackground = "custom_barlist_\(preference.objectID.uriRepresentation().absoluteString.suffix(8))"
                    } else {
                        barListViewBackground = preference.imageName ?? "BarListBackground"
                    }
                default:
                    break
                }
            }
        } catch {
            print("Error loading background preferences: \(error)")
        }
    }
    
    func saveBackgroundPreference(for viewName: String, imageName: String?, imageData: Data?, isCustom: Bool) {
        let context = PersistenceController.shared.container.viewContext
        
        // Remove existing preference for this view
        let request: NSFetchRequest<BackgroundPreference> = BackgroundPreference.fetchRequest()
        request.predicate = NSPredicate(format: "viewName == %@", viewName)
        
        do {
            let existingPreferences = try context.fetch(request)
            for preference in existingPreferences {
                context.delete(preference)
            }
            
            // Create new preference
            let newPreference = BackgroundPreference(context: context)
            newPreference.viewName = viewName
            newPreference.imageName = imageName
            newPreference.imageData = imageData
            newPreference.isCustomImage = isCustom
            newPreference.createdAt = Date()
            
            try context.save()
            
            // Update published properties
            DispatchQueue.main.async {
                switch viewName {
                case "ContentView":
                    if isCustom {
                        self.contentViewBackground = "custom_content_\(newPreference.objectID.uriRepresentation().absoluteString.suffix(8))"
                    } else {
                        self.contentViewBackground = imageName ?? "ContentBackground"
                    }
                case "BarListView":
                    if isCustom {
                        self.barListViewBackground = "custom_barlist_\(newPreference.objectID.uriRepresentation().absoluteString.suffix(8))"
                    } else {
                        self.barListViewBackground = imageName ?? "BarListBackground"
                    }
                default:
                    break
                }
            }
            
        } catch {
            print("Error saving background preference: \(error)")
        }
    }
    
    func getCustomImageData(for viewName: String) -> Data? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<BackgroundPreference> = BackgroundPreference.fetchRequest()
        request.predicate = NSPredicate(format: "viewName == %@ AND isCustomImage == YES", viewName)
        
        do {
            let preferences = try context.fetch(request)
            return preferences.first?.imageData
        } catch {
            print("Error fetching custom image data: \(error)")
            return nil
        }
    }
}
