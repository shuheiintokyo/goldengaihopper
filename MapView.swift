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
    @AppStorage("showEnglish") var showEnglish = false  // Use AppStorage instead of State
    
    // Add scroll position tracking
    @State private var scrollPosition: CGPoint = .zero
    @State private var scrollViewSize: CGSize = .zero
    
    // Fixed cell size for the grid
    private let cellSize: CGFloat = 80
    
    var body: some View {
        NavigationView {
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
                        ScrollViewReader { scrollViewProxy in
                            VStack(spacing: 0) {
                                ForEach(0..<35) { row in
                                    HStack(spacing: 0) {
                                        ForEach(0..<21) { column in
                                            cellView(for: row, column: column)
                                                .frame(width: cellSize, height: cellSize)
                                                .id("\(row)-\(column)")
                                        }
                                    }
                                }
                            }
                            .onChange(of: highlightedBarUUID) { oldValue, newValue in
                                if let uuid = newValue,
                                   let highlightedBar = bars.first(where: { $0.uuid == uuid }) {
                                    let row = Int(highlightedBar.locationRow)
                                    let column = Int(highlightedBar.locationColumn)
                                    withAnimation {
                                        scrollViewProxy.scrollTo("\(row)-\(column)", anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        scrollViewSize = geometry.size
                    }
                }
            }
            .navigationTitle(showEnglish ? "Golden Gai Map" : "ゴールデン街マップ")
        }
        .sheet(item: $selectedBar) { bar in
            NavigationView {
                BarDetailView(bar: bar)
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("HighlightBar"),
                object: nil,
                queue: .main) { notification in
                    if let uuid = notification.userInfo?["barUUID"] as? String {
                        self.highlightedBarUUID = uuid
                    }
                }
        }
    }
    
    private func cellView(for row: Int, column: Int) -> some View {
        let bar = findBar(at: row, column: column)
        
        return ZStack {
            Rectangle()
                .fill(cellBackgroundColor(for: bar))
                .border(Color.gray.opacity(0.2), width: 0.5)
            
            if let bar = bar {
                if showEnglish {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .cornerRadius(4)
                            .padding(2)
                        
                        Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "")
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(3)
                    }
                } else {
                    Text(bar.name ?? "")
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let bar = bar {
                self.selectedBar = bar
            }
        }
        .onLongPressGesture(minimumDuration: 3) {
            if let bar = bar {
                bar.isVisited = !bar.isVisited
                try? viewContext.save()
            }
        }
    }
    
    private func cellBackgroundColor(for bar: Bar?) -> Color {
        guard let bar = bar else { return Color.white }
        
        if bar.isVisited {
            return Color.green.opacity(0.3)
        }
        
        if bar.uuid == highlightedBarUUID {
            return Color.blue.opacity(0.5)
        }
        
        return Color.gray.opacity(0.1)
    }
    
    private func findBar(at row: Int, column: Int) -> Bar? {
        bars.first { Int($0.locationRow) == row && Int($0.locationColumn) == column }
    }
}
