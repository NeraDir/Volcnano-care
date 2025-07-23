import SwiftUI

struct EditGoatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    let goat: Goat
    
    @State private var name: String
    @State private var breed: String
    @State private var age: Int
    @State private var sex: GoatSex
    @State private var healthStatus: HealthStatus
    @State private var lineage: String
    @State private var temperamentNotes: String
    @State private var selectedPhoto: String
    
    let photos = ["🐐", "🐑", "🦌", "🐕", "🐾"]
    
    init(goat: Goat) {
        self.goat = goat
        _name = State(initialValue: goat.name)
        _breed = State(initialValue: goat.breed)
        _age = State(initialValue: goat.age)
        _sex = State(initialValue: goat.sex)
        _healthStatus = State(initialValue: goat.healthStatus)
        _lineage = State(initialValue: goat.lineage)
        _temperamentNotes = State(initialValue: goat.temperamentNotes)
        _selectedPhoto = State(initialValue: goat.photo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Breed", text: $breed)
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        Stepper(value: $age, in: 0...20) {
                            Text("\(age) years")
                        }
                    }
                    
                    Picker("Sex", selection: $sex) {
                        ForEach(GoatSex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    
                    Picker("Health Status", selection: $healthStatus) {
                        ForEach(HealthStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                
                Section("Details") {
                    TextField("Lineage", text: $lineage)
                    TextField("Temperament Notes", text: $temperamentNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Photo") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(photos, id: \.self) { photo in
                            Button(photo) {
                                selectedPhoto = photo
                            }
                            .font(.system(size: 30))
                            .padding(8)
                            .background(selectedPhoto == photo ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("Edit Goat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedGoat = goat
                        updatedGoat.name = name
                        updatedGoat.breed = breed
                        updatedGoat.age = age
                        updatedGoat.sex = sex
                        updatedGoat.healthStatus = healthStatus
                        updatedGoat.lineage = lineage
                        updatedGoat.temperamentNotes = temperamentNotes
                        updatedGoat.photo = selectedPhoto
                        
                        dataProvider.updateGoat(updatedGoat)
                        dismiss()
                    }
                    .disabled(name.isEmpty || breed.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
    }
}

#Preview {
    EditGoatView(goat: Goat(name: "Bella", breed: "Nubian", age: 3, sex: .female, healthStatus: .healthy))
} 