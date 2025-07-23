import SwiftUI

struct FeedingNutritionView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddSchedule = false
    @State private var selectedGoatForPlan: Goat?
    @State private var feedingPlans: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // AI Feeding Plans Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Feeding Recommendations", systemImage: "brain.head.profile")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    feedingPlans.removeAll()
                                    for goat in dataProvider.goats {
                                        let plan = await aiProvider.generateFeedingPlan(for: goat)
                                        feedingPlans[goat.id] = plan
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.green)
                            }
                            .disabled(aiProvider.isLoading)
                        }
                        
                        if dataProvider.goats.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No goats in your herd")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Add goats to get personalized AI feeding plans")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(dataProvider.goats) { goat in
                                    FeedingPlanCard(
                                        goat: goat, 
                                        plan: feedingPlans[goat.id],
                                        isLoadingAI: aiProvider.isLoadingFeedingPlan(goat)
                                    ) {
                                        Task {
                                            let plan = await aiProvider.generateFeedingPlan(for: goat)
                                            feedingPlans[goat.id] = plan
                                        }
                                    }

                                }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Current Schedules
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Feeding Schedules", systemImage: "clock")
                                .font(.headline)
                                .foregroundColor(.brown)
                            
                            Spacer()
                            
                            Button("Add Schedule") {
                                showingAddSchedule = true
                            }
                            .foregroundColor(.brown)
                        }
                        
                        if dataProvider.feedingSchedules.isEmpty {
                                            VStack(spacing: 20) {
                    Spacer()
                    
                    EmptyStateView(
                        icon: "🌾",
                        title: "No Feeding Schedules",
                        message: "Create feeding schedules to track nutrition"
                    )
                    
                    Spacer()
                }
                        } else {
                            ForEach(dataProvider.feedingSchedules.sorted { $0.feedingTime < $1.feedingTime }) { schedule in
                                FeedingScheduleCard(schedule: schedule)
                            }
                        }
                    }
                    .padding()
                    
                    // Feed Consumption Trends
                    if !dataProvider.feedConsumption.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Consumption Trends", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            ForEach(dataProvider.goats) { goat in
                                let consumption = dataProvider.feedConsumption.filter { $0.goatId == goat.id }
                                if !consumption.isEmpty {
                                    ConsumptionTrendCard(goat: goat, consumption: consumption)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Feeding & Nutrition")
        }
        .sheet(isPresented: $showingAddSchedule) {
            AddFeedingScheduleView()
        }
    }
}

struct FeedingPlanCard: View {
    let goat: Goat
    let plan: String?
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
                    
                    Text(goat.breed)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let plan = plan {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan)
                        .font(.caption)
                        .lineLimit(isExpanded ? nil : 4)
                        .multilineTextAlignment(.leading)
                    
                    if plan.count > 150 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            } else if isLoadingAI {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Generating plan...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: onRefresh) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Generate AI plan")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FeedingScheduleCard: View {
    let schedule: FeedingSchedule
    @StateObject private var dataProvider = DataProvider.shared
    
    var goatName: String {
        if let goatId = schedule.goatId,
           let goat = dataProvider.getGoat(by: goatId) {
            return goat.name
        }
        return "Group Feeding"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: schedule.feedType.icon)
                    .foregroundColor(.brown)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.feedType.rawValue)
                        .font(.headline)
                    
                    Text(goatName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(schedule.quantity, specifier: "%.1f") kg")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(schedule.feedingTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !schedule.supplements.isEmpty {
                HStack {
                    Text("Supplements:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(schedule.supplements.joined(separator: ", "))
                        .font(.caption)
                }
            }
            
            if !schedule.notes.isEmpty {
                Text(schedule.notes)
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

struct ConsumptionTrendCard: View {
    let goat: Goat
    let consumption: [FeedConsumption]
    
    var averageConsumption: Double {
        let total = consumption.reduce(0) { $0 + $1.consumptionRate }
        return total / Double(consumption.count)
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
                    Text("\(averageConsumption, specifier: "%.1f")%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(averageConsumption >= 80 ? .green : averageConsumption >= 60 ? .orange : .red)
                    
                    Text("Avg. Consumption")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Simple trend visualization
            HStack(spacing: 2) {
                ForEach(consumption.suffix(7), id: \.id) { record in
                    Rectangle()
                        .fill(record.consumptionRate >= 80 ? Color.green : record.consumptionRate >= 60 ? Color.orange : Color.red)
                        .frame(height: max(4, record.consumptionRate / 100 * 20))
                        .cornerRadius(1)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AddFeedingScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var selectedGoat: UUID?
    @State private var feedType: FeedType = .hay
    @State private var quantity: Double = 1.0
    @State private var feedingTime = Date()
    @State private var supplements: [String] = []
    @State private var newSupplement = ""
    @State private var notes = ""
    @State private var isGroupFeeding = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Target") {
                    Toggle("Group Feeding", isOn: $isGroupFeeding)
                    
                    if !isGroupFeeding {
                        Picker("Goat", selection: $selectedGoat) {
                            Text("Select Goat").tag(nil as UUID?)
                            ForEach(dataProvider.goats) { goat in
                                Text("\(goat.name) (\(goat.breed))").tag(goat.id as UUID?)
                            }
                        }
                    }
                }
                
                Section("Feed Details") {
                    Picker("Feed Type", selection: $feedType) {
                        ForEach(FeedType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Quantity", value: $quantity, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("kg")
                    }
                    
                    DatePicker("Feeding Time", selection: $feedingTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Supplements") {
                    ForEach(supplements, id: \.self) { supplement in
                        HStack {
                            Text(supplement)
                            Spacer()
                            Button("Remove") {
                                supplements.removeAll { $0 == supplement }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add supplement", text: $newSupplement)
                        Button("Add") {
                            if !newSupplement.isEmpty {
                                supplements.append(newSupplement)
                                newSupplement = ""
                            }
                        }
                        .disabled(newSupplement.isEmpty)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Feeding Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let schedule = FeedingSchedule(
                            goatId: isGroupFeeding ? nil : selectedGoat,
                            feedType: feedType,
                            quantity: quantity,
                            feedingTime: feedingTime,
                            supplements: supplements,
                            notes: notes,
                            isGroupFeeding: isGroupFeeding
                        )
                        dataProvider.addFeedingSchedule(schedule)
                        dismiss()
                    }
                    .disabled(!isGroupFeeding && selectedGoat == nil)
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
    FeedingNutritionView()
} 