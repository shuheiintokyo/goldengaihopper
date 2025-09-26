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
    
    var body: some View {
        TabView(selection: $selection) {
            // Home tab with horizontal scrolling cards
            NavigationStack {
                ZStack {
                    // Custom background image that user can control
                    DynamicBackgroundImage(viewName: "ContentView", defaultImageName: "ContentBackground")
                        .ignoresSafeArea()
                    
                    // REMOVED the extra overlay that was making it darker
                    // Color.black.opacity(0.3) was here
                    
                    VStack(spacing: 0) {
                        // Title
                        Text(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
                            .font(.system(size: 46, weight: .black))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .padding(.top, 60)
                            .padding(.bottom, 20)
                        
                        // Scrolling cards with PEEK effect
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 15) {
                                    ForEach(bars.indices, id: \.self) { index in
                                        let bar = bars[index]
                                        BarCardView(bar: bar)
                                            .frame(width: geometry.size.width * 0.78)
                                            .frame(height: 450)
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
                                .padding(.horizontal, 20)
                            }
                            .scrollTargetBehavior(.viewAligned)
                            .scrollIndicators(.hidden)
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
            
            // Search tab - Now a regular view
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
        
        // Modern blur effect with lighter appearance
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        // Modern tab colors
        let normalColor = UIColor.label.withAlphaComponent(0.6)
        let selectedColor = UIColor.systemBlue
        
        // Configure normal state
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Configure selected state
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Add subtle selected indicator background
        tabBarAppearance.selectionIndicatorTintColor = selectedColor.withAlphaComponent(0.1)
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Remove top border for cleaner look
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

// MARK: - Search View (Now a full view, not a sheet)
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
            // Consistent background with other views
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
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
                    
                    Text("Row \(bar.locationRow), Col \(bar.locationColumn)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if bar.isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .padding(.horizontal)
    }
}
