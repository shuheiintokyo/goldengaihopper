import SwiftUI
import CoreData

struct BarListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var presentedBars: [Bar] = []
    @State private var showingAllBars = false
    @State private var barNameCounts: [String: Int] = [:]
    @AppStorage("showEnglish") var showEnglish = false
    
    private var visitedBars: [Bar] {
        return bars.filter { $0.isVisited }
    }
    
    private var displayedBars: [Bar] {
        return showingAllBars ? Array(bars) : visitedBars
    }
    
    var body: some View {
        ZStack {
            // Custom background image that user can control
            DynamicBackgroundImage(viewName: "BarListView", defaultImageName: "BarListBackground")
                .ignoresSafeArea(.all, edges: .top)
            
            // Semi-transparent overlay - only ignore top safe area, not bottom
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all, edges: .top)
            
            Group {
                if visitedBars.isEmpty && !showingAllBars {
                    // Empty state for visited bars
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text(showEnglish ? "No Visited Bars Yet" : "まだ訪問したバーがありません")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(showEnglish ? "Visit bars to see them appear here" : "バーを訪問するとここに表示されます")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
                                .tint(Color.blue)
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
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
                                        .fill(bar.isVisited ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                                        .padding(.vertical, 4)
                                )
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
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
            if !showingAllBars && visitedBars.isEmpty {
                presentedBars.removeAll()
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

struct BarRowView: View {
    let bar: Bar
    let showEnglish: Bool
    
    var body: some View {
        HStack {
            Image(systemName: bar.isVisited ? "checkmark.circle.fill" : "circle")
                .foregroundColor(bar.isVisited ? .green : .white.opacity(0.6))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                if showEnglish {
                    Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "Unknown")
                        .font(.system(size: 18, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.white)
                } else {
                    Text(bar.name ?? "不明")
                        .font(.system(size: 18, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.white)
                }
                
                Text("Row \(bar.locationRow), Col \(bar.locationColumn)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if let notes = bar.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
    }
}
