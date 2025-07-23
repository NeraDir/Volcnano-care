import SwiftUI

struct EquipmentInventoryView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddEquipment = false
    @State private var editingEquipment: Equipment?

    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Add button
                        HStack {
                    Text("Equipment Inventory")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                            
                            Spacer()
                            
                    Button(action: { showingAddEquipment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                
                if dataProvider.equipment.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                            EmptyStateView(
                                icon: "🔧",
                                title: "No Equipment",
                            message: "Add equipment to track maintenance and inventory"
                            )
                        
                        Spacer()
                    }
                        } else {
                    List {
                        ForEach(dataProvider.equipment.sorted { $0.name < $1.name }) { equipment in
                            EquipmentRow(equipment: equipment)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete") {
                                        deleteEquipment(equipment)
                                    }
                                    .tint(.red)
                                    
                                    Button("Edit") {
                                        editingEquipment = equipment
                                    }
                                    .tint(.blue)
                                }
                        }

                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView()
        }
        .sheet(item: $editingEquipment) { equipment in
            EditEquipmentView(equipment: equipment)
        }
    }
    
    private func deleteEquipment(_ equipment: Equipment) {
        if let index = dataProvider.equipment.firstIndex(where: { $0.id == equipment.id }) {
            dataProvider.equipment.remove(at: index)
        }
    }
}

struct EquipmentRow: View {
    let equipment: Equipment
    
