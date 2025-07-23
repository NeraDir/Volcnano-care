import SwiftUI

struct HealthChecksView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddRecord = false
    @State private var showingSymptomAnalysis = false
    @State private var selectedGoatForAnalysis: Goat?
    @State private var symptomText = ""
    @State private var analysisResult = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Health Status Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Health Overview", systemImage: "heart.text.square")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(dataProvider.goats) { goat in
                                HealthStatusCard(goat: goat)
                            }
                        }
                    }
                    .padding()
                    
                    // AI Symptom Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Label("AI Health Assistant", systemImage: "brain.head.profile")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Picker("Select Goat", selection: $selectedGoatForAnalysis) {
                                    Text("Choose a goat").tag(nil as Goat?)
                                    ForEach(dataProvider.goats) { goat in
                                        Text("\(goat.name) (\(goat.breed))").tag(goat as Goat?)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                Spacer()
                            }
                            
                            TextField("Describe symptoms...", text: $symptomText, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            HStack {
                                Button("Analyze Symptoms") {
                                    Task {
                                        if let goat = selectedGoatForAnalysis {
                                            analysisResult = await aiProvider.analyzeHealthSymptoms(symptoms: symptomText, goat: goat)
                                            showingSymptomAnalysis = true
                                        }
                                    }
                                }
                                .disabled(selectedGoatForAnalysis == nil || symptomText.isEmpty || aiProvider.isLoadingTask("health-\(selectedGoatForAnalysis?.id.uuidString ?? "")"))
                                .foregroundColor(.blue)
                                
                                if let goat = selectedGoatForAnalysis, aiProvider.isLoadingTask("health-\(goat.id.uuidString)") {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                Spacer()
                            }
                            
                            if !analysisResult.isEmpty && !showingSymptomAnalysis {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Latest Analysis:")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text(analysisResult)
                                        .font(.body)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    
                    // Recent Medical Records
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Medical Records", systemImage: "doc.text")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Button("Add Record") {
                                showingAddRecord = true
                            }
                            .foregroundColor(.green)
                        }
                        
                        let allRecords = getAllMedicalRecords()
                        if allRecords.isEmpty {
                            EmptyStateView(
                                icon: "🏥",
                                title: "No Medical Records",
                                message: "Start tracking health records for your goats"
                            )
                        } else {
                            ForEach(allRecords.prefix(10), id: \.record.id) { item in
                                MedicalRecordCard(goat: item.goat, record: item.record)
                            }
                        }
                    }
                    .padding()
                    
                    // Health Alerts
                    let alerts = getHealthAlerts()
                    if !alerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Health Alerts", systemImage: "exclamationmark.triangle")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            ForEach(alerts, id: \.goat.id) { alert in
                                HealthAlertCard(goat: alert.goat, message: alert.message)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Health Checks")
        }
        .sheet(isPresented: $showingAddRecord) {
            AddMedicalRecordView()
        }
        .sheet(isPresented: $showingSymptomAnalysis) {
            SymptomAnalysisView(goat: selectedGoatForAnalysis, symptoms: symptomText, analysis: analysisResult)
        }
    }
    
    private func getAllMedicalRecords() -> [(goat: Goat, record: MedicalRecord)] {
        var allRecords: [(goat: Goat, record: MedicalRecord)] = []
        
        for goat in dataProvider.goats {
            for record in goat.medicalHistory {
                allRecords.append((goat: goat, record: record))
            }
        }
        
        return allRecords.sorted { $0.record.date > $1.record.date }
    }
    
    private func getHealthAlerts() -> [(goat: Goat, message: String)] {
        var alerts: [(goat: Goat, message: String)] = []
        let calendar = Calendar.current
        let today = Date()
        
        for goat in dataProvider.goats {
            // Health status alerts
            if goat.healthStatus == .sick {
                alerts.append((goat: goat, message: "Currently sick - needs attention"))
            } else if goat.healthStatus == .checkup {
                alerts.append((goat: goat, message: "Scheduled for health checkup"))
            }
            
            // Vaccination reminders (if last vaccination was more than 6 months ago)
            if let lastVaccination = goat.medicalHistory.filter({ $0.type == .vaccination }).sorted(by: { $0.date > $1.date }).first {
                if let monthsAgo = calendar.dateComponents([.month], from: lastVaccination.date, to: today).month, monthsAgo >= 6 {
                    alerts.append((goat: goat, message: "Vaccination due (last: \(monthsAgo) months ago)"))
                }
            } else {
                alerts.append((goat: goat, message: "No vaccination records found"))
            }
        }
        
        return alerts
    }
}

struct HealthStatusCard: View {
    let goat: Goat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goat.photo)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goat.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(goat.breed)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HealthStatusBadge(status: goat.healthStatus)
            
            HStack {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(goat.medicalHistory.count) records")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastRecord = goat.medicalHistory.sorted(by: { $0.date > $1.date }).first {
                    Text(lastRecord.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MedicalRecordCard: View {
    let goat: Goat
    let record: MedicalRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.type.rawValue)
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("\(goat.name) • \(goat.breed)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !record.veterinarian.isEmpty {
                        Text("Dr. \(record.veterinarian)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !record.description.isEmpty {
                Text(record.description)
                    .font(.body)
            }
            
            if !record.treatment.isEmpty {
                HStack {
                    Image(systemName: "pills")
                        .foregroundColor(.blue)
                    Text("Treatment: \(record.treatment)")
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

struct HealthAlertCard: View {
    let goat: Goat
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goat.name)
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
}

struct AddMedicalRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var selectedGoat: UUID?
    @State private var recordType: MedicalType = .checkup
    @State private var date = Date()
    @State private var description = ""
    @State private var treatment = ""
    @State private var veterinarian = ""
    
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
                    
                    Picker("Record Type", selection: $recordType) {
                        ForEach(MedicalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Details") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Treatment", text: $treatment, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Veterinarian", text: $veterinarian)
                }
            }
            .navigationTitle("Add Medical Record")
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
                            let record = MedicalRecord(
                                date: date,
                                type: recordType,
                                description: description,
                                treatment: treatment,
                                veterinarian: veterinarian
                            )
                            
                            dataProvider.goats[goatIndex].medicalHistory.append(record)
                            dataProvider.saveData()
                        }
                        dismiss()
                    }
                    .disabled(selectedGoat == nil)
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

struct SymptomAnalysisView: View {
    let goat: Goat?
    let symptoms: String
    let analysis: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let goat = goat {
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
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reported Symptoms")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text(symptoms)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI Health Analysis", systemImage: "brain.head.profile")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(analysis)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Note")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("This AI analysis is for informational purposes only and should not replace professional veterinary care. Always consult with a qualified veterinarian for proper diagnosis and treatment.")
                            .font(.caption)
                            .italic()
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Health Analysis")
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
    HealthChecksView()
} 