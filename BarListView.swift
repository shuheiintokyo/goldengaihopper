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
    @State private var barNameCounts: [String: Int] = [:]
    
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
                    .listRowBackground(bar.isVisited ? Color.green.opacity(0.2) : Color.white)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Golden Gai Bars")
            .onAppear {
                countBarNames()
                validateBars()
            }
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
    
    private func countBarNames() {
        // Reset counts
        barNameCounts = [:]
        
        // Count occurrences of each name
        for bar in bars {
            if let name = bar.name {
                barNameCounts[name, default: 0] += 1
            }
        }
    }
    
    private func validateBars() {
        var uuidSet = Set<String>()
        var duplicateCount = 0
        var nilUUIDCount = 0
        
        for bar in bars {
            if let uuid = bar.uuid {
                if uuidSet.contains(uuid) {
                    duplicateCount += 1
                    print("Duplicate UUID found: \(uuid) for bar: \(bar.name ?? "unknown")")
                } else {
                    uuidSet.insert(uuid)
                }
            } else {
                nilUUIDCount += 1
                print("Nil UUID found for bar: \(bar.name ?? "unknown")")
                
                // Attempt to fix bars with nil UUIDs
                bar.uuid = UUID().uuidString
            }
        }
        
        if duplicateCount > 0 || nilUUIDCount > 0 {
            print("Found \(duplicateCount) bars with duplicate UUIDs and \(nilUUIDCount) bars with nil UUIDs")
            // Save the context to persist any fixes
            try? viewContext.save()
        }
    }
}
