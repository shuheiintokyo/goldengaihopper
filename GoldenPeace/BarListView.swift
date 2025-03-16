import SwiftUI
import CoreData

struct BarListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var showingVisitedOnly = false
    
    var body: some View {
        List {
            Toggle("Show Visited Only", isOn: $showingVisitedOnly)
                .padding(.vertical, 8)
            
            ForEach(filteredBars, id: \.uuid) { bar in
                NavigationLink(destination: BarDetailView(bar: bar)) {
                    HStack {
                        Text(bar.name ?? "Unknown")
                        Spacer()
                        if bar.isVisited {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Golden Gai Bars")
    }
    
    private var filteredBars: [Bar] {
        if showingVisitedOnly {
            return bars.filter { $0.isVisited }
        } else {
            return Array(bars)
        }
    }
}
