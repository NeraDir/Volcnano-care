import Foundation

struct BreedingRecord: Identifiable, Codable {
    let id = UUID()
    var doeId: UUID
    var buckId: UUID?
    var matingDate: Date
    var expectedBirthDate: Date
    var actualBirthDate: Date?
    var pregnancyStatus: PregnancyStatus
    var numberOfKids: Int
    var kidIds: [UUID]
    var notes: String
    var complications: String
    var dateCreated: Date
    
    init(doeId: UUID, buckId: UUID? = nil, matingDate: Date = Date(), pregnancyStatus: PregnancyStatus = .unknown, numberOfKids: Int = 0, notes: String = "", complications: String = "") {
        self.doeId = doeId
        self.buckId = buckId
        self.matingDate = matingDate
        self.expectedBirthDate = Calendar.current.date(byAdding: .day, value: 150, to: matingDate) ?? matingDate
        self.actualBirthDate = nil
        self.pregnancyStatus = pregnancyStatus
        self.numberOfKids = numberOfKids
        self.kidIds = []
        self.notes = notes
        self.complications = complications
        self.dateCreated = Date()
    }
}

enum PregnancyStatus: String, CaseIterable, Codable {
    case unknown = "Unknown"
    case confirmed = "Confirmed"
    case notPregnant = "Not Pregnant"
    case delivered = "Delivered"
    case complications = "Complications"
    
    var color: String {
        switch self {
        case .unknown: return "gray"
        case .confirmed: return "blue"
        case .notPregnant: return "red"
        case .delivered: return "green"
        case .complications: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .confirmed: return "checkmark.circle"
        case .notPregnant: return "xmark.circle"
        case .delivered: return "heart.circle"
        case .complications: return "exclamationmark.triangle"
        }
    }
}

struct BreedingEvent: Identifiable, Codable {
    let id = UUID()
    var title: String
    var date: Date
    var type: BreedingEventType
    var goatId: UUID
    var description: String
    var completed: Bool
    
    init(title: String = "", date: Date = Date(), type: BreedingEventType = .mating, goatId: UUID, description: String = "", completed: Bool = false) {
        self.title = title
        self.date = date
        self.type = type
        self.goatId = goatId
        self.description = description
        self.completed = completed
    }
}

enum BreedingEventType: String, CaseIterable, Codable {
    case mating = "Mating"
    case pregnancyCheck = "Pregnancy Check"
    case expectedBirth = "Expected Birth"
    case weaning = "Weaning"
    case breeding = "Breeding Season"
} 