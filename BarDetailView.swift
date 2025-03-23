import SwiftUI
import CoreData
import PhotosUI

struct BarDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("showEnglish") var showEnglish = false
    @ObservedObject var bar: Bar
    @State private var notes: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var barImage: UIImage?
    
    // Add notification for image updates
    private let imageUpdatedNotification = NotificationCenter.default.publisher(
        for: NSNotification.Name("ImageUpdated")
    )
    
    init(bar: Bar) {
        self.bar = bar
        _notes = State(initialValue: bar.notes ?? "")
        
        // Initialize by checking for existing image
        if let uuid = bar.uuid {
            _barImage = State(initialValue: ImageManager.loadImage(for: uuid))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                if showEnglish {
                    Text(BarNameTranslation.nameMap[bar.name ?? ""] ?? bar.name ?? "Unknown Bar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .multilineTextAlignment(.center)
                } else {
                    Text(bar.name ?? "不明なバー")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .multilineTextAlignment(.center)
                }
                
                // Image section
                VStack {
                    if let image = barImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Image picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(showEnglish ? "Add Photo" : "写真を追加", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .onChange(of: selectedItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    barImage = image
                                    if let uuid = bar.uuid {
                                        // Save image to disk
                                        ImageManager.saveImage(image, for: uuid)
                                        
                                        // Notify other views that image has been updated
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("ImageUpdated"),
                                            object: nil,
                                            userInfo: ["barUUID": uuid]
                                        )
                                        
                                        // Update the bar object to trigger refresh
                                        bar.objectWillChange.send()
                                        
                                        // Save context to ensure persistence
                                        try? viewContext.save()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                HStack {
                    Text(showEnglish ? "Status:" : "ステータス:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(bar.isVisited ? (showEnglish ? "Visited" : "訪問済み") : (showEnglish ? "Not Visited Yet" : "未訪問"))
                        .foregroundColor(bar.isVisited ? .green : .gray)
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
                
                Toggle(isOn: Binding(
                    get: { bar.isVisited },
                    set: {
                        bar.isVisited = $0
                        try? viewContext.save()
                    }
                )) {
                    Text(showEnglish ? "Mark as Visited" : "訪問済みにする")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                Button(action: {
                    findInMap()
                }) {
                    HStack {
                        Image(systemName: "map")
                        Text(showEnglish ? "Find in Map" : "マップで探す")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text(showEnglish ? "Notes" : "メモ")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    saveNotes()
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text(showEnglish ? "Save Notes" : "メモを保存")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationBarTitle(showEnglish ? "Bar Details" : "バーの詳細", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text(showEnglish ? "Close" : "閉じる")
                .bold()
        })
    }
    
    private func saveNotes() {
        bar.notes = notes
        try? viewContext.save()
    }
    
    private func findInMap() {
        // Post notification to highlight this bar in the map
        NotificationCenter.default.post(
            name: NSNotification.Name("HighlightBar"),
            object: nil,
            userInfo: ["barUUID": bar.uuid ?? ""]
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// Image management class
class ImageManager {
    // Get the documents directory path
    static private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Save an image to the documents directory
    static func saveImage(_ image: UIImage, for identifier: String) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let filename = getDocumentsDirectory().appendingPathComponent("\(identifier).jpg")
            try? data.write(to: filename)
        }
    }
    
    // Load an image from the documents directory
    static func loadImage(for identifier: String) -> UIImage? {
        let filename = getDocumentsDirectory().appendingPathComponent("\(identifier).jpg")
        return UIImage(contentsOfFile: filename.path)
    }
}

extension ImageManager {
    // Get image from assets based on bar name
    static func getAssetImage(for barName: String?) -> UIImage? {
        guard let barName = barName else { return nil }
        
        // Try to get image from English name first
        if let englishName = BarNameTranslation.nameMap[barName],
           let image = UIImage(named: englishName) {
            return image
        }
        
        // Fallback to the original name
        return UIImage(named: barName)
    }
}

extension BarDetailView {
    // Function to get the appropriate image for the bar
    func getBarImage() -> UIImage? {
        // First try to get a saved image
        if let uuid = bar.uuid, let savedImage = ImageManager.loadImage(for: uuid) {
            return savedImage
        }
        
        // Then try to get from assets using the name
        return ImageManager.getAssetImage(for: bar.name)
    }
}
