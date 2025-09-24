import UIKit
import SwiftUI

class ImageManager {
    
    // MARK: - Properties
    private static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private static let imagesDirectory = documentsDirectory.appendingPathComponent("BarImages")
    
    // MARK: - Initialization
    static func setupImageDirectory() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // MARK: - Save Image
    static func saveImage(_ image: UIImage, for barUUID: String) {
        setupImageDirectory()
        
        // Compress and save the image
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        let filename = imagesDirectory.appendingPathComponent("\(barUUID).jpg")
        
        do {
            try data.write(to: filename)
            print("Image saved successfully for bar: \(barUUID)")
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load Image
    static func loadImage(for barUUID: String) -> UIImage? {
        let filename = imagesDirectory.appendingPathComponent("\(barUUID).jpg")
        
        if FileManager.default.fileExists(atPath: filename.path) {
            return UIImage(contentsOfFile: filename.path)
        }
        
        return nil
    }
    
    // MARK: - Delete Image
    static func deleteImage(for barUUID: String) {
        let filename = imagesDirectory.appendingPathComponent("\(barUUID).jpg")
        
        if FileManager.default.fileExists(atPath: filename.path) {
            do {
                try FileManager.default.removeItem(at: filename)
                print("Image deleted successfully for bar: \(barUUID)")
            } catch {
                print("Failed to delete image: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Check if Image Exists
    static func imageExists(for barUUID: String) -> Bool {
        let filename = imagesDirectory.appendingPathComponent("\(barUUID).jpg")
        return FileManager.default.fileExists(atPath: filename.path)
    }
    
    // MARK: - Get All Saved Images
    static func getAllSavedImageUUIDs() -> [String] {
        var uuids: [String] = []
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
            
            for url in fileURLs {
                if url.pathExtension == "jpg" {
                    let uuid = url.deletingPathExtension().lastPathComponent
                    uuids.append(uuid)
                }
            }
        } catch {
            print("Error reading images directory: \(error.localizedDescription)")
        }
        
        return uuids
    }
    
    // MARK: - Clean Up Orphaned Images
    static func cleanupOrphanedImages(validUUIDs: Set<String>) {
        let savedUUIDs = getAllSavedImageUUIDs()
        
        for uuid in savedUUIDs {
            if !validUUIDs.contains(uuid) {
                deleteImage(for: uuid)
                print("Deleted orphaned image for UUID: \(uuid)")
            }
        }
    }
    
    // MARK: - Get Image File Size
    static func getImageFileSize(for barUUID: String) -> Int64? {
        let filename = imagesDirectory.appendingPathComponent("\(barUUID).jpg")
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filename.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    // MARK: - Get Total Images Size
    static func getTotalImagesSize() -> String {
        var totalSize: Int64 = 0
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            for url in fileURLs {
                if url.pathExtension == "jpg" {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        } catch {
            print("Error calculating total images size: \(error.localizedDescription)")
        }
        
        // Format size for display
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}
