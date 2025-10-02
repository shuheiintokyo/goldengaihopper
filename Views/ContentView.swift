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
            
            // Search tab
            NavigationStack {
                BarSearchView(bars: Array(bars), showEnglish: showEnglish) { selectedBar in
                    self.selectedBar = selectedBar
                }
            }
            .tabItem {
                Label(showEnglish ? "Search" : "検索", systemImage: "magnifyingglass")
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
            setupModernTabBarAppearance()
            setupNotifications()
            
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
            print("🔄 Bars count changed: \(oldCount) → \(newCount)")
            if newCount > 0 && shuffledBars.isEmpty {
                print("🎲 Shuffling \(newCount) bars...")
                shuffledBars = Array(bars).shuffled()
                isDataReady = true
                print("✅ Cards ready! isDataReady = \(isDataReady)")
            }
        }
        .sheet(item: $selectedBar) { bar in
            NavigationStack {
                BarDetailView(bar: bar)
            }
        }
    }
    
    private func setupModernTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        let normalColor = UIColor.label.withAlphaComponent(0.6)
        let selectedColor = UIColor.systemBlue
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        tabBarAppearance.selectionIndicatorTintColor = selectedColor.withAlphaComponent(0.1)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
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

// MARK: - Search View
struct BarSearchView: View {
    let bars: [Bar]
    let showEnglish: Bool
    let onSelectBar: (Bar) -> Void
    
    @State private var searchText = ""
    
    var filteredBars: [Bar] {
        if searchText.isEmpty {
            return bars
        }
        
        return bars.filter { bar in
            let barName = getBarDisplayName(for: bar)
            return barName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func getBarDisplayName(for bar: Bar) -> String {
        let defaultName = bar.name ?? ""
        if showEnglish {
            return BarNameTranslation.nameMap[defaultName] ?? defaultName
        }
        return defaultName
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text(showEnglish ? "Search Bars" : "バー検索")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    searchBarView
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                resultsListView
            }
        }
        .navigationBarHidden(true)
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(
                showEnglish ? "Search bars..." : "バーを検索...",
                text: $searchText
            )
            .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
        )
    }
    
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredBars, id: \.uuid) { bar in
                    searchResultRow(for: bar)
                }
            }
            .padding(.top, 1)
        }
    }
    
    private func searchResultRow(for bar: Bar) -> some View {
        Button(action: {
            onSelectBar(bar)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getBarDisplayName(for: bar).isEmpty ?
                        (showEnglish ? "Unknown" : "不明") :
                        getBarDisplayName(for: bar))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if bar.isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .padding(.horizontal)
    }
}
