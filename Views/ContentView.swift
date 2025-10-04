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
    
    // Shuffled bars - populated once when data loads
    @State private var shuffledBars: [Bar] = []
    @State private var isDataReady = false
    
    var body: some View {
        TabView(selection: $selection) {
            // Home tab with horizontal scrolling cards
            NavigationStack {
                ZStack {
                    // Custom background image that user can control
                    DynamicBackgroundImage(viewName: "ContentView", defaultImageName: "ContentBackground")
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Title - Adaptive for iPad/iPhone
                        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                        Text(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
                            .font(.system(size: isIPad ? 64 : 46, weight: .black))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .padding(.top, isIPad ? 80 : 60)
                            .padding(.bottom, isIPad ? 30 : 20)
                        
                        // Scrolling cards with PEEK effect - Adaptive for iPad/iPhone
                        if isDataReady {
                            GeometryReader { geometry in
                                let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                                let cardWidth = isIPad ?
                                    min(geometry.size.width * 0.45, 400) :
                                    geometry.size.width * 0.78
                                let cardHeight: CGFloat = isIPad ? 550 : 450
                                let horizontalPadding: CGFloat = isIPad ? 40 : 20
                                let cardSpacing: CGFloat = isIPad ? 25 : 15
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: cardSpacing) {
                                        ForEach(shuffledBars, id: \.uuid) { bar in
                                            BarCardView(bar: bar, isIPad: isIPad)
                                                .frame(width: cardWidth)
                                                .frame(height: cardHeight)
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
                                    .padding(.horizontal, horizontalPadding)
                                }
                                .scrollTargetBehavior(.viewAligned)
                                .scrollIndicators(.hidden)
                            }
                        } else {
                            // Loading indicator while data is being shuffled
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text(showEnglish ? "Loading..." : "読み込み中...")
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(for: Bar.self) { bar in
                    BarDetailView(bar: bar)
                }
                .onAppear {
                    reinforceTabBarAppearance()
                }
            }
            .tabItem {
                Label(showEnglish ? "Home" : "ホーム", systemImage: "house.fill")
            }
            .tag(0)
            
            // List tab (now with integrated search)
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
            
            // Info tab
            NavigationStack {
                InfoView()
            }
            .tabItem {
                Label(showEnglish ? "Info" : "情報", systemImage: "info.circle.fill")
            }
            .tag(3)
            
            // Settings tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(showEnglish ? "Settings" : "設定", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .onAppear {
            setupNotifications()
            reinforceTabBarAppearance()
            
            // Initial shuffle
            print("📊 OnAppear - Bars count: \(bars.count)")
            if bars.count > 0 && shuffledBars.isEmpty {
                print("🎲 Shuffling \(bars.count) bars...")
                shuffledBars = Array(bars).shuffled()
                isDataReady = true
                print("✅ Cards ready! isDataReady = \(isDataReady)")
            }
        }
        .onChange(of: bars.count) { oldCount, newCount in
            print("📄 Bars count changed: \(oldCount) → \(newCount)")
            if newCount > 0 && shuffledBars.isEmpty {
                print("🎲 Shuffling \(newCount) bars...")
                shuffledBars = Array(bars).shuffled()
                isDataReady = true
                print("✅ Cards ready! isDataReady = \(isDataReady)")
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            // Reinforce tab bar appearance whenever tab changes
            reinforceTabBarAppearance()
        }
        .sheet(item: $selectedBar) { bar in
            NavigationStack {
                BarDetailView(bar: bar)
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HighlightBar"),
            object: nil,
            queue: .main
        ) { notification in
            if let uuid = notification.userInfo?["barUUID"] as? String,
               bars.first(where: { $0.uuid == uuid }) != nil {
                selection = 2  // Switch to Map tab
            }
        }
    }
    
    private func reinforceTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .dark)
        
        let normalColor = UIColor.white.withAlphaComponent(0.6)
        let selectedColor = UIColor.systemBlue
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        appearance.inlineLayoutAppearance.normal.iconColor = normalColor
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        appearance.compactInlineLayoutAppearance.normal.iconColor = normalColor
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.forEach { window in
                window.allSubviews.compactMap { $0 as? UITabBar }.forEach { tabBar in
                    tabBar.standardAppearance = appearance
                    tabBar.scrollEdgeAppearance = appearance
                }
            }
        }
    }
}
