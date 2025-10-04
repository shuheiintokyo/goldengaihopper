import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("showEnglish") var showEnglish = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("enableLiquidGlass") var enableLiquidGlass = false
    @State private var showingLogoutAlert = false
    @State private var showingAbout = false
    @State private var showingAppGuide = false
    @State private var showingUpdateAlert = false
    @State private var updateMessage = ""
    @State private var isCheckingUpdate = false
    @State private var showingImagePicker = false
    @State private var selectedViewForBackground = ""
    @State private var showingBackgroundAlert = false
    @State private var showLiquidGlassInfo = false
    @Environment(\.managedObjectContext) private var viewContext
    
    // Computed property for display name
    private var selectedViewDisplayName: String {
        switch selectedViewForBackground {
        case "ContentView":
            return showEnglish ? "Home Page" : "ホームページ"
        case "BarListView":
            return showEnglish ? "Bar List" : "バーリスト"
        case "MapView":
            return showEnglish ? "Map" : "マップ"
        default:
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all, edges: .top)
            
            List {
                languageSection
                visualEffectsSection
                backgroundSection
                dataUpdatesSection
                appInformationSection
                howToUseSection
                accountSection
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
        .alert(showEnglish ? "Liquid Glass Mode" : "リキッドグラスモード", isPresented: $showLiquidGlassInfo) {
            Button("OK") {}
        } message: {
            Text(showEnglish ?
                "Liquid Glass Mode adds a beautiful glass effect to bar cards. This feature requires iOS 26.0 or later. On older versions, the standard gradient will be used." :
                "リキッドグラスモードはバーカードに美しいガラス効果を追加します。この機能にはiOS 26.0以降が必要です。古いバージョンでは標準グラデーションが使用されます。")
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
            Text(showEnglish ? "Choose background for \(selectedViewDisplayName)" : "\(selectedViewDisplayName)の背景を選択してください")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingAppGuide) {
            AppGuideView()
        }
        .sheet(isPresented: $showingImagePicker) {
            BackgroundImagePicker { image in
                saveCustomBackground(image: image)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var languageSection: some View {
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
    }
    
    private var visualEffectsSection: some View {
        Section(header: Text(showEnglish ? "Visual Effects" : "視覚効果")) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(showEnglish ? "Liquid Glass Mode" : "リキッドグラスモード")
                        .foregroundColor(.primary)
                    Text(showEnglish ? "iOS 26.0+ required" : "iOS 26.0以上が必要")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableLiquidGlass)
                    .tint(.blue)
                
                Button(action: {
                    showLiquidGlassInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(Color.gray.opacity(0.1))
    }
    
    private var backgroundSection: some View {
        Section(header: Text(showEnglish ? "Background Images" : "背景画像")) {
            BackgroundSettingRow(
                icon: "photo",
                color: .blue,
                title: showEnglish ? "Home Page Background" : "ホームページ背景",
                subtitle: showEnglish ? "Tap to change home screen background" : "ホーム画面の背景を変更",
                action: {
                    selectedViewForBackground = "ContentView"
                    showingBackgroundAlert = true
                }
            )
            
            BackgroundSettingRow(
                icon: "list.bullet.rectangle",
                color: .green,
                title: showEnglish ? "Bar List Background" : "バーリスト背景",
                subtitle: showEnglish ? "Tap to change bar list background" : "バーリスト画面の背景を変更",
                action: {
                    selectedViewForBackground = "BarListView"
                    showingBackgroundAlert = true
                }
            )
            
            BackgroundSettingRow(
                icon: "map",
                color: .purple,
                title: showEnglish ? "Map Background" : "マップ背景",
                subtitle: showEnglish ? "Tap to change map background" : "マップ画面の背景を変更",
                action: {
                    selectedViewForBackground = "MapView"
                    showingBackgroundAlert = true
                }
            )
            
            resetBackgroundsButton
        }
        .listRowBackground(Color.gray.opacity(0.1))
    }
    
    private var resetBackgroundsButton: some View {
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
    
    private var dataUpdatesSection: some View {
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
    }
    
    private var appInformationSection: some View {
        Section(header: Text(showEnglish ? "Information" : "情報")) {
            HStack {
                Text(showEnglish ? "App Version" : "アプリバージョン")
                Spacer()
                Text("1.2")
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
    }
    
    private var howToUseSection: some View {
        Section(header: Text(showEnglish ? "How to Use" : "使い方ガイド")) {
            Button(action: {
                showingAppGuide = true
            }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                    Text(showEnglish ? "App Guide" : "アプリガイド")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listRowBackground(Color.gray.opacity(0.1))
    }
    
    private var accountSection: some View {
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
    
    // MARK: - Update Functions
    private func checkForUpdates() {
        isCheckingUpdate = true
        updateMessage = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingUpdate = false
            updateMessage = showEnglish ? "No updates available" : "利用可能な更新はありません"
            showingUpdateAlert = true
        }
    }
    
    private func getCurrentVersion() -> String {
        return "1.2"
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
        let key: String
        switch selectedViewForBackground {
        case "ContentView":
            key = "contentBackgroundImage"
        case "BarListView":
            key = "barListBackgroundImage"
        case "MapView":
            key = "mapBackgroundImage"
        default:
            return
        }
        
        UserDefaults.standard.removeObject(forKey: key)
        
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
        UserDefaults.standard.removeObject(forKey: "mapBackgroundImage")
        
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
        NotificationCenter.default.post(
            name: NSNotification.Name("BackgroundImageChanged"),
            object: nil,
            userInfo: ["viewName": "MapView"]
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
        
        let key: String
        switch selectedViewForBackground {
        case "ContentView":
            key = "contentBackgroundImage"
        case "BarListView":
            key = "barListBackgroundImage"
        case "MapView":
            key = "mapBackgroundImage"
        default:
            return
        }
        
        UserDefaults.standard.set(imageData, forKey: key)
        
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

// MARK: - Background Image Picker
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

// MARK: - About View
struct AboutView: View {
    @AppStorage("showEnglish") var showEnglish = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                            Label(showEnglish ? "Version 1.2" : "バージョン 1.2", systemImage: "info.circle")
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

// MARK: - Background Setting Row Helper
struct BackgroundSettingRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - App Guide View
struct AppGuideView: View {
    @AppStorage("showEnglish") var showEnglish = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea(.all, edges: .top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(showEnglish ? "How to Use Golden Gai Hopper" : "ゴールデン街ホッパーの使い方")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text(showEnglish ?
                                "Discover and track your Golden Gai bar-hopping adventures!" :
                                "ゴールデン街のバーホッピングを記録・発見しよう！")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // Main Features
                        VStack(alignment: .leading, spacing: 20) {
                            featureSection(
                                icon: "camera.fill",
                                color: .blue,
                                title: showEnglish ? "Take Photos & Upload" : "写真を撮影・アップロード",
                                description: showEnglish ?
                                    "Tap on any bar card to open its details. Use the 'Add Photo' button to take a picture or choose from your library. Your photos are saved locally and displayed on the bar cards." :
                                    "バーカードをタップして詳細を開きます。「写真を追加」ボタンで写真を撮影するか、ライブラリから選択できます。写真はローカルに保存され、カードに表示されます。"
                            )
                            
                            featureSection(
                                icon: "checkmark.circle.fill",
                                color: .green,
                                title: showEnglish ? "Mark as Visited" : "訪問済みにする",
                                description: showEnglish ?
                                    "Toggle the 'Visited' switch in the bar details. Visited bars appear with a green badge and are automatically added to your Visited Bars list and highlighted on the map." :
                                    "バー詳細画面で「訪問済み」をオンにします。訪問済みバーは緑色のバッジが表示され、訪問済みバーリストとマップに自動的に反映されます。"
                            )
                            
                            featureSection(
                                icon: "list.bullet",
                                color: .orange,
                                title: showEnglish ? "View in List & Map" : "リストとマップで確認",
                                description: showEnglish ?
                                    "Check the 'List' tab to see all your visited bars. Use the 'Map' tab to visualize bar locations and see which ones you've already explored in Golden Gai." :
                                    "「リスト」タブで訪問済みバーを確認できます。「マップ」タブでバーの位置を視覚化し、ゴールデン街でどこを訪れたかチェックできます。"
                            )
                            
                            featureSection(
                                icon: "text.bubble.fill",
                                color: .purple,
                                title: showEnglish ? "Add Comments" : "コメントを追加",
                                description: showEnglish ?
                                    "Write notes about your experience in the 'Notes' section. Tap the 'Save' button to save your comments. Your notes will appear as a preview on the bar cards, helping you remember great experiences!" :
                                    "「メモ」セクションで体験についての記録を残せます。「保存」ボタンをタップしてコメントを保存。メモはカードにプレビュー表示され、良い体験を思い出すのに役立ちます！"
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Current Status
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.blue)
                                Text(showEnglish ? "Local Storage Only" : "ローカル保存のみ")
                                    .font(.headline)
                            }
                            
                            Text(showEnglish ?
                                "Currently, all your data (photos, visited bars, and comments) is stored locally on your device. Your information is private and secure." :
                                "現在、すべてのデータ（写真、訪問済みバー、コメント）はデバイスにローカル保存されます。情報はプライベートで安全です。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Future Features
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.green)
                                Text(showEnglish ? "Coming Soon" : "今後の予定")
                                    .font(.headline)
                            }
                            
                            Text(showEnglish ?
                                "We're planning to add cloud storage and comment sharing features in future updates. You'll be able to share your experiences with other Golden Gai explorers!" :
                                "今後のアップデートでクラウド保存とコメント共有機能を追加予定です。他のゴールデン街探検者と体験を共有できるようになります！")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Feedback
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.orange)
                                Text(showEnglish ? "Send Feedback" : "フィードバック送信")
                                    .font(.headline)
                            }
                            
                            Text(showEnglish ?
                                "Have suggestions or ideas for new features? We'd love to hear from you! Your feedback helps us improve the app for everyone. Contact us through the App Store or our support channels." :
                                "新機能のアイデアやご提案はありますか？ぜひお聞かせください！皆様のフィードバックがアプリの改善に役立ちます。App Storeまたはサポートチャンネルからご連絡ください。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle(showEnglish ? "App Guide" : "アプリガイド")
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
    
    private func featureSection(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
