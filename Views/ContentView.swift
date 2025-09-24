import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showEnglish") var showEnglish = false
    @AppStorage("isLoggedIn") var isLoggedIn = true
    
    var body: some View {
        TabView(selection: $selection) {
            // Home tab with horizontal scrolling cards
            NavigationStack {
                GeometryReader { geometry in
                    ZStack {
                        // Custom background image that user can control
                        DynamicBackgroundImage(viewName: "ContentView", defaultImageName: "ContentBackground")
                            .ignoresSafeArea(.all, edges: .top)
                            .clipped() // Prevent background from affecting layout
                        
                        // Semi-transparent overlay for better readability
                        Color.black.opacity(0.3)
                            .ignoresSafeArea(.all, edges: .top)
                        
                        VStack(spacing: 0) {
                            // Title
                            Text(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
                                .font(.system(size: 46, weight: .black))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                                .padding(.top, 30)
                                .padding(.bottom, 20)
                            
                            // Scrolling cards with balanced height
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 0) {
                                    ForEach(bars.indices, id: \.self) { index in
                                        let bar = bars[index]
                                        BarCardView(bar: bar)
                                            .frame(width: geometry.size.width * 0.85)
                                            .frame(height: 450)
                                            .padding(.horizontal, geometry.size.width * 0.075) // 7.5% on each side
                                            .onTapGesture {
                                                selectedBar = bar
                                            }
                                            .scrollTransition { content, phase in
                                                content
                                                    .opacity(phase.isIdentity ? 1.0 : 0.6)
                                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.9)
                                                    .offset(y: phase.isIdentity ? 0 : 15)
                                                    .blur(radius: phase.isIdentity ? 0 : 1)
                                            }
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.viewAligned)
                            .frame(height: geometry.size.height * 0.65)
                            .scrollIndicators(.hidden)
                            
                            Spacer()
                        }
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(for: Bar.self) { bar in
                    BarDetailView(bar: bar)
                }
            }
            .tabItem {
                Label(showEnglish ? "Home" : "ホーム", systemImage: "house.fill")
            }
            .tag(0)
            
            // List tab
            NavigationStack {
                BarListView()
            }
            .tabItem {
                Label(showEnglish ? "List" : "リスト", systemImage: "list.bullet")
            }
            .tag(1)
            
            // Map tab
            NavigationStack {
                MapView()
            }
            .tabItem {
                Label(showEnglish ? "Map" : "マップ", systemImage: "map")
            }
            .tag(2)
            
            // Settings tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(showEnglish ? "Settings" : "設定", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .onAppear {
            setupTabBarAppearance()
            setupNotifications()
        }
        .sheet(item: $selectedBar) { bar in
            NavigationStack {
                BarDetailView(bar: bar)
            }
        }
    }
    
    private func setupTabBarAppearance() {
        // Configure tab bar appearance to make it visible
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        // Configure tab bar item colors
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HighlightBar"),
            object: nil,
            queue: .main
        ) { notification in
            if let uuid = notification.userInfo?["barUUID"] as? String,
               bars.first(where: { $0.uuid == uuid }) != nil {
                selection = 2
            }
        }
    }
}
