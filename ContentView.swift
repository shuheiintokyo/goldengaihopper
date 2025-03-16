import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    
    // Environment for responsive layout
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        TabView(selection: $selection) {
            // Home tab with horizontal scrolling
            VStack(spacing: 0) {
                Text("Golden Peace")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Add leading spacer to center first item
                            Spacer(minLength: 16)
                            
                            ForEach(bars, id: \.uuid) { bar in
                                barCell(for: bar, width: geometry.size.width * 0.85)
                                    .frame(width: geometry.size.width * 0.85)
                                    // Increase height to use more vertical space
                                    .frame(height: geometry.size.height * 0.9)
                                    .scrollTransition { content, phase in
                                        content
                                            .opacity(phase.isIdentity ? 1.0 : 0.5)
                                            .scaleEffect(x: phase.isIdentity ? 1.0 : 0.8,
                                                         y: phase.isIdentity ? 1.0 : 0.8)
                                            .offset(y: phase.isIdentity ? 0 : 30)
                                    }
                            }
                            
                            // Add trailing spacer to center last item
                            Spacer(minLength: 16)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
                .frame(height: UIScreen.main.bounds.height * 0.7) // Increased height for more vertical space
                
                Spacer()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // List tab (middle)
            BarListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Map tab (right)
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(2)
        }
        .sheet(item: $selectedBar) { bar in
            NavigationView {
                BarDetailView(bar: bar)
            }
        }
        .onAppear {
            // Listen for notifications to highlight bars on the map
            NotificationCenter.default.addObserver(forName: NSNotification.Name("HighlightBar"),
                                                  object: nil,
                                                  queue: .main) { notification in
                if let uuid = notification.userInfo?["barUUID"] as? String,
                   bars.first(where: { $0.uuid == uuid }) != nil {
                    // Switch to the map tab and highlight the bar
                    selection = 2
                }
            }
        }
    }
    
    private func barCell(for bar: Bar, width: CGFloat) -> some View {
        Button(action: {
            selectedBar = bar
        }) {
            ZStack(alignment: .bottom) {
                // Background with conditional color based on visited status
                Rectangle()
                    .fill(bar.isVisited ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(16)
                
                VStack(spacing: 0) {
                    // Check if we have a saved image for this bar
                    if let uuid = bar.uuid, let image = ImageManager.loadImage(for: uuid) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // Make image take up most of the card space
                            .frame(width: width - 24, height: width * 0.8)
                            .cornerRadius(12)
                            .padding(.top, 12)
                            .clipped()
                    } else {
                        // Placeholder when no image
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: width - 24, height: width * 0.5)
                            .cornerRadius(12)
                            .padding(.top, 12)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Bar name
                    Text(bar.name ?? "Unknown")
                        .font(.title2)
                        .bold()
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .multilineTextAlignment(.center)
                    
                    // Visit status indicator (only shows a dot, no text)
                    if bar.isVisited {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 22))
                        }
                        .padding(.bottom, 12)
                    } else {
                        Spacer()
                            .frame(height: 12)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
