import SwiftUI

// MARK: - Custom Background Image View
struct CustomBackgroundImage: View {
    let viewName: String
    let defaultImageName: String
    @StateObject private var backgroundManager = BackgroundManager.shared
    
    var body: some View {
        Group {
            if let customImageData = backgroundManager.getCustomImageData(for: viewName),
               let uiImage = UIImage(data: customImageData) {
                // Custom image from user's photos
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Default image from app bundle
                Image(getCurrentBackgroundName())
                    .resizable()
                    .scaledToFill()
            }
        }
    }
    
    private func getCurrentBackgroundName() -> String {
        switch viewName {
        case "ContentView":
            return backgroundManager.contentViewBackground.starts(with: "custom_") ? defaultImageName : backgroundManager.contentViewBackground
        case "BarListView":
            return backgroundManager.barListViewBackground.starts(with: "custom_") ? defaultImageName : backgroundManager.barListViewBackground
        default:
            return defaultImageName
        }
    }
}
