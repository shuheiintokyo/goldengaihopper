import SwiftUI
import Combine

struct BarCardView: View {
    let bar: Bar
    
    @State private var refreshID = UUID()
    @State private var imageUpdateSubscription: AnyCancellable?
    
    private var englishName: String? {
        guard let japaneseName = bar.name,
              let translation = BarNameTranslation.nameMap[japaneseName],
              translation != japaneseName else {
            return nil
        }
        return translation
    }
    
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
            // Card background
            RoundedRectangle(cornerRadius: 22)
                .fill(uniqueColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                )
            
            // IMPORTANT CHANGE: Set fixed and equal insets for all content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 20)
                
                // IMPORTANT CHANGE: Image has fixed insets on all sides
                if let uuid = bar.uuid, let image = ImageManager.loadImage(for: uuid) {
                    // Real image with equal margins on both sides
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .padding(.horizontal, 25) // FIXED EQUAL PADDING
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .id(refreshID)
                } else {
                    // Placeholder with equal margins on both sides
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(uniqueColor)
                            .frame(height: 220)
                        
                        Text(bar.name ?? "Unknown")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.horizontal, 25) // FIXED EQUAL PADDING
                    .id(refreshID)
                }
                
                Spacer()
                    .frame(height: 25)
                
                // Name section - same padding as image for consistency
                VStack(spacing: 12) {
                    Text(bar.name ?? "Unknown")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if let englishName = englishName {
                        Text(englishName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.top, 5)
                    }
                    
                    if bar.isVisited {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                            
                            Text("VISITED")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.2))
                        )
                        .padding(.top, 15)
                    }
                }
                .padding(.horizontal, 25) // FIXED EQUAL PADDING
                
                Spacer()
            }
        }
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
