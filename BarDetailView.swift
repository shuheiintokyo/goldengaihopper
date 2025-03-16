import SwiftUI
import CoreData
import PhotosUI

struct BarDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var bar: Bar
    @State private var notes: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var barImage: UIImage?
    
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
                Text(bar.name ?? "Unknown Bar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .multilineTextAlignment(.center)
                
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
                        Label(barImage == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
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
                                        ImageManager.saveImage(image, for: uuid)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                HStack {
                    Text("Status:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(bar.isVisited ? "Visited" : "Not Visited Yet")
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
                    Text("Mark as Visited")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                Button(action: {
                    findInMap()
                }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Find in Map")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Notes")
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
                        Text("Save Notes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Location info if available
                if bar.locationRow > 0 || bar.locationColumn > 0 {
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.headline)
                        
                        HStack {
                            Text("Row: \(bar.locationRow), Column: \(bar.locationColumn)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.bottom, 30)
        }
        .navigationBarTitle("Bar Details", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Close")
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
