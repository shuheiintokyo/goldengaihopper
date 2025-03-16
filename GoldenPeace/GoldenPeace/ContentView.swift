import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            BarListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
                .tag(1)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(2)
        }
    }
}

// New HomeView for the horizontal scrolling bar view
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    @State private var showingBarDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Title header
                Text("Golden Gai")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Main scrollable content - fullscreen width
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                        ForEach(bars, id: \.uuid) { bar in
                            barCell(for: bar)
                                .frame(width: UIScreen.main.bounds.width - 40)
                        }
                    }
                    .padding()
                }
                .frame(height: 350)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingBarDetail) {
                if let selectedBar = selectedBar {
                    BarDetailView(bar: selectedBar)
                }
            }
        }
    }
    
    private func barCell(for bar: Bar) -> some View {
        Button(action: {
            selectedBar = bar
            showingBarDetail = true
        }) {
            VStack {
                // Square cell but bigger to fill most of the screen
                ZStack {
                    Rectangle()
                        .fill(bar.isVisited ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                    VStack(spacing: 16) {
                        Text(bar.name ?? "Unknown")
                            .font(.title)
                            .bold()
                            .padding(.top)
                        
                        if bar.isVisited {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Visited")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        Text("Tap for details")
                            .font(.caption)
                            .padding(.bottom)
                    }
                    .padding()
                }
                .frame(height: 300)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
