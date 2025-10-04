// MapView.swift - Simple Merged Cells with Centered Names
import SwiftUI
import CoreData

struct MapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    @State private var highlightedBarUUID: String?
    @AppStorage("showEnglish") var showEnglish = false
    @AppStorage("pendingBarHighlight") private var pendingBarHighlight: String = ""
    
    @State private var scrollViewSize: CGSize = .zero
    @State private var scrollProxy: ScrollViewProxy?
    
    private let cellSize: CGFloat = 80
    
    var body: some View {
        ZStack {
            DynamicBackgroundImage(viewName: "MapView", defaultImageName: "BarMapBackground")
                .ignoresSafeArea()
            
            VStack {
                // Language toggle button
                Button(action: {
                    showEnglish.toggle()
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text(showEnglish ? "Switch to Japanese" : "Switch to English")
                    }
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        ScrollViewReader { proxy in
                            VStack(spacing: 0) {
                                ForEach(0..<35) { row in
                                    HStack(spacing: 0) {
                                        ForEach(0..<21) { column in
                                            cellView(for: row, column: column)
                                                .id("\(row)-\(column)")
                                        }
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding()
                            .onAppear {
                                scrollProxy = proxy
                                processPendingHighlight(with: proxy)
                            }
                            .onChange(of: highlightedBarUUID) { oldValue, newValue in
                                if let uuid = newValue,
                                   let highlightedBar = bars.first(where: { $0.uuid == uuid }) {
                                    let row = Int(highlightedBar.locationRow)
                                    let column = Int(highlightedBar.locationColumn)
                                    
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            proxy.scrollTo("\(row)-\(column)", anchor: .center)
                                        }
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                        if self.highlightedBarUUID == uuid {
                                            self.highlightedBarUUID = nil
                                        }
                                    }
                                }
                            }
                            .onChange(of: pendingBarHighlight) { oldValue, newValue in
                                if !newValue.isEmpty && newValue != oldValue {
                                    processPendingHighlight(with: proxy)
                                }
                            }
                        }
                    }
                    .onAppear {
                        scrollViewSize = geometry.size
                    }
                }
            }
        }
        .navigationTitle(showEnglish ? "Golden Gai Map" : "ゴールデン街マップ")
        .navigationDestination(for: Bar.self) { bar in
            BarDetailView(bar: bar)
        }
        .sheet(item: $selectedBar) { bar in
            NavigationStack {
                BarDetailView(bar: bar)
            }
        }
        .onAppear {
            setupNotificationObserver()
            reinforceTabBarAppearance()
        }
        .onDisappear {
            highlightedBarUUID = nil
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
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.forEach { window in
                window.allSubviews.compactMap { $0 as? UITabBar }.forEach { tabBar in
                    tabBar.standardAppearance = appearance
                    tabBar.scrollEdgeAppearance = appearance
                }
            }
        }
    }
    
    private func processPendingHighlight(with proxy: ScrollViewProxy) {
        guard !pendingBarHighlight.isEmpty else { return }
        
        let uuid = pendingBarHighlight
        pendingBarHighlight = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.highlightedBarUUID = uuid
            
            if let bar = self.bars.first(where: { $0.uuid == uuid }) {
                let row = Int(bar.locationRow)
                let column = Int(bar.locationColumn)
                
                withAnimation {
                    proxy.scrollTo("\(row)-\(column)", anchor: .center)
                }
                
                print("✅ First-time highlight successful for bar: \(bar.name ?? "unknown") at (\(row), \(column))")
            }
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HighlightBar"),
            object: nil,
            queue: .main) { notification in
                if let uuid = notification.userInfo?["barUUID"] as? String {
                    self.highlightedBarUUID = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.highlightedBarUUID = uuid
                    }
                }
            }
    }
    
    // MARK: - Cell View with Simple Merged Cell Logic
    private func cellView(for row: Int, column: Int) -> some View {
        // Find bar at this exact position
        let bar = findBar(at: row, column: column)
        
        // Check if this cell is occupied by a merged bar from a different position
        if bar == nil {
            if let occupyingBar = findBarOccupyingThisCell(row: row, column: column) {
                // This cell is part of a merged bar, render as empty WITH FIXED SIZE to maintain grid
                return AnyView(
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                )
            }
        }
        
        // Calculate dimensions based on span
        let hSpan = bar?.cellSpanHorizontal ?? 1
        let vSpan = bar?.cellSpanVertical ?? 1
        
        // IMPORTANT: Frame size stays at cellSize to maintain grid alignment
        // The content will extend beyond using overlay
        let bgColor = cellBackgroundColor(for: bar)
        
        return AnyView(
            ZStack {
                // Base cell - maintains grid size
                Color.clear
                    .frame(width: cellSize, height: cellSize)
                
                // Overlay the actual merged cell content
                if let bar = bar {
                    ZStack {
                        // Background with border - extended size
                        Rectangle()
                            .fill(bgColor)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Bar name - centered in the merged cell area
                        if showEnglish {
                            ZStack {
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .cornerRadius(4)
                                
                                Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(3)
                            }
                            .padding(3)
                        } else {
                            Text(bar.name ?? "")
                                .font(.system(size: 10))
                                .multilineTextAlignment(.center)
                                .lineLimit(Int(vSpan) + 1)
                                .padding(2)
                        }
                    }
                    .frame(width: cellSize * CGFloat(hSpan), height: cellSize * CGFloat(vSpan))
                    .offset(
                        x: cellSize * CGFloat(hSpan - 1) / 2,
                        y: cellSize * CGFloat(vSpan - 1) / 2
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.selectedBar = bar
                    }
                    .onLongPressGesture(minimumDuration: 3) {
                        bar.isVisited = !bar.isVisited
                        try? viewContext.save()
                    }
                } else {
                    // Empty cell
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .frame(width: cellSize, height: cellSize)
        )
    }
    
    private func cellBackgroundColor(for bar: Bar?) -> Color {
        guard let bar = bar else {
            return Color.white.opacity(0.1)
        }
        
        if bar.isVisited {
            return Color.green.opacity(0.6)
        }
        
        if bar.uuid == highlightedBarUUID {
            return Color.blue.opacity(0.7)
        }
        
        return Color.gray.opacity(0.15)
    }
    
    // Find bar that starts at this exact position
    private func findBar(at row: Int, column: Int) -> Bar? {
        bars.first { Int($0.locationRow) == row && Int($0.locationColumn) == column }
    }
    
    // Check if a bar starting elsewhere occupies this cell
    private func findBarOccupyingThisCell(row: Int, column: Int) -> Bar? {
        bars.first { bar in
            let startRow = Int(bar.locationRow)
            let startCol = Int(bar.locationColumn)
            let hSpan = Int(bar.cellSpanHorizontal)
            let vSpan = Int(bar.cellSpanVertical)
            
            // Check if this cell falls within the bar's span
            let isInRowRange = row >= startRow && row < (startRow + vSpan)
            let isInColRange = column >= startCol && column < (startCol + hSpan)
            
            // Must be within range but NOT at the origin (origin is handled by findBar)
            return isInRowRange && isInColRange && !(row == startRow && column == startCol)
        }
    }
}
