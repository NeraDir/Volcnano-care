import SwiftUI

struct HerdOverviewView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddGoat = false
    @State private var selectedGoat: Goat?
    @State private var editingGoat: Goat?
    @State private var aiSummaries: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            VStack {
                if dataProvider.goats.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "🐐",
                        title: "No Goats Yet",
                        message: "Add your first goat to start managing your herd"
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(dataProvider.goats) { goat in
                            GoatCard(
                                goat: goat, 
                                aiSummary: aiSummaries[goat.id],
                                isLoadingAI: aiProvider.isLoadingGoatProfile(goat)
                            ) {
                                selectedGoat = goat
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete") {
                                    withAnimation {
                                        dataProvider.deleteGoat(goat)
                                        aiSummaries.removeValue(forKey: goat.id)
                                    }
                                }
                                .tint(.red)
                                
                                Button("Edit") {
                                    editingGoat = goat
                                }
                                .tint(.blue)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Herd Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Goat") {
                        showingAddGoat = true
                    }
                    .foregroundColor(.brown)
                }
            }
        }
        .sheet(isPresented: $showingAddGoat) {
            AddGoatView()
        }
        .sheet(item: $selectedGoat) { goat in
            GoatDetailView(goat: goat)
        }
        .sheet(item: $editingGoat) { goat in
            EditGoatView(goat: goat)
        }
    }
}

struct GoatCard: View {
    let goat: Goat
    let aiSummary: String?
    let isLoadingAI: Bool
    let onTap: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goat.photo)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goat.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(goat.breed) • \(goat.age) years • \(goat.sex.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HealthStatusBadge(status: goat.healthStatus)
                }
                
                if let summary = aiSummary {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 3)
                        
                        if summary.count > 100 {
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
                } else if isLoadingAI {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Getting AI insights...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !goat.temperamentNotes.isEmpty {
                    Text("Temperament: \(goat.temperamentNotes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
                    .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthStatusBadge: View {
    let status: HealthStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(8)
    }
}

struct AddGoatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var name = ""
    @State private var breed = ""
    @State private var age = 0
    @State private var sex: GoatSex = .female
    @State private var healthStatus: HealthStatus = .healthy
    @State private var lineage = ""
    @State private var temperamentNotes = ""
    @State private var selectedPhoto = "🐐"
    
    let photos = ["🐐", "🐑", "🦌", "🐕", "🐾"]
    
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
            .navigationTitle("Add New Goat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newGoat = Goat(
                            name: name,
                            breed: breed,
                            age: age,
                            sex: sex,
                            healthStatus: healthStatus,
                            lineage: lineage,
                            temperamentNotes: temperamentNotes,
                            photo: selectedPhoto
                        )
                        dataProvider.addGoat(newGoat)
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

struct GoatDetailView: View {
    let goat: Goat
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiProvider = AIProvider.shared
    @State private var aiSummary = ""
    @State private var isExpanded = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(goat.photo)
                            .font(.system(size: 60))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(goat.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(goat.breed) • \(goat.age) years")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            HealthStatusBadge(status: goat.healthStatus)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // AI Insights Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI Insights")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Powered by advanced analytics")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    aiSummary = await aiProvider.generateGoatProfileSummary(for: goat)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: aiProvider.isLoadingGoatProfile(goat) ? "arrow.clockwise" : "sparkles")
                                        .font(.caption)
                                        .rotationEffect(.degrees(aiProvider.isLoadingGoatProfile(goat) ? 360 : 0))
                                        .animation(aiProvider.isLoadingGoatProfile(goat) ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: aiProvider.isLoadingGoatProfile(goat))
                                    Text(aiProvider.isLoadingGoatProfile(goat) ? "Analyzing..." : "Refresh")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                            }
                            .disabled(aiProvider.isLoadingGoatProfile(goat))
                        }
                        
                        // Content
                        Group {
                            if !aiSummary.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Profile Analysis")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(aiSummary)
                                            .font(.body)
                                            .lineSpacing(2)
                                            .foregroundColor(.primary)
                                            .lineLimit(isExpanded ? nil : 6)
                                        
                                        if aiSummary.count > 300 {
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    isExpanded.toggle()
                                                }
                                            }) {
                                                Text(isExpanded ? "Show less" : "Show more")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            } else if aiProvider.isLoadingGoatProfile(goat) {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.blue)
                                    
                                    VStack(spacing: 4) {
                                        Text("Analyzing goat profile...")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("This may take a few seconds")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Sex", value: goat.sex.rawValue)
                        DetailRow(title: "Lineage", value: goat.lineage.isEmpty ? "Not specified" : goat.lineage)
                        DetailRow(title: "Temperament", value: goat.temperamentNotes.isEmpty ? "Not specified" : goat.temperamentNotes)
                        DetailRow(title: "Date Added", value: DateFormatter.short.string(from: goat.dateAdded))
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Goat Details")
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

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 60))
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    HerdOverviewView()
} 