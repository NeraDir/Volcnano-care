import SwiftUI

struct BreedingTrackerView: View {
    @StateObject private var dataProvider = DataProvider.shared
    @StateObject private var aiProvider = AIProvider.shared
    @State private var showingAddRecord = false
    @State private var editingRecord: BreedingRecord?
    @State private var selectedGoatForTips: Goat?
    @State private var breedingTips: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // AI Breeding Tips Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Breeding Tips", systemImage: "brain.head.profile")
                                .font(.headline)
                                .foregroundColor(.pink)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    breedingTips.removeAll()
                                    for goat in dataProvider.goats.filter({ $0.sex == .female }) {
                                        let tips = await aiProvider.generateBreedingTips(for: goat)
                                        breedingTips[goat.id] = tips
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.pink)
                            }
                            .disabled(aiProvider.isLoading)
                        }
                        
                        let femaleGoats = dataProvider.goats.filter { $0.sex == .female }
                        
                        if femaleGoats.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No female goats in your herd")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Add female goats to get AI breeding insights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(femaleGoats) { goat in
                                    BreedingTipCard(
                                        goat: goat, 
                                        tips: breedingTips[goat.id],
                                        isLoadingAI: aiProvider.isLoadingBreedingTips(goat)
                                    ) {
                                        Task {
                                            let tips = await aiProvider.generateBreedingTips(for: goat)
                                            breedingTips[goat.id] = tips
                                        }
                                    }
                                    
                                }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Current Breeding Records
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Breeding Records", systemImage: "heart.circle")
                                .font(.headline)
                                .foregroundColor(.pink)
                            
                            Spacer()
                            
                            Button("Add Record") {
                                showingAddRecord = true
                            }
                            .foregroundColor(.pink)
                        }
                        
                        if dataProvider.breedingRecords.isEmpty {
                                            VStack(spacing: 20) {
                    Spacer()
                    
                    EmptyStateView(
                        icon: "💕",
                        title: "No Breeding Records",
                        message: "Start tracking breeding activities for your herd"
                    )
                    
                    Spacer()
                }
                        } else {
                            ForEach(dataProvider.breedingRecords.sorted { $0.matingDate > $1.matingDate }) { record in
                                BreedingRecordCard(record: record)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Delete") {
                                            dataProvider.deleteBreedingRecord(record)
                                        }
                                        .tint(.red)
                                        
                                        Button("Edit") {
                                            editingRecord = record
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    }
                    .padding()
                    
                    // Upcoming Events
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Upcoming Events", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        let upcomingEvents = getUpcomingEvents()
                        if upcomingEvents.isEmpty {
                            Text("No upcoming breeding events")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(upcomingEvents, id: \.id) { event in
                                UpcomingEventCard(event: event)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Delete") {
                                            deleteEvent(event)
                                        }
                                        .tint(.red)
                                        
                                        Button("Edit") {
                                            editEvent(event)
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Breeding Tracker")
        }
        .sheet(isPresented: $showingAddRecord) {
            AddBreedingRecordView()
        }
        .sheet(item: $editingRecord) { record in
            EditBreedingRecordView(record: record)
        }
    }
    
    private func getUpcomingEvents() -> [BreedingEvent] {
        var events: [BreedingEvent] = []
        let calendar = Calendar.current
        let today = Date()
        
        for record in dataProvider.breedingRecords {
            // Expected birth events
            if record.pregnancyStatus == .confirmed && record.actualBirthDate == nil {
                let event = BreedingEvent(
                    title: "Expected Birth",
                    date: record.expectedBirthDate,
                    type: .expectedBirth,
                    goatId: record.doeId,
                    description: "Expected kidding date"
                )
                if event.date >= today {
                    events.append(event)
                }
            }
            
            // Pregnancy check reminders
            if record.pregnancyStatus == .unknown {
                let checkDate = calendar.date(byAdding: .day, value: 21, to: record.matingDate) ?? record.matingDate
                let event = BreedingEvent(
                    title: "Pregnancy Check",
                    date: checkDate,
                    type: .pregnancyCheck,
                    goatId: record.doeId,
                    description: "Time to check for pregnancy"
                )
                if event.date >= today {
                    events.append(event)
                }
            }
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    private func deleteEvent(_ event: BreedingEvent) {
        // Find and delete the corresponding breeding record
        if let recordIndex = dataProvider.breedingRecords.firstIndex(where: { record in
            (event.type == .expectedBirth && record.doeId == event.goatId && record.pregnancyStatus == .confirmed) ||
            (event.type == .pregnancyCheck && record.doeId == event.goatId && record.pregnancyStatus == .unknown)
        }) {
            dataProvider.breedingRecords.remove(at: recordIndex)
        }
    }
    
    private func editEvent(_ event: BreedingEvent) {
        // For now, just show the add record view
        // In a full implementation, you would populate the form with existing data
        showingAddRecord = true
    }
}

struct BreedingTipCard: View {
    let goat: Goat
    let tips: String?
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
                    
                    Text("\(goat.breed), \(goat.age) years")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
            
            if let tips = tips {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tips)
                        .font(.caption)
                        .lineLimit(isExpanded ? nil : 5)
                        .multilineTextAlignment(.leading)
                    
                    if tips.count > 200 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }
                    }
                }
            } else if isLoadingAI {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Getting breeding tips...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: onRefresh) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.pink)
                            .font(.caption)
                        Text("Get AI tips")
                            .font(.caption)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: 220)
        .background(Color.pink.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BreedingRecordCard: View {
    let record: BreedingRecord
    @StateObject private var dataProvider = DataProvider.shared
    
    var doeName: String {
        dataProvider.getGoat(by: record.doeId)?.name ?? "Unknown"
    }
    
    var buckName: String {
        if let buckId = record.buckId {
            return dataProvider.getGoat(by: buckId)?.name ?? "Unknown"
        }
        return "Not specified"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: record.pregnancyStatus.icon)
                    .foregroundColor(Color(record.pregnancyStatus.color))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(doeName) × \(buckName)")
                        .font(.headline)
                    
                    Text("Mated: \(record.matingDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(record.pregnancyStatus.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(record.pregnancyStatus.color).opacity(0.2))
                        .foregroundColor(Color(record.pregnancyStatus.color))
                        .cornerRadius(8)
                    
                    if record.pregnancyStatus == .confirmed || record.pregnancyStatus == .delivered {
                        Text("Due: \(record.expectedBirthDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if record.pregnancyStatus == .delivered {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                    Text("\(record.numberOfKids) kid(s) born")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let birthDate = record.actualBirthDate {
                        Text("on \(birthDate, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
            }
            
            if !record.complications.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(record.complications)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct UpcomingEventCard: View {
    let event: BreedingEvent
    @StateObject private var dataProvider = DataProvider.shared
    
    var goatName: String {
        dataProvider.getGoat(by: event.goatId)?.name ?? "Unknown"
    }
    
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text(goatName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(event.description)
                    .font(.caption)
                    .italic()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if daysUntil == 0 {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                } else if daysUntil > 0 {
                    Text("\(daysUntil) days")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(daysUntil <= 7 ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(daysUntil <= 0 ? Color.red : daysUntil <= 7 ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

struct AddBreedingRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    @State private var selectedDoe: UUID?
    @State private var selectedBuck: UUID?
    @State private var matingDate = Date()
    @State private var pregnancyStatus: PregnancyStatus = .unknown
    @State private var numberOfKids = 0
    @State private var actualBirthDate: Date?
    @State private var notes = ""
    @State private var complications = ""
    @State private var showingBirthDate = false
    
    var does: [Goat] {
        dataProvider.goats.filter { $0.sex == .female }
    }
    
    var bucks: [Goat] {
        dataProvider.goats.filter { $0.sex == .male }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Breeding Pair") {
                    Picker("Doe (Female)", selection: $selectedDoe) {
                        Text("Select Doe").tag(nil as UUID?)
                        ForEach(does) { goat in
                            Text("\(goat.name) (\(goat.breed))").tag(goat.id as UUID?)
                        }
                    }
                    
                    Picker("Buck (Male)", selection: $selectedBuck) {
                        Text("Select Buck").tag(nil as UUID?)
                        ForEach(bucks) { goat in
                            Text("\(goat.name) (\(goat.breed))").tag(goat.id as UUID?)
                        }
                    }
                }
                
                Section("Breeding Details") {
                    DatePicker("Mating Date", selection: $matingDate, displayedComponents: .date)
                    
                    Picker("Pregnancy Status", selection: $pregnancyStatus) {
                        ForEach(PregnancyStatus.allCases, id: \.self) { status in
                            Label(status.rawValue, systemImage: status.icon).tag(status)
                        }
                    }
                    
                    if pregnancyStatus == .delivered {
                        HStack {
                            Text("Number of Kids")
                            Spacer()
                            Stepper(value: $numberOfKids, in: 0...5) {
                                Text("\(numberOfKids)")
                            }
                        }
                        
                        Toggle("Birth Date Known", isOn: $showingBirthDate)
                        
                        if showingBirthDate {
                            DatePicker("Birth Date", selection: Binding(
                                get: { actualBirthDate ?? Date() },
                                set: { actualBirthDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Complications", text: $complications, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Breeding Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let record = BreedingRecord(
                            doeId: selectedDoe!,
                            buckId: selectedBuck,
                            matingDate: matingDate,
                            pregnancyStatus: pregnancyStatus,
                            numberOfKids: numberOfKids,
                            notes: notes,
                            complications: complications
                        )
                        
                        if showingBirthDate && pregnancyStatus == .delivered {
                            var updatedRecord = record
                            updatedRecord.actualBirthDate = actualBirthDate
                            dataProvider.addBreedingRecord(updatedRecord)
                        } else {
                            dataProvider.addBreedingRecord(record)
                        }
                        
                        dismiss()
                    }
                    .disabled(selectedDoe == nil)
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

struct EditBreedingRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataProvider = DataProvider.shared
    
    let record: BreedingRecord
    @State private var selectedDoe: UUID?
    @State private var selectedBuck: UUID?
    @State private var matingDate = Date()
    @State private var pregnancyStatus: PregnancyStatus = .unknown
    @State private var numberOfKids = 0
    @State private var actualBirthDate: Date?
    @State private var notes = ""
    @State private var complications = ""
    @State private var showingBirthDate = false
    
    var does: [Goat] {
        dataProvider.goats.filter { $0.sex == .female }
    }
    
    var bucks: [Goat] {
        dataProvider.goats.filter { $0.sex == .male }
    }
    
    init(record: BreedingRecord) {
        self.record = record
        _selectedDoe = State(initialValue: record.doeId)
        _selectedBuck = State(initialValue: record.buckId)
        _matingDate = State(initialValue: record.matingDate)
        _pregnancyStatus = State(initialValue: record.pregnancyStatus)
        _numberOfKids = State(initialValue: record.numberOfKids)
        _actualBirthDate = State(initialValue: record.actualBirthDate)
        _notes = State(initialValue: record.notes)
        _complications = State(initialValue: record.complications)
        _showingBirthDate = State(initialValue: record.actualBirthDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Breeding Information") {
                    Picker("Doe (Female)", selection: $selectedDoe) {
                        Text("Select Doe").tag(nil as UUID?)
                        ForEach(does, id: \.id) { goat in
                            Text("\(goat.photo) \(goat.name)").tag(goat.id as UUID?)
                        }
                    }
                    
                    Picker("Buck (Male)", selection: $selectedBuck) {
                        Text("Select Buck").tag(nil as UUID?)
                        ForEach(bucks, id: \.id) { goat in
                            Text("\(goat.photo) \(goat.name)").tag(goat.id as UUID?)
                        }
                    }
                    
                    DatePicker("Mating Date", selection: $matingDate, displayedComponents: .date)
                }
                
                Section("Pregnancy Status") {
                    Picker("Status", selection: $pregnancyStatus) {
                        ForEach(PregnancyStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if pregnancyStatus == .confirmed {
                        Toggle("Birth Date Known", isOn: $showingBirthDate)
                        
                        if showingBirthDate {
                            DatePicker("Birth Date", selection: Binding(
                                get: { actualBirthDate ?? Date() },
                                set: { actualBirthDate = $0 }
                            ), displayedComponents: .date)
                            
                            Stepper("Number of Kids: \(numberOfKids)", value: $numberOfKids, in: 0...10)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("General Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Complications (if any)", text: $complications, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Breeding Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedRecord = record
                        updatedRecord.doeId = selectedDoe!
                        updatedRecord.buckId = selectedBuck!
                        updatedRecord.matingDate = matingDate
                        updatedRecord.pregnancyStatus = pregnancyStatus
                        updatedRecord.expectedBirthDate = Calendar.current.date(byAdding: .day, value: 150, to: matingDate) ?? matingDate
                        updatedRecord.actualBirthDate = showingBirthDate ? actualBirthDate : nil
                        updatedRecord.numberOfKids = pregnancyStatus == .confirmed ? numberOfKids : 0
                        updatedRecord.notes = notes
                        updatedRecord.complications = complications
                        
                        dataProvider.updateBreedingRecord(updatedRecord)
                        dismiss()
                    }
                    .disabled(selectedDoe == nil || selectedBuck == nil)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

#Preview {
    BreedingTrackerView()
} 