import SwiftUI
import Combine

struct BarCardView: View {
    let bar: Bar
    var isIPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    
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
    
    // Adaptive dimensions
    private var topBottomSpacing: CGFloat {
        isIPad ? 35 : 25
    }
    
    private var horizontalPadding: CGFloat {
        isIPad ? 35 : 25
    }
    
    private var imageHeight: CGFloat {
        isIPad ? 380 : 290
    }
    
    private var imageSectionSpacing: CGFloat {
        isIPad ? 30 : 20
    }
    
    private var titleFontSize: CGFloat {
        isIPad ? 28 : 22
    }
    
    private var subtitleFontSize: CGFloat {
        isIPad ? 18 : 15
    }
    
    private var badgeFontSize: CGFloat {
        isIPad ? 14 : 12
    }
    
    private var badgeIconSize: CGFloat {
        isIPad ? 18 : 16
    }
    
    var body: some View {
        ZStack {
            // Clean card background with properly rendered border
            RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                .fill(uniqueColor)
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: isIPad ? 1.5 : 1)
                )
            
            // Main content layout
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: topBottomSpacing)
                
                // Image section - Fixed frame that completely fills with image
                GeometryReader { geometry in
                    ZStack {
                        // Background placeholder (always present)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(uniqueColor.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        
                        // Image on top (if available) - fills the entire frame
                        if let uuid = bar.uuid, let image = ImageManager.loadImage(for: uuid) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: imageHeight)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .id(refreshID)
                        }
                    }
                }
                .frame(height: imageHeight)
                .padding(.horizontal, horizontalPadding)
                
                // Spacing between image and text
                Spacer()
                    .frame(height: imageSectionSpacing)
                
                // Text section - consistent styling regardless of image presence
                VStack(spacing: isIPad ? 14 : 12) {
                    // Main bar name
                    Text(bar.name ?? "Unknown")
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(isIPad ? 2 : 1)
                    
                    // English translation if available
                    if let englishName = englishName {
                        Text(englishName)
                            .font(.system(size: subtitleFontSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    
                    // Visited status badge
                    if bar.isVisited {
                        HStack(spacing: isIPad ? 10 : 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: badgeIconSize))
                                .foregroundColor(.white)
                            
                            Text("VISITED")
                                .font(.system(size: badgeFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, isIPad ? 6 : 5)
                        .padding(.horizontal, isIPad ? 18 : 14)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.25))
                        )
                        .padding(.top, isIPad ? 8 : 6)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                
                // Bottom spacing
                Spacer()
                    .frame(height: topBottomSpacing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isIPad ? 24 : 20))
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
