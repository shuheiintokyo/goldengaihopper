import SwiftUI
import CoreData

struct BarListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var showingVisitedOnly = false
    @State private var selectedBar: Bar?
    @State private var showingBarDetail = false
    
    var body: some View {
        NavigationView {
            List {
                Toggle("Show Visited Only", isOn: $showingVisitedOnly)
                    .padding(.vertical, 8)
                
                ForEach(filteredBars, id: \.uuid) { bar in
                    Button(action: {
                        selectedBar = bar
                        showingBarDetail = true
                    }) {
                        HStack {
                            Text(bar.name ?? "Unknown")
                            Spacer()
                            if bar.isVisited {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Golden Gai Bars")
            .sheet(isPresented: $showingBarDetail) {
                if let selectedBar = selectedBar {
                    BarDetailView(bar: selectedBar)
                }
            }
        }
    }
    
    private var filteredBars: [Bar] {
        if showingVisitedOnly {
            return bars.filter { $0.isVisited }
        } else {
            return Array(bars)
        }
    }
}
