import SwiftUI
import Combine

struct BarCardView: View {
    let bar: Bar
    
    @State private var refreshID = UUID()
    @State private var imageUpdateSubscription: AnyCancellable?
    
    // Get English translation if available
    private var englishName: String? {
        guard let japaneseName = bar.name,
              let translation = BarNameTranslation.nameMap[japaneseName],
              translation != japaneseName else {
            return nil
        }
        return translation
    }
    
    // Generate unique gradient color based on bar name
    private var uniqueColor: LinearGradient {
        let nameHash = (bar.name ?? "Unknown").hash
        let baseColor = Color(
            red: 0.5 + Double((nameHash & 0xFF0000) >> 16) / 512.0,
            green: 0.5 + Double((nameHash & 0x00FF00) >> 8) / 512.0,
            blue: 0.5 + Double(nameHash & 0x0000FF) / 512.0
        )
        
        return LinearGradient(
            gradient: Gradient(colors: [
                bar.isVisited ? Color.green.opacity(0.6) : baseColor.opacity(0.7),
                bar.isVisited ? Color.green.opacity(0.4) : baseColor.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            // Card background with rounded corners and border
            RoundedRectangle(cornerRadius: 22)
                .fill(uniqueColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                )
            
            // Main content layout
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 20)
                
                // Image section - expanded to take more space
                if let uuid = bar.uuid, let image = ImageManager.loadImage(for: uuid) {
                    // Display actual uploaded image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 320) // Expanded from 220 to 320
                        .padding(.horizontal, 25)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .id(refreshID)
                } else {
                    // Empty placeholder - just colored rectangle without text
                    RoundedRectangle(cornerRadius: 18)
                        .fill(uniqueColor.opacity(0.3)) // Lighter version of the card color
                        .frame(height: 320) // Same size as image
                        .padding(.horizontal, 25)
                        .id(refreshID)
                }
                
                // Spacing between image and text
                Spacer()
                    .frame(height: 15)
                
                // Text section - consistent styling regardless of image presence
                VStack(spacing: 12) {
                    // Main bar name
                    Text(bar.name ?? "Unknown")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    // English translation if available
                    if let englishName = englishName {
                        Text(englishName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    
                    // Visited status badge
                    if bar.isVisited {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            
                            Text("VISITED")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.2))
                        )
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 25)
                
                // Bottom spacing
                Spacer()
            }
        }
        // Listen for image update notifications
        .onAppear {
            imageUpdateSubscription = NotificationCenter.default.publisher(
                for: NSNotification.Name("ImageUpdated")
            )
            .sink { notification in
                if let uuid = notification.userInfo?["barUUID"] as? String,
                   uuid == bar.uuid {
                    refreshID = UUID()
                }
            }
        }
    }
}
