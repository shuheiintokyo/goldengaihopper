import SwiftUI
import PhotosUI
import MapKit

struct BarDetailView: View {
    let bar: Bar
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @AppStorage("showEnglish") var showEnglish = false
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var refreshID = UUID()
    @State private var showingDeleteAlert = false
    @State private var showingMap = false
    @State private var notes: String = ""
    
    // Get English translation if available
    private var englishName: String? {
        guard let japaneseName = bar.name,
              let translation = BarNameTranslation.nameMap[japaneseName],
              translation != japaneseName else {
            return nil
        }
        return translation
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                imageSection
                addPhotoButton
                statusSection
                mapButton
                notesSection
                deletePhotoButton
                
                Spacer(minLength: 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            SimpleImagePicker(image: $inputImage, isPresented: $showingImagePicker)
        }
        .sheet(isPresented: $showingMap) {
            if let location = getBarLocation() {
                MapDetailView(location: location, barName: bar.name ?? "Unknown")
            }
        }
        .alert(showEnglish ? "Delete Photo?" : "写真を削除しますか？", isPresented: $showingDeleteAlert) {
            Button(showEnglish ? "Cancel" : "キャンセル", role: .cancel) { }
            Button(showEnglish ? "Delete" : "削除", role: .destructive) {
                deleteImage()
            }
        } message: {
            Text(showEnglish ? "This action cannot be undone." : "この操作は取り消せません。")
        }
        .onChange(of: inputImage) { oldValue, newValue in
            if let newImage = newValue {
                saveImage(newImage)
            }
        }
        .onAppear {
            notes = bar.notes ?? ""
            setupImageUpdateListener()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(bar.name ?? "Unknown")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if let englishName = englishName {
                Text(englishName)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var imageSection: some View {
        Group {
            if let uuid = bar.uuid, let image = ImageManager.loadImage(for: uuid) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .id(refreshID)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(showEnglish ? "No Photo" : "写真なし")
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .padding(.horizontal)
    }
    
    private var addPhotoButton: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            HStack {
                Image(systemName: "photo")
                Text(showEnglish ? "Add Photo" : "写真を追加")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showEnglish ? "Status:" : "ステータス:")
                .font(.headline)
            
            Toggle(isOn: Binding(
                get: { bar.isVisited },
                set: { newValue in
                    bar.isVisited = newValue
                    try? viewContext.save()
                }
            )) {
                HStack {
                    Text(showEnglish ? "Visited" : "訪問済み")
                        .font(.body)
                    Spacer()
                    if bar.isVisited {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .tint(.green)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var mapButton: some View {
        Button(action: {
            showingMap = true
        }) {
            HStack {
                Image(systemName: "map")
                Text(showEnglish ? "Find on Map" : "マップで探す")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(showEnglish ? "Notes" : "メモ")
                .font(.headline)
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: notes) { oldValue, newValue in
                    bar.notes = newValue
                    try? viewContext.save()
                }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var deletePhotoButton: some View {
        if let uuid = bar.uuid, ImageManager.loadImage(for: uuid) != nil {
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text(showEnglish ? "Delete Photo" : "写真を削除")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveImage(_ image: UIImage) {
        guard let uuid = bar.uuid else { return }
        
        ImageManager.saveImage(image, for: uuid)
        
        // Automatically mark as visited when photo is added
        if !bar.isVisited {
            bar.isVisited = true
            try? viewContext.save()
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ImageUpdated"),
            object: nil,
            userInfo: ["barUUID": uuid]
        )
        
        refreshID = UUID()
        inputImage = nil
    }
    
    private func deleteImage() {
        guard let uuid = bar.uuid else { return }
        
        ImageManager.deleteImage(for: uuid)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ImageUpdated"),
            object: nil,
            userInfo: ["barUUID": uuid]
        )
        
        refreshID = UUID()
    }
    
    private func setupImageUpdateListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ImageUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let uuid = notification.userInfo?["barUUID"] as? String,
               uuid == bar.uuid {
                refreshID = UUID()
            }
        }
    }
    
    private func getBarLocation() -> CLLocationCoordinate2D? {
        return CLLocationCoordinate2D(latitude: 35.6938, longitude: 139.7034)
    }
}

// MARK: - Simple Image Picker
struct SimpleImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: SimpleImagePicker
        
        init(_ parent: SimpleImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Immediately dismiss by setting isPresented to false
            parent.isPresented = false
            
            // Process image if selected
            if let provider = results.first?.itemProvider {
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.image = image
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Map Detail View
struct MapDetailView: View {
    let location: CLLocationCoordinate2D
    let barName: String
    @Environment(\.dismiss) var dismiss
    @AppStorage("showEnglish") var showEnglish = false
    
    var body: some View {
        NavigationStack {
            Map(position: .constant(.region(MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            )))) {
                Marker(barName, coordinate: location)
            }
            .navigationTitle(barName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showEnglish ? "Close" : "閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
