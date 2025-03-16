import SwiftUI
import CoreData

struct BarDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var bar: Bar
    @State private var notes: String
    
    init(bar: Bar) {
        self.bar = bar
        _notes = State(initialValue: bar.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(bar.name ?? "Unknown Bar")
                    .font(.largeTitle)
                    .padding()
                
                Button(action: {
                    findInMap()
                }) {
                    Text("Find in Map")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Toggle(isOn: Binding(
                    get: { bar.isVisited },
                    set: {
                        bar.isVisited = $0
                        try? viewContext.save()
                    }
                )) {
                    Text("Bar is Visited")
                        .font(.headline)
                }
                .padding()
                
                TextEditor(text: $notes)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .frame(height: 200)
                
                Button(action: {
                    saveNotes()
                }) {
                    Text("Save Notes")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveNotes() {
        bar.notes = notes
        try? viewContext.save()
    }
    
    private func findInMap() {
        // This will be handled in ContentView by dismissing this sheet
        // and highlighting the appropriate cell
        NotificationCenter.default.post(
            name: NSNotification.Name("HighlightBar"),
            object: nil,
            userInfo: ["barUUID": bar.uuid ?? ""]
        )
        presentationMode.wrappedValue.dismiss()
    }
}
