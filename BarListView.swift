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
    @AppStorage("showEnglish") var showEnglish = false
    
    var body: some View {
        NavigationView {
            List {
                Toggle(showEnglish ? "Show Visited Only" : "訪問済みのみ表示", isOn: $showingVisitedOnly)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                
                ForEach(filteredBars, id: \.uuid) { bar in
                    Button(action: {
                        selectedBar = bar
                    }) {
                        HStack {
                            if showEnglish {
                                Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "Unknown")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text(bar.name ?? "不明")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            if bar.isVisited {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(bar.isVisited ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                            .padding(.vertical, 4)
                    )
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .listStyle(PlainListStyle())
            .navigationTitle(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
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
        barNameCounts = [:]
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
                bar.uuid = UUID().uuidString
            }
        }
        
        if duplicateCount > 0 || nilUUIDCount > 0 {
            print("Found \(duplicateCount) bars with duplicate UUIDs and \(nilUUIDCount) bars with nil UUIDs")
            try? viewContext.save()
        }
    }
}
