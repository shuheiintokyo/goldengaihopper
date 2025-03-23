import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bar.name, ascending: true)],
        animation: .default)
    private var bars: FetchedResults<Bar>
    
    @State private var selectedBar: Bar?
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showEnglish") var showEnglish = false
    @AppStorage("isLoggedIn") var isLoggedIn = true
    
    var body: some View {
        TabView(selection: $selection) {
            // Home tab with horizontal scrolling cards
            ZStack {
                // Background color
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title
                    Text(showEnglish ? "Golden Gai Bars" : "ゴールデン街バー")
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                    
                    // Scrolling cards with balanced height
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 25) {
                            Spacer(minLength: 5)
                            
                            ForEach(bars, id: \.uuid) { bar in
                                BarCardView(bar: bar)
                                    .frame(width: UIScreen.main.bounds.width * 0.85)
                                    .frame(height: 480)
                                    .onTapGesture {
                                        selectedBar = bar
                                    }
                                    .scrollTransition { content, phase in
                                        content
                                            .opacity(phase.isIdentity ? 1.0 : 0.6)
                                            .scaleEffect(phase.isIdentity ? 1.0 : 0.9)
                                            .offset(y: phase.isIdentity ? 0 : 15)
                                            .blur(radius: phase.isIdentity ? 0 : 1)
                                    }
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .scrollTargetLayout()
                        .padding(.vertical, 10)
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .frame(height: UIScreen.main.bounds.height * 0.65)
                    
                    Spacer()
                }
            }
            .tabItem {
                Label(showEnglish ? "Home" : "ホーム", systemImage: "house.fill")
            }
            .tag(0)
            
            // List tab
            BarListView()
                .tabItem {
                    Label(showEnglish ? "List" : "リスト", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Map tab
            MapView()
                .tabItem {
                    Label(showEnglish ? "Map" : "マップ", systemImage: "map")
                }
                .tag(2)
            
            // Logout tab
            VStack {
                Spacer()
                Text(showEnglish ? "Are you sure you want to log out?" : "ログアウトしますか？")
                    .font(.headline)
                    .padding()
                
                Button(action: {
                    isLoggedIn = false
                }) {
                    Text(showEnglish ? "Log Out" : "ログアウト")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                Spacer()
            }
            .tabItem {
                Label(showEnglish ? "Logout" : "ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .tag(3)
        }
        .sheet(item: $selectedBar) { bar in
            NavigationView {
                BarDetailView(bar: bar)
            }
        }
        .onAppear {
            setupNotifications()
        }
    }
    
    // MARK: - Helper methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HighlightBar"),
            object: nil,
            queue: .main
        ) { notification in
            if let uuid = notification.userInfo?["barUUID"] as? String,
               bars.first(where: { $0.uuid == uuid }) != nil {
                selection = 2
            }
        }
    }
}
