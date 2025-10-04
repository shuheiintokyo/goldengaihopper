import SwiftUI
import PhotosUI
import MapKit

struct BarDetailView: View {
    let bar: Bar
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @AppStorage("showEnglish") var showEnglish = false
    @AppStorage("enableLiquidGlass") var enableLiquidGlass = false
    @AppStorage("pendingBarHighlight") private var pendingBarHighlight: String = ""
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageSourceAlert = false
    @State private var inputImage: UIImage?
    @State private var refreshID = UUID()
    @State private var showingDeleteAlert = false
    @State private var notes: String = ""
    @State private var hasUnsavedChanges = false
    @State private var showSaveConfirmation = false
    
    var onImageUploaded: (() -> Void)?
    
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
            ImagePickerView(image: $inputImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(image: $inputImage, sourceType: .camera)
        }
        .alert(showEnglish ? "Delete Photo?" : "写真を削除しますか？", isPresented: $showingDeleteAlert) {
            Button(showEnglish ? "Cancel" : "キャンセル", role: .cancel) { }
            Button(showEnglish ? "Delete" : "削除", role: .destructive) {
                deleteImage()
            }
        } message: {
            Text(showEnglish ? "This action cannot be undone." : "この操作は取り消せません。")
        }
        .confirmationDialog(
            showEnglish ? "Add Photo" : "写真を追加",
            isPresented: $showingImageSourceAlert,
            titleVisibility: .visible
        ) {
            Button(action: {
                showingCamera = true
            }) {
                Label(showEnglish ? "Take Photo" : "写真を撮る", systemImage: "camera")
            }
            
            Button(action: {
                showingImagePicker = true
            }) {
                Label(showEnglish ? "Choose from Library" : "ライブラリから選択", systemImage: "photo.on.rectangle")
            }
            
            Button(showEnglish ? "Cancel" : "キャンセル", role: .cancel) { }
        }
        .onChange(of: inputImage) { oldValue, newValue in
            if let newImage = newValue {
                saveImage(newImage)
            }
        }
        .onAppear {
            notes = bar.notes ?? ""
            hasUnsavedChanges = false
            showSaveConfirmation = false
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
                    .overlay(
                        Group {
                            if #available(iOS 26.0, *), enableLiquidGlass {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                    .glassEffect(in: .rect(cornerRadius: 16))
                            } else {
                                EmptyView()
                            }
                        }
                    )
            }
        }
        .padding(.horizontal)
    }
    
    private var addPhotoButton: some View {
        Button(action: {
            showingImageSourceAlert = true
        }) {
            HStack {
                Image(systemName: "camera.fill")
                Text(showEnglish ? "Add Photo" : "写真を追加")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if #available(iOS 26.0, *), enableLiquidGlass {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .glassEffect(in: .rect(cornerRadius: 12))
                    } else {
                        Color.blue
                    }
                }
            )
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
        .background(
            Group {
                if #available(iOS 26.0, *), enableLiquidGlass {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .glassEffect(in: .rect(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var mapButton: some View {
        Button(action: {
            if let uuid = bar.uuid {
                print("🔵 Setting pending highlight: \(uuid)")
                
                // Set the pending highlight using @AppStorage (reactive)
                pendingBarHighlight = uuid
                
                // Also post notification for cases where MapView is already loaded
                NotificationCenter.default.post(
                    name: NSNotification.Name("HighlightBar"),
                    object: nil,
                    userInfo: ["barUUID": uuid]
                )
                
                // Dismiss to return to main view
                dismiss()
            }
        }) {
            HStack {
                Image(systemName: "map")
                Text(showEnglish ? "Find on Map" : "マップで探す")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(
                Group {
                    if #available(iOS 26.0, *), enableLiquidGlass {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .glassEffect(in: .rect(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(showEnglish ? "Notes" : "メモ")
                    .font(.headline)
                
                Spacer()
                
                // Save button - only show when there are unsaved changes
                if hasUnsavedChanges {
                    Button(action: saveNotes) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text(showEnglish ? "Save" : "保存")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                }
                
                // Saved confirmation indicator
                if showSaveConfirmation {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text(showEnglish ? "Saved" : "保存済み")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.green)
                    .transition(.opacity)
                }
            }
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: notes) { oldValue, newValue in
                    // Mark as having unsaved changes
                    hasUnsavedChanges = (newValue != (bar.notes ?? ""))
                    showSaveConfirmation = false
                }
        }
        .padding()
        .background(
            Group {
                if #available(iOS 26.0, *), enableLiquidGlass {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .glassEffect(in: .rect(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                }
            }
        )
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
    
    private func saveNotes() {
        bar.notes = notes
        try? viewContext.save()
        
        // Notify that bar data has updated (for card view refresh)
        NotificationCenter.default.post(
            name: NSNotification.Name("BarDataUpdated"),
            object: nil,
            userInfo: ["barUUID": bar.uuid ?? ""]
        )
        
        // Update UI state
        hasUnsavedChanges = false
        showSaveConfirmation = true
        
        // Hide confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveConfirmation = false
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        guard let uuid = bar.uuid else { return }
        
        ImageManager.saveImage(image, for: uuid)
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
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
}

// MARK: - Universal Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        
        if sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("⚠️ Camera not available on this device")
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.dismiss()
            
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
