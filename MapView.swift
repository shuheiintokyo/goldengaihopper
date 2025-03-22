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
    @State private var showEnglishNames: Bool = false  // Toggle for English/Japanese names
    
    // Fixed cell size for the grid
    private let cellSize: CGFloat = 80
    
    var body: some View {
        NavigationView {
            VStack {
                // Language toggle button
                Button(action: {
                    showEnglishNames.toggle()
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text(showEnglishNames ? "Show Japanese" : "Show English")
                    }
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Update the number of rows from 39 to 42
                        ForEach(0..<42) { row in
                            HStack(spacing: 0) {
                                // Column count remains the same at 21
                                ForEach(0..<21) { column in
                                    cellView(for: row, column: column)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Golden Gai Map")
        }
        .sheet(item: $selectedBar) { bar in
            NavigationView {
                BarDetailView(bar: bar)
            }
        }
        .onAppear {
            // Listen for notifications to highlight bars
            NotificationCenter.default.addObserver(forName: NSNotification.Name("HighlightBar"),
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
                // Display cell with appropriate text based on language toggle
                if showEnglishNames {
                    // Black background with white text for English names
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .cornerRadius(4)
                            .padding(2)
                        
                        Text(getEnglishName(for: bar.name ?? ""))
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(3)
                    }
                } else {
                    // Original display for Japanese names
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
    }
    
    private func cellBackgroundColor(for bar: Bar?) -> Color {
        guard let bar = bar else { return Color.white }
        
        if bar.uuid == highlightedBarUUID {
            return Color.blue.opacity(0.5)
        }
        
        if bar.isVisited {
            return Color.green.opacity(0.3)
        }
        
        return Color.gray.opacity(0.1)
    }
    
    private func findBar(at row: Int, column: Int) -> Bar? {
        bars.first { Int($0.locationRow) == row && Int($0.locationColumn) == column }
    }
    
    // Function to get English name for a bar
    private func getEnglishName(for japaneseName: String) -> String {
        return BarNameTranslation.nameMap[japaneseName] ?? japaneseName
    }
}
