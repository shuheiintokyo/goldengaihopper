import SwiftUI
import CoreData

struct MapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    @State private var showingBarDetail = false
    
    // Fixed cell size for the grid
    private let cellSize: CGFloat = 80
    
    var body: some View {
        NavigationView {
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(spacing: 0) {
                    // Create rows for the grid
                    ForEach(0..<39) { row in
                        HStack(spacing: 0) {
                            // Create columns for each row
                            ForEach(0..<21) { column in
                                cellView(for: row, column: column)
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Golden Gai Map")
            .sheet(isPresented: $showingBarDetail, content: {
                if let selectedBar = selectedBar {
                    BarDetailView(bar: selectedBar)
                }
            })
        }
    }
    
    private func cellView(for row: Int, column: Int) -> some View {
        let bar = findBar(at: row, column: column)
        
        return ZStack {
            Rectangle()
                .fill(cellBackgroundColor(for: bar))
                .border(Color.gray.opacity(0.2), width: 0.5)
            
            if let bar = bar {
                Text(bar.name ?? "")
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let bar = bar {
                self.selectedBar = bar
                self.showingBarDetail = true
            }
        }
    }
    
    private func cellBackgroundColor(for bar: Bar?) -> Color {
        guard let bar = bar else { return Color.white }
        
        if bar.isVisited {
            return Color.green.opacity(0.3)
        }
        
        if bar == selectedBar {
            return Color.blue.opacity(0.3)
        }
        
        return Color.gray.opacity(0.1)
    }
    
    private func findBar(at row: Int, column: Int) -> Bar? {
        bars.first { Int($0.locationRow) == row && Int($0.locationColumn) == column }
    }
}
