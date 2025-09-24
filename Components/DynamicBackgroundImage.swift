import SwiftUI

// MARK: - Dynamic Background Image Component
struct DynamicBackgroundImage: View {
    let viewName: String
    let defaultImageName: String
    @State private var customImage: UIImage?
    
    var body: some View {
        Group {
            if let customImage = customImage {
                // Display custom image
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Display default image
                Image(defaultImageName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .onAppear {
            loadCustomImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .backgroundImageChanged)) { notification in
            if let changedViewName = notification.userInfo?["viewName"] as? String,
               changedViewName == viewName {
                loadCustomImage()
            }
        }
    }
    
    private func loadCustomImage() {
        let key = viewName == "ContentView" ? "contentBackgroundImage" : "barListBackgroundImage"
        
        if let imageData = UserDefaults.standard.data(forKey: key),
           let image = UIImage(data: imageData) {
            self.customImage = image
        } else {
            self.customImage = nil
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let backgroundImageChanged = Notification.Name("backgroundImageChanged")
}
