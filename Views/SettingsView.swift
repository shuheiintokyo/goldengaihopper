import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("showEnglish") var showEnglish = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var showingLogoutAlert = false
    @State private var showingAbout = false
    @State private var showingUpdateAlert = false
    @State private var updateMessage = ""
    @State private var isCheckingUpdate = false
    @State private var showingImagePicker = false
    @State private var selectedViewForBackground = ""
    @State private var showingBackgroundAlert = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea(.all, edges: .top)
            
            List {
                // Language Settings Section
                Section(header: Text(showEnglish ? "Language" : "言語設定")) {
                    HStack {
                        Text(showEnglish ? "Language" : "言語")
                        Spacer()
                        Picker("", selection: $showEnglish) {
                            Text("日本語").tag(false)
                            Text("English").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                // Background Customization Section
                Section(header: Text(showEnglish ? "Background Images" : "背景画像")) {
                    // Content View Background
                    Button(action: {
                        selectedViewForBackground = "ContentView"
                        showingBackgroundAlert = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(showEnglish ? "Home Page Background" : "ホームページ背景")
                                    .foregroundColor(.primary)
                                Text(showEnglish ? "Tap to change home screen background" : "ホーム画面の背景を変更")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Bar List View Background
                    Button(action: {
                        selectedViewForBackground = "BarListView"
                        showingBackgroundAlert = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(showEnglish ? "Bar List Background" : "バーリスト背景")
                                    .foregroundColor(.primary)
                                Text(showEnglish ? "Tap to change bar list background" : "バーリスト画面の背景を変更")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Reset all backgrounds button
                    Button(action: {
                        resetAllBackgrounds()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text(showEnglish ? "Reset All Backgrounds" : "全ての背景をリセット")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                // Data Updates Section
                Section(header: Text(showEnglish ? "Data Updates" : "データ更新")) {
                    HStack {
                        Text(showEnglish ? "Current Version" : "現在のバージョン")
                        Spacer()
                        Text(getCurrentVersion())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(showEnglish ? "Last Updated" : "最終更新")
                        Spacer()
                        Text(formatUpdateDate(getLastUpdateDate()))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        checkForUpdates()
                    }) {
                        HStack {
                            if isCheckingUpdate {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(showEnglish ? "Check for Updates" : "更新を確認")
                            Spacer()
                        }
                        .foregroundColor(.primary)
                    }
                    .disabled(isCheckingUpdate)
                    
                    if !updateMessage.isEmpty {
                        Text(updateMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                // App Information Section
                Section(header: Text(showEnglish ? "Information" : "情報")) {
                    HStack {
                        Text(showEnglish ? "App Version" : "アプリバージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(showEnglish ? "Total Bars" : "バー総数")
                        Spacer()
                        Text("\(getBarCount())")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(showEnglish ? "Visited Bars" : "訪問済み")
                        Spacer()
                        Text("\(getVisitedCount())")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Text(showEnglish ? "About This App" : "このアプリについて")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                // Account Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text(showEnglish ? "Log Out" : "ログアウト")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(showEnglish ? "Settings" : "設定")
        }
        .alert(showEnglish ? "Log Out" : "ログアウト", isPresented: $showingLogoutAlert) {
            Button(showEnglish ? "Cancel" : "キャンセル", role: .cancel) {}
            Button(showEnglish ? "Log Out" : "ログアウト", role: .destructive) {
                isLoggedIn = false
            }
        } message: {
            Text(showEnglish ? "Are you sure you want to log out?" : "本当にログアウトしますか？")
        }
        .alert(showEnglish ? "Update Status" : "更新状況", isPresented: $showingUpdateAlert) {
            Button("OK") {}
        } message: {
            Text(updateMessage)
        }
        .alert(showEnglish ? "Choose Background" : "背景を選択", isPresented: $showingBackgroundAlert) {
            Button(showEnglish ? "Default Background" : "デフォルト背景") {
                resetToDefaultBackground()
            }
            Button(showEnglish ? "Choose from Photos" : "写真から選択") {
                showingImagePicker = true
            }
            Button(showEnglish ? "Cancel" : "キャンセル", role: .cancel) {}
        } message: {
            let viewDisplayName = selectedViewForBackground == "ContentView" ?
                (showEnglish ? "Home Page" : "ホームページ") :
                (showEnglish ? "Bar List" : "バーリスト")
            Text(showEnglish ? "Choose background for \(viewDisplayName)" : "\(viewDisplayName)の背景を選択してください")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingImagePicker) {
            BackgroundImagePicker { image in
                saveCustomBackground(image: image)
            }
        }
    }
    
    // MARK: - Update Functions
    private func checkForUpdates() {
        isCheckingUpdate = true
        updateMessage = ""
        
        // For now, just simulate a check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingUpdate = false
            updateMessage = showEnglish ? "No updates available" : "利用可能な更新はありません"
            showingUpdateAlert = true
        }
    }
    
    private func getCurrentVersion() -> String {
        return "1.0"
    }
    
    private func getLastUpdateDate() -> String {
        return UserDefaults.standard.string(forKey: "lastDataUpdate") ?? "Never"
    }
    
    private func formatUpdateDate(_ dateString: String) -> String {
        if dateString == "Never" {
            return showEnglish ? "Never" : "なし"
        }
        
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // MARK: - Data Functions
    private func getBarCount() -> Int {
        let request: NSFetchRequest<Bar> = Bar.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private func getVisitedCount() -> Int {
        let request: NSFetchRequest<Bar> = Bar.fetchRequest()
        request.predicate = NSPredicate(format: "isVisited == true")
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    // MARK: - Background Management Functions
    private func resetToDefaultBackground() {
        let key = selectedViewForBackground == "ContentView" ? "contentBackgroundImage" : "barListBackgroundImage"
        UserDefaults.standard.removeObject(forKey: key)
        
        // Send notification to update the view
        NotificationCenter.default.post(
            name: NSNotification.Name("BackgroundImageChanged"),
            object: nil,
            userInfo: ["viewName": selectedViewForBackground]
        )
        
        let message = showEnglish ? "Background reset to default" : "背景をデフォルトにリセットしました"
        updateMessage = message
        showingUpdateAlert = true
    }
    
    private func resetAllBackgrounds() {
        UserDefaults.standard.removeObject(forKey: "contentBackgroundImage")
        UserDefaults.standard.removeObject(forKey: "barListBackgroundImage")
        
        // Send notifications for both views
        NotificationCenter.default.post(
            name: NSNotification.Name("BackgroundImageChanged"),
            object: nil,
            userInfo: ["viewName": "ContentView"]
        )
        NotificationCenter.default.post(
            name: NSNotification.Name("BackgroundImageChanged"),
            object: nil,
            userInfo: ["viewName": "BarListView"]
        )
        
        let message = showEnglish ? "All backgrounds reset to default" : "すべての背景をデフォルトにリセットしました"
        updateMessage = message
        showingUpdateAlert = true
    }
    
    private func saveCustomBackground(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        let key = selectedViewForBackground == "ContentView" ? "contentBackgroundImage" : "barListBackgroundImage"
        UserDefaults.standard.set(imageData, forKey: key)
        
        // Send notification to update the view
        NotificationCenter.default.post(
            name: NSNotification.Name("BackgroundImageChanged"),
            object: nil,
            userInfo: ["viewName": selectedViewForBackground]
        )
        
        let message = showEnglish ? "Background image updated!" : "背景画像を更新しました！"
        updateMessage = message
        showingUpdateAlert = true
    }
}

// MARK: - Background Image Picker (renamed from SimpleImagePicker to avoid conflict)
struct BackgroundImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: BackgroundImagePicker
        
        init(_ parent: BackgroundImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct AboutView: View {
    @AppStorage("showEnglish") var showEnglish = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean white background to match SettingsView
                Color.white
                    .ignoresSafeArea(.all, edges: .top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(showEnglish ? "Golden Gai Hopper" : "ゴールデン街ホッパー")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.primary)
                            .padding(.top)
                        
                        Text(showEnglish ?
                            "Your ultimate guide to exploring the unique bars of Tokyo's Golden Gai district. Track your visits, take notes, and discover new places in this historic nightlife area." :
                            "東京のゴールデン街地区のユニークなバーを探索するための究極のガイド。訪問を記録し、メモを取り、この歴史的なナイトライフエリアで新しい場所を発見しましょう。")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Label(showEnglish ? "Version 1.0.0" : "バージョン 1.0.0", systemImage: "info.circle")
                            Label(showEnglish ? "© 2025 Golden Gai Hopper" : "© 2025 ゴールデン街ホッパー", systemImage: "c.circle")
                            Label(showEnglish ? "All rights reserved" : "無断転載を禁じます", systemImage: "lock.circle")
                        }
                        .foregroundColor(.secondary)
                        .padding(.top)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle(showEnglish ? "About" : "このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showEnglish ? "Done" : "完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}