    var statusColor: Color {
        switch equipment.condition {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .needsReplacement: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(equipment.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(equipment.condition.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack {
                Label(equipment.type.rawValue, systemImage: "tag")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastMaintenance = equipment.lastMaintenanceDate {
                    Text("Last maintained: \(lastMaintenance, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never maintained")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            if !equipment.notes.isEmpty {
                Text(equipment.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}



struct EditEquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var name: String
    @State private var category: EquipmentType
    @State private var condition: EquipmentCondition
    @State private var lastMaintenanceDate: Date?
    @State private var notes: String
    @State private var showingDatePicker = false
    
    let equipment: Equipment
    
    init(equipment: Equipment) {
        self.equipment = equipment
        _name = State(initialValue: equipment.name)
        _category = State(initialValue: equipment.type)
        _condition = State(initialValue: equipment.condition)
        _lastMaintenanceDate = State(initialValue: equipment.lastMaintenanceDate)
        _notes = State(initialValue: equipment.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Equipment Name", text: $name)
                    
                                         Picker("Category", selection: $category) {
                         ForEach(EquipmentType.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("Condition", selection: $condition) {
                        ForEach(EquipmentCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue.capitalized).tag(condition)
                        }
                    }
                }
                
                Section("Maintenance") {
                    if let date = lastMaintenanceDate {
                        HStack {
                            Text("Last Maintenance")
                            Spacer()
                            Text(date, style: .date)
                                .foregroundColor(.secondary)
                            Button("Change") {
                                showingDatePicker = true
                            }
                        }
                    } else {
                        Button("Set Last Maintenance Date") {
                            lastMaintenanceDate = Date()
                            showingDatePicker = true
                        }
                    }
                    
                    if lastMaintenanceDate != nil {
                        Button("Clear Date") {
                            lastMaintenanceDate = nil
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let index = dataProvider.equipment.firstIndex(where: { $0.id == equipment.id }) {
                                                         var updatedEquipment = equipment
                             updatedEquipment.name = name
                             updatedEquipment.type = category
                             updatedEquipment.condition = condition
                             updatedEquipment.lastMaintenanceDate = lastMaintenanceDate
                             updatedEquipment.notes = notes
                             dataProvider.equipment[index] = updatedEquipment
                            dataProvider.saveData()
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    DatePicker("Last Maintenance Date", selection: Binding(
                        get: { lastMaintenanceDate ?? Date() },
                        set: { lastMaintenanceDate = $0 }
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

struct MaintenanceAlert {
    let equipment: Equipment
    let message: String
    let severity: Severity
    
    enum Severity: Int {
        case high = 3
        case medium = 2
        case low = 1
    }
}

struct EquipmentCard: View {
    let equipment: Equipment
    let onTap: () -> Void
    
    var statusColor: Color {
        switch equipment.condition {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .needsReplacement: return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: equipment.type.icon)
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(equipment.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(equipment.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Location:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(equipment.location.isEmpty ? "Not specified" : equipment.location)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Condition:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(equipment.condition.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }
                    
                    if let nextMaintenance = equipment.nextMaintenanceDate {
                        HStack {
                            Text("Next Service:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(nextMaintenance, style: .date)
                                .font(.caption)
                                .foregroundColor(nextMaintenance <= Date() ? .red : .secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



struct MaintenanceAlertCard: View {
    let equipment: Equipment
    let message: String
    let severity: MaintenanceAlert.Severity
    
    var severityColor: Color {
        switch severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(severityColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.headline)
                    .foregroundColor(severityColor)
                
                Text(message)
                    .font(.body)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(equipment.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !equipment.location.isEmpty {
                    Text(equipment.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor, lineWidth: 1)
        )
    }
}

struct CategorySection: View {
    let type: EquipmentType
    let equipment: [Equipment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(.green)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(equipment.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 4) {
                ForEach(equipment) { item in
                    HStack {
                        Text(item.name)
                            .font(.body)
                        
                        Spacer()
                        
                        Text(item.condition.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(item.condition.color).opacity(0.2))
                            .foregroundColor(Color(item.condition.color))
                            .cornerRadius(6)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MaintenanceRecordCard: View {
    let equipment: Equipment
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.type.rawValue)
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text("\(equipment.name) • \(equipment.type.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if record.cost > 0 {
                        Text("$\(record.cost, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !record.description.isEmpty {
                Text(record.description)
                    .font(.body)
            }
            
            if !record.performedBy.isEmpty {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.blue)
                    Text("Performed by: \(record.performedBy)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddEquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var name = ""
    @State private var type: EquipmentType = .feeder
    @State private var condition: EquipmentCondition = .good
    @State private var purchaseDate = Date()
    @State private var cost: Double = 0.0
    @State private var location = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Equipment Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(EquipmentType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    
                    Picker("Condition", selection: $condition) {
                        ForEach(EquipmentCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                }
                
                Section("Purchase Details") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("Cost", value: $cost, format: .currency(code: "USD"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
                
                Section("Location & Notes") {
                    TextField("Location", text: $location)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let equipment = Equipment(
                            name: name,
                            type: type,
                            condition: condition,
                            purchaseDate: purchaseDate,
                            cost: cost,
                            location: location,
                            notes: notes
                        )
                        dataProvider.addEquipment(equipment)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
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

struct EquipmentDetailView: View {
    let equipment: Equipment
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: equipment.type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(equipment.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(equipment.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(equipment.condition.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(equipment.condition.color).opacity(0.2))
                                .foregroundColor(Color(equipment.condition.color))
                                .cornerRadius(8)
                        }
                    }
                    .padding()

                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Location", value: equipment.location.isEmpty ? "Not specified" : equipment.location)
                        DetailRow(title: "Purchase Date", value: DateFormatter.short.string(from: equipment.purchaseDate))
                        DetailRow(title: "Cost", value: String(format: "$%.2f", equipment.cost))
                        
                        if let lastMaintenance = equipment.lastMaintenanceDate {
                            DetailRow(title: "Last Maintenance", value: DateFormatter.short.string(from: lastMaintenance))
                        }
                        
                        if let nextMaintenance = equipment.nextMaintenanceDate {
                            DetailRow(title: "Next Maintenance", value: DateFormatter.short.string(from: nextMaintenance))
                        }
                        
                        if !equipment.notes.isEmpty {
                            DetailRow(title: "Notes", value: equipment.notes)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Equipment Details")
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
    EquipmentInventoryView()
} 