import SwiftUI

struct PastureRotationView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddPasture = false
    @State private var editingPasture: Pasture?
    @State private var managementAdvice: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Add button
                HStack {
                    Text("Pasture Rotation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingAddPasture = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                
                if dataProvider.pastures.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        EmptyStateView(
                            icon: "🌱",
                            title: "No Pastures",
                            message: "Add pastures to manage rotation schedule"
                        )
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(dataProvider.pastures.sorted { $0.name < $1.name }) { pasture in
                            PastureRow(pasture: pasture)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete") {
                                        deletePasture(pasture)
                                    }
                                    .tint(.red)
                                    
                                    Button("Edit") {
                                        editingPasture = pasture
                                    }
                                    .tint(.blue)
                                }
                        }
                        
                        // AI Management Advice Section
                        Section("AI Management Advice") {
                            ForEach(dataProvider.pastures, id: \.id) { pasture in
                                ManagementAdviceRow(
                                    pasture: pasture,
                                    advice: managementAdvice[pasture.id],
                                    isLoading: aiProvider.isLoadingPastureAdvice(pasture)
                                ) {
                                    Task {
                                        let advice = await aiProvider.generatePastureManagementAdvice(for: pasture)
                                        managementAdvice[pasture.id] = advice
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .sheet(isPresented: $showingAddPasture) {
            AddPastureView()
        }
        .sheet(item: $editingPasture) { pasture in
            EditPastureView(pasture: pasture)
        }
    }
    
    private func deletePasture(_ pasture: Pasture) {
        if let index = dataProvider.pastures.firstIndex(where: { $0.id == pasture.id }) {
            dataProvider.pastures.remove(at: index)
            managementAdvice.removeValue(forKey: pasture.id)
        }
    }
}

struct PastureRow: View {
    let pasture: Pasture
    
    var statusColor: Color {
        switch pasture.condition {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .overgrazed: return .red
        case .resting: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pasture.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                                 Text(pasture.condition.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack {
                Label("\(pasture.size, specifier: "%.1f") acres", systemImage: "square.dashed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastRotation = pasture.lastGrazedDate {
                    Text("Last rotated: \(lastRotation, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never rotated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            if !pasture.notes.isEmpty {
                Text(pasture.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ManagementAdviceRow: View {
    let pasture: Pasture
    let advice: String?
    let isLoading: Bool
    let onRefresh: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pasture.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let advice = advice {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: onRefresh) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("Get Advice")
                                .foregroundColor(.blue)
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            if let advice = advice {
                VStack(alignment: .leading, spacing: 4) {
                    Text(advice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 3)
                    
                    if advice.count > 100 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else if isLoading {
                Text("Generating management advice...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

struct EditPastureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var name: String
    @State private var size: Double
    @State private var status: PastureCondition
    @State private var lastRotationDate: Date?
    @State private var notes: String
    @State private var showingDatePicker = false
    
    let pasture: Pasture
    
    init(pasture: Pasture) {
        self.pasture = pasture
        _name = State(initialValue: pasture.name)
        _size = State(initialValue: pasture.size)
        _status = State(initialValue: pasture.condition)
        _lastRotationDate = State(initialValue: pasture.lastGrazedDate)
        _notes = State(initialValue: pasture.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Pasture Name", text: $name)
                    
                    HStack {
                        Text("Size")
                        Spacer()
                        TextField("Size", value: $size, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("acres")
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(PastureCondition.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
                
                Section("Rotation") {
                    if let date = lastRotationDate {
                        HStack {
                            Text("Last Rotation")
                            Spacer()
                            Text(date, style: .date)
                                .foregroundColor(.secondary)
                            Button("Change") {
                                showingDatePicker = true
                            }
                        }
                    } else {
                        Button("Set Last Rotation Date") {
                            lastRotationDate = Date()
                            showingDatePicker = true
                        }
                    }
                    
                    if lastRotationDate != nil {
                        Button("Clear Date") {
                            lastRotationDate = nil
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Pasture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let index = dataProvider.pastures.firstIndex(where: { $0.id == pasture.id }) {
                                                         var updatedPasture = pasture
                             updatedPasture.name = name
                             updatedPasture.size = size
                             updatedPasture.condition = status
                             updatedPasture.lastGrazedDate = lastRotationDate
                             updatedPasture.notes = notes
                             dataProvider.pastures[index] = updatedPasture
                            dataProvider.saveData()
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || size <= 0)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    DatePicker("Last Rotation Date", selection: Binding(
                        get: { lastRotationDate ?? Date() },
                        set: { lastRotationDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingDatePicker = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AddPastureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var name = ""
    @State private var size: Double = 0.0
    @State private var grassType: GrassType = .mixed
    @State private var condition: PastureCondition = .good
    @State private var restPeriod = 30
    @State private var capacity = 0
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Pasture Name", text: $name)
                    
                    HStack {
                        Text("Size")
                        Spacer()
                        TextField("Size", value: $size, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("acres")
                    }
                    
                    Picker("Grass Type", selection: $grassType) {
                        ForEach(GrassType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    
                    Picker("Condition", selection: $condition) {
                        ForEach(PastureCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                }
                
                Section("Management") {
                    HStack {
                        Text("Rest Period")
                        Spacer()
                        Stepper(value: $restPeriod, in: 7...90, step: 7) {
                            Text("\(restPeriod) days")
                        }
                    }
                    
                    HStack {
                        Text("Capacity")
                        Spacer()
                        Stepper(value: $capacity, in: 0...20) {
                            Text("\(capacity) goats")
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Pasture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let pasture = Pasture(
                            name: name,
                            size: size,
                            grassType: grassType,
                            condition: condition,
                            restPeriod: restPeriod,
                            capacity: capacity,
                            notes: notes
                        )
                        dataProvider.addPasture(pasture)
                        dismiss()
                    }
                    .disabled(name.isEmpty || size <= 0)
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

struct PastureDetailView: View {
    let pasture: Pasture
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: pasture.grassType.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text(pasture.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(pasture.grassType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(pasture.condition.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(pasture.condition.color).opacity(0.2))
                                .foregroundColor(Color(pasture.condition.color))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Size", value: String(format: "%.1f acres", pasture.size))
                        DetailRow(title: "Capacity", value: "\(pasture.capacity) goats")
                        DetailRow(title: "Current Occupancy", value: "\(pasture.currentOccupancy) goats")
                        DetailRow(title: "Rest Period", value: "\(pasture.restPeriod) days")
                        
                        if let lastGrazed = pasture.lastGrazedDate {
                            DetailRow(title: "Last Grazed", value: DateFormatter.short.string(from: lastGrazed))
                        }
                        
                        if !pasture.notes.isEmpty {
                            DetailRow(title: "Notes", value: pasture.notes)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Pasture Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PastureRotationView()
} 