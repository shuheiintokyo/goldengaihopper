import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    @State private var showingBarDetail = false
    
    var body: some View {
        TabView(selection: $selection) {
            // Home tab with horizontal scrolling
            VStack {
                Text("Golden Peace")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(bars, id: \.uuid) { bar in
                            barCell(for: bar)
                                .frame(width: UIScreen.main.bounds.width - 80)
                                .frame(height: 450)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .sheet(isPresented: $showingBarDetail) {
                if let selectedBar = selectedBar {
                    BarDetailView(bar: selectedBar)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Map tab
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            // List tab
            BarListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
                .tag(2)
        }
    }
    
    private func barCell(for bar: Bar) -> some View {
        Button(action: {
            selectedBar = bar
            showingBarDetail = true
        }) {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(bar.isVisited ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .center) {
                        Text(bar.name ?? "Unknown")
                            .font(.title2)
                            .bold()
                            .padding(.top, 16)
                        
                        Spacer()
                        
                        if bar.isVisited {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Visited")
                                    .foregroundColor(.green)
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
