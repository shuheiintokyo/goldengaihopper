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
    
    var body: some View {
        NavigationView {
            List {
                Toggle("Show Visited Only", isOn: $showingVisitedOnly)
                    .padding(.vertical, 8)
                
                ForEach(filteredBars, id: \.uuid) { bar in
                    Button(action: {
                        selectedBar = bar
                    }) {
                        HStack {
                            Text(bar.name ?? "Unknown")
                                .font(.body)
                            
                            Spacer()
                            
                            if bar.isVisited {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .padding(.trailing, 4)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Golden Gai Bars")
        }
        .sheet(item: $selectedBar) { bar in
            NavigationView {
                BarDetailView(bar: bar)
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
