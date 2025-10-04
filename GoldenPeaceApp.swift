// GoldenPeaceApp.swift - Fixed Tab Bar Appearance
import SwiftUI
import CoreData

@main
struct GoldenPeaceApp: App {
    let persistenceController = PersistenceController.shared
    let dataImportService: DataImportService
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    init() {
        dataImportService = DataImportService(persistenceController: persistenceController)
        
        // IMPORTANT: Set tab bar appearance AFTER stored properties initialized
        setupTabBarAppearance()
        
        dataImportService.importInitialData()
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onAppear {
                        // Reinforce tab bar appearance when view appears
                        reinforceTabBarAppearance()
                        checkForRemoteUpdates()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        checkForRemoteUpdates()
                    }
            } else {
                LoginView()
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Dark, semi-transparent background
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .dark)
        
        // Colors for tab items
        let normalColor = UIColor.white.withAlphaComponent(0.6)
        let selectedColor = UIColor.systemBlue
        
        // Configure all layout appearances
        configureItemAppearance(appearance.stackedLayoutAppearance, normal: normalColor, selected: selectedColor)
        configureItemAppearance(appearance.inlineLayoutAppearance, normal: normalColor, selected: selectedColor)
        configureItemAppearance(appearance.compactInlineLayoutAppearance, normal: normalColor, selected: selectedColor)
        
        // Apply globally with FORCED setting
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Ensure iOS 15+ doesn't override
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Force all existing tab bars to update immediately
        DispatchQueue.main.async {
            UIApplication.shared.windows.forEach { window in
                window.allSubviews.compactMap { $0 as? UITabBar }.forEach { tabBar in
                    tabBar.standardAppearance = appearance
                    tabBar.scrollEdgeAppearance = appearance
                }
            }
        }
    }
    
    private func reinforceTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .dark)
        
        let normalColor = UIColor.white.withAlphaComponent(0.6)
        let selectedColor = UIColor.systemBlue
        
        configureItemAppearance(appearance.stackedLayoutAppearance, normal: normalColor, selected: selectedColor)
        configureItemAppearance(appearance.inlineLayoutAppearance, normal: normalColor, selected: selectedColor)
        configureItemAppearance(appearance.compactInlineLayoutAppearance, normal: normalColor, selected: selectedColor)
        
        // Reinforce the appearance settings
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.allSubviews.forEach { view in
                        if let tabBar = view as? UITabBar {
                            tabBar.standardAppearance = appearance
                            tabBar.scrollEdgeAppearance = appearance
                        }
                    }
                }
            }
        }
    }
    
    private func configureItemAppearance(_ itemAppearance: UITabBarItemAppearance, normal: UIColor, selected: UIColor) {
        // Normal state
        itemAppearance.normal.iconColor = normal
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: normal,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state
        itemAppearance.selected.iconColor = selected
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: selected,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
    }
    
    private func checkForRemoteUpdates() {
        let context = persistenceController.container.viewContext
        
        RemoteDataService.shared.checkForUpdates(context: context) { success in
            if success {
                print("✅ Remote update successful")
                NotificationCenter.default.post(
                    name: NSNotification.Name("BarDataUpdated"),
                    object: nil
                )
            } else {
                print("ℹ️ No updates needed")
            }
        }
    }
}

// Helper extension to get all subviews
extension UIView {
    var allSubviews: [UIView] {
        var subs = subviews
        for subview in subviews {
            subs.append(contentsOf: subview.allSubviews)
        }
        return subs
    }
}
