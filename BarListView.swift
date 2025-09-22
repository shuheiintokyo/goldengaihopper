import SwiftUI
import CoreData

struct BarListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    // NavigationStack state management
    @State private var presentedBars: [Bar] = []
    
    @State private var showingAllBars = false
    @State private var barNameCounts: [String: Int] = [:]
    @AppStorage("showEnglish") var showEnglish = false
    
    // Computed property for visited bars
    private var visitedBars: [Bar] {
        return bars.filter { $0.isVisited }
    }
    
    // Computed property for all bars or visited only
    private var displayedBars: [Bar] {
        return showingAllBars ? Array(bars) : visitedBars
    }
    
    var body: some View {
        NavigationStack(path: $presentedBars) {
            Group {
                if visitedBars.isEmpty && !showingAllBars {
                    // Empty state for visited bars
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(showEnglish ? "No Visited Bars Yet" : "まだ訪問したバーがありません")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text(showEnglish ? "Visit bars to see them appear here" : "バーを訪問するとここに表示されます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showingAllBars = true
                        }) {
                            Text(showEnglish ? "Show All Bars" : "全てのバーを表示")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        // Toggle section
                        Section {
                            Toggle(showEnglish ? "Show All Bars" : "全てのバーを表示", isOn: $showingAllBars)
                                .padding(.vertical, 8)
                        }
                        
                        // Bars list
                        Section(header: Text(showEnglish ?
                            (showingAllBars ? "All Bars (\(bars.count))" : "Visited Bars (\(visitedBars.count))") :
                            (showingAllBars ? "全てのバー (\(bars.count))" : "訪問済みバー (\(visitedBars.count))"))) {
                            
                            ForEach(displayedBars, id: \.uuid) { bar in
                                NavigationLink(value: bar) {
                                    BarRowView(bar: bar, showEnglish: showEnglish)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(bar.isVisited ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                                        .padding(.vertical, 4)
                                )
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
            .navigationDestination(for: Bar.self) { bar in
                BarDetailView(bar: bar)
            }
            .onAppear {
                countBarNames()
                validateBars()
            }
            .onChange(of: bars.map { $0.isVisited }) { oldValue, newValue in
                // React to changes in visited status
                if !showingAllBars && visitedBars.isEmpty {
                    // If we're showing visited only and no bars are visited,
                    // clear the navigation stack
                    presentedBars.removeAll()
                }
            }
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

// MARK: - Custom Row View
struct BarRowView: View {
    let bar: Bar
    let showEnglish: Bool
    
    var body: some View {
        HStack {
            // Bar status indicator
            Image(systemName: bar.isVisited ? "checkmark.circle.fill" : "circle")
                .foregroundColor(bar.isVisited ? .green : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Bar name
                if showEnglish {
                    Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "Unknown")
                        .font(.system(size: 18, weight: .medium))
                        .lineLimit(1)
                } else {
                    Text(bar.name ?? "不明")
                        .font(.system(size: 18, weight: .medium))
                        .lineLimit(1)
                }
                
                // Location info
                Text("Row \(bar.locationRow), Col \(bar.locationColumn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Notes preview if available
                if let notes = bar.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Navigation indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    BarListView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
