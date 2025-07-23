import SwiftUI

struct MilkYieldLogView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddRecord = false
    @State private var editingRecord: MilkRecordView?
    @State private var yieldAnalysis: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Add button
                HStack {
                    Text("Milk Yield Log")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingAddRecord = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Milk Records List
                if getAllMilkRecords().isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        EmptyStateView(
                            icon: "🥛",
                            title: "No Milk Records",
                            message: "Start logging milk production for your goats"
                        )
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(getAllMilkRecords().sorted { $0.date > $1.date }, id: \.id) { record in
                            MilkRecordRow(
                                record: record,
                                goatName: getGoatName(for: record.goatId)
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete") {
                                    deleteMilkRecord(record)
                                }
                                .tint(.red)
                                
                                Button("Edit") {
                                    editingRecord = record
                                }
                                .tint(.blue)
                            }
                        }
                        
                        // AI Analysis Section
                        Section("AI Analysis") {
                            ForEach(dataProvider.goats.filter { !$0.milkProduction.isEmpty }, id: \.id) { goat in
                                YieldAnalysisRow(
                                    goat: goat,
                                    analysis: yieldAnalysis[goat.id],
                                    isLoading: aiProvider.isLoadingYieldAnalysis(goat)
                                ) {
                                    Task {
                                        let analysis = await aiProvider.interpretMilkYieldTrends(records: goat.milkProduction, goat: goat)
                                        yieldAnalysis[goat.id] = analysis
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddMilkRecordView()
        }
        .sheet(item: $editingRecord) { record in
            EditMilkRecordView(record: record)
        }
    }
    
    private func getAllMilkRecords() -> [MilkRecordView] {
        return dataProvider.goats.flatMap { goat in
            goat.milkProduction.map { record in
                                                                  MilkRecordView(
                                     id: record.id,
                                     goatId: goat.id,
                                     date: record.date,
                                     morningYield: record.quantity / 2,
                                     eveningYield: record.quantity / 2,
                                     notes: record.notes
                                 )
            }
        }
    }
    
    private func getGoatName(for goatId: UUID) -> String {
        return dataProvider.goats.first { $0.id == goatId }?.name ?? "Unknown"
    }
    
    private func deleteMilkRecord(_ record: MilkRecordView) {
        if let goatIndex = dataProvider.goats.firstIndex(where: { $0.id == record.goatId }),
           let recordIndex = dataProvider.goats[goatIndex].milkProduction.firstIndex(where: { $0.id == record.id }) {
            dataProvider.goats[goatIndex].milkProduction.remove(at: recordIndex)
        }
    }
}

struct MilkRecordView: Identifiable {
    let id: UUID
    let goatId: UUID
    let date: Date
    let morningYield: Double
    let eveningYield: Double
    let notes: String
}

struct MilkRecordRow: View {
    let record: MilkRecordView
    let goatName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goatName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(record.morningYield, specifier: "%.1f")L", systemImage: "sunrise")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("\(record.eveningYield, specifier: "%.1f")L", systemImage: "sunset")
                    .font(.subheadline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("Total: \(record.morningYield + record.eveningYield, specifier: "%.1f")L")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

struct YieldAnalysisRow: View {
    let goat: Goat
    let analysis: String?
    let isLoading: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goat.photo)
                    .font(.title2)
                
                Text(goat.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let analysis = analysis {
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
                                .foregroundColor(.purple)
                            Text("Analyze")
                                .foregroundColor(.purple)
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            if let analysis = analysis {
                Text(analysis)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            } else if isLoading {
                Text("Analyzing milk yield trends...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

struct MilkProductionCard: View {
    let goat: Goat
    
    var totalProduction: Double {
        goat.milkProduction.reduce(0) { $0 + $1.quantity }
    }
    
    var averageDaily: Double {
        guard !goat.milkProduction.isEmpty else { return 0 }
        return totalProduction / Double(goat.milkProduction.count)
    }
    
    var lastRecord: MilkRecord? {
        goat.milkProduction.sorted { $0.date > $1.date }.first
    }
    
    var body: some View {
        Button {
            // Could navigate to detailed view
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goat.photo)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goat.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(goat.breed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Total:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(totalProduction, specifier: "%.1f")L")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Daily Avg:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(averageDaily, specifier: "%.2f")L")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    if let lastRecord = lastRecord {
                        HStack {
                            Text("Last:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(lastRecord.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
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

struct YieldAnalysisCard: View {
    let goat: Goat
    let analysis: String?
    let isLoadingAI: Bool
    let onRefresh: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goat.photo)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goat.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(goat.milkProduction.count) records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            if let analysis = analysis {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis)
                        .font(.caption)
                        .lineLimit(isExpanded ? nil : 6)
                        .multilineTextAlignment(.leading)
                    
                    if analysis.count > 250 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                    }
                }
            } else if isLoadingAI {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Analyzing trends...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: onRefresh) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text("Analyze trends")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: 240)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MilkRecordCard: View {
    let goat: Goat
    let record: MilkRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(goat.name) • \(goat.breed)")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(record.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(record.quantity, specifier: "%.2f") L")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    QualityBadge(quality: record.quality)
                }
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QualityBadge: View {
    let quality: MilkQuality
    
    var color: Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    var body: some View {
        Text(quality.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct ProductionTrendCard: View {
    let goat: Goat
    
    var recentRecords: [MilkRecord] {
        Array(goat.milkProduction.sorted { $0.date > $1.date }.prefix(14))
    }
    
    var trend: String {
        let recent7 = Array(recentRecords.prefix(7))
        let previous7 = Array(recentRecords.dropFirst(7))
        
        guard !recent7.isEmpty && !previous7.isEmpty else { return "Stable" }
        
        let recentAvg = recent7.reduce(0) { $0 + $1.quantity } / Double(recent7.count)
        let previousAvg = previous7.reduce(0) { $0 + $1.quantity } / Double(previous7.count)
        
        if recentAvg > previousAvg * 1.1 {
            return "Increasing"
        } else if recentAvg < previousAvg * 0.9 {
            return "Decreasing"
        } else {
            return "Stable"
        }
    }
    
    var trendColor: Color {
        switch trend {
        case "Increasing": return .green
        case "Decreasing": return .red
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goat.photo)
                    .font(.title2)
                
                Text(goat.name)
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(trend)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(trendColor)
                    
                    Text("14-day trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Simple trend visualization
            HStack(spacing: 2) {
                ForEach(recentRecords.reversed(), id: \.id) { record in
                    Rectangle()
                        .fill(trendColor.opacity(0.7))
                        .frame(height: max(4, record.quantity * 10))
                        .cornerRadius(1)
                }
            }
            .frame(height: 30)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AddMilkRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var selectedGoat: UUID?
    @State private var date = Date()
    @State private var quantity: Double = 0.0
    @State private var quality: MilkQuality = .good
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    Picker("Goat", selection: $selectedGoat) {
                        Text("Select Goat").tag(nil as UUID?)
                        ForEach(dataProvider.goats) { goat in
                            Text("\(goat.name) (\(goat.breed))").tag(goat.id as UUID?)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Milk Details") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Quantity", value: $quantity, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("Liters")
                    }
                    
                    Picker("Quality", selection: $quality) {
                        ForEach(MilkQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Milk Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let goatId = selectedGoat,
                           let goatIndex = dataProvider.goats.firstIndex(where: { $0.id == goatId }) {
                            let record = MilkRecord(
                                date: date,
                                quantity: quantity,
                                quality: quality,
                                notes: notes
                            )
                            
                            dataProvider.goats[goatIndex].milkProduction.append(record)
                            dataProvider.saveData()
                        }
                        dismiss()
                    }
                    .disabled(selectedGoat == nil || quantity <= 0)
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

struct EditMilkRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var date = Date()
    @State private var quantity: Double = 0.0
    @State private var quality: MilkQuality = .good
    @State private var notes = ""
    
    let record: MilkRecordView
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Milk Details") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Quantity", value: $quantity, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("Liters")
                    }
                    
                    Picker("Quality", selection: $quality) {
                        ForEach(MilkQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Milk Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let goatIndex = dataProvider.goats.firstIndex(where: { $0.id == record.goatId }),
                           let recordIndex = dataProvider.goats[goatIndex].milkProduction.firstIndex(where: { $0.id == record.id }) {
                                                         let updatedRecord = MilkRecord(
                                 date: date,
                                 quantity: record.morningYield + record.eveningYield,
                                 quality: .good,
                                 notes: notes
                             )
                             dataProvider.goats[goatIndex].milkProduction[recordIndex] = updatedRecord
                            dataProvider.saveData()
                        }
                        dismiss()
                    }
                    .disabled(quantity <= 0)
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

struct GoatMilkDetailView: View {
    let goat: Goat
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(goat.photo)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading) {
                            Text(goat.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(goat.breed) • \(goat.age) years")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Production Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Production Statistics")
                            .font(.headline)
                        
                        let totalProduction = goat.milkProduction.reduce(0) { $0 + $1.quantity }
                        let averageDaily = goat.milkProduction.isEmpty ? 0 : totalProduction / Double(goat.milkProduction.count)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total Production:")
                                Spacer()
                                Text("\(totalProduction, specifier: "%.1f") L")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Daily Average:")
                                Spacer()
                                Text("\(averageDaily, specifier: "%.2f") L")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Total Records:")
                                Spacer()
                                Text("\(goat.milkProduction.count)")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Milk Details")
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
    MilkYieldLogView()
} 