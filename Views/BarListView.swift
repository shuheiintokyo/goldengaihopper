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
    @State private var searchText = ""
    @AppStorage("showEnglish") var showEnglish = false
    
    // Helper function to check if a bar is a vacant placeholder
    private func isVacantPlaceholder(_ bar: Bar) -> Bool {
        guard let name = bar.name else { return false }
        return name == "*" || name == "_VACANT_" || name == "---"
    }
    
    private var visitedBars: [Bar] {
        return bars.filter { $0.isVisited && !isVacantPlaceholder($0) }
    }
    
    private var displayedBars: [Bar] {
        let baseBars = showingAllBars ? Array(bars).filter { !isVacantPlaceholder($0) } : visitedBars
        
        // Apply search filter
        if searchText.isEmpty {
            return baseBars
        }
        
        return baseBars.filter { bar in
            let barName = getBarDisplayName(for: bar)
            return barName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func getBarDisplayName(for bar: Bar) -> String {
        let defaultName = bar.name ?? ""
        if showEnglish {
            return BarNameTranslation.nameMap[defaultName] ?? defaultName
        }
        return defaultName
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            DynamicBackgroundImage(viewName: "BarListView", defaultImageName: "BarListBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar at the top
                searchBarSection
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                Group {
                    if visitedBars.isEmpty && !showingAllBars {
                        // Empty state for visited bars
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                            
                            Text(showEnglish ? "No Visited Bars Yet" : "まだ訪問したバーがありません")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                            
                            Text(showEnglish ? "Visit bars to see them appear here" : "バーを訪問するとここに表示されます")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .shadow(radius: 1)
                            
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            // Toggle section
                            Section {
                                HStack {
                                    Spacer()
                                    HStack {
                                        Text(showEnglish ? "Show All Bars" : "全てのバーを表示")
                                            .foregroundColor(.white)
                                            .font(.body)
                                        
                                        Toggle("", isOn: $showingAllBars)
                                            .tint(Color.blue)
                                    }
                                    .padding(.vertical, 8)
                                    Spacer()
                                }
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                    .padding(.horizontal, 4)
                            )
                            
                            // Bars list
                            Section(header:
                                HStack {
                                    Spacer()
                                    Text(showEnglish ?
                                        (showingAllBars ? "All Bars (\(displayedBars.count))" : "Visited Bars (\(displayedBars.count))") :
                                        (showingAllBars ? "全てのバー (\(displayedBars.count))" : "訪問済みバー (\(displayedBars.count))"))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                            ) {
                                ForEach(displayedBars, id: \.uuid) { bar in
                                    NavigationLink(value: bar) {
                                        BarRowView(bar: bar, showEnglish: showEnglish)
                                    }
                                    .listRowBackground(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(bar.isVisited ? Color.green.opacity(0.3) : Color.black.opacity(0.3))
                                            .padding(.vertical, 2)
                                            .padding(.horizontal, 4)
                                    )
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
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
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            
            TextField(
                showEnglish ? "Search bars..." : "バーを検索...",
                text: $searchText
            )
            .textFieldStyle(.plain)
            .foregroundColor(.white)
            .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.4))
        )
    }
    
    private func countBarNames() {
        barNameCounts = [:]
        for bar in bars {
            if let name = bar.name, !isVacantPlaceholder(bar) {
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
        HStack(spacing: 12) {
            // Checkmark icon - fixed width
            Image(systemName: bar.isVisited ? "checkmark.circle.fill" : "circle")
                .foregroundColor(bar.isVisited ? .green : .white.opacity(0.6))
                .font(.title2)
                .frame(width: 24, height: 24)
            
            // Text content - constrained to available width
            VStack(alignment: .leading, spacing: 4) {
                // Bar name - FIX: Added frame with alignment and removed inner HStack
                Group {
                    if showEnglish {
                        Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "Unknown")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Text(bar.name ?? "不明")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Notes preview
                if let notes = bar.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron - fixed width
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 14))
                .frame(width: 14, height: 14)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
