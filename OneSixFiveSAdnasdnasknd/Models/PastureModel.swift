import Foundation

struct Pasture: Identifiable, Codable {
    let id = UUID()
    var name: String
    var size: Double // in acres
    var grassType: GrassType
    var condition: PastureCondition
    var lastGrazedDate: Date?
    var restPeriod: Int // days
    var capacity: Int // number of goats
    var currentOccupancy: Int
    var notes: String
    var grazingHistory: [GrazingRecord]
    var dateCreated: Date
    
    init(name: String = "", size: Double = 0.0, grassType: GrassType = .mixed, condition: PastureCondition = .good, restPeriod: Int = 30, capacity: Int = 0, currentOccupancy: Int = 0, notes: String = "") {
        self.name = name
        self.size = size
        self.grassType = grassType
        self.condition = condition
        self.lastGrazedDate = nil
        self.restPeriod = restPeriod
        self.capacity = capacity
        self.currentOccupancy = currentOccupancy
        self.notes = notes
        self.grazingHistory = []
        self.dateCreated = Date()
    }
}

enum GrassType: String, CaseIterable, Codable {
    case mixed = "Mixed Grass"
    case bermuda = "Bermuda"
    case fescue = "Fescue"
    case clover = "Clover"
    case alfalfa = "Alfalfa"
    case orchard = "Orchard Grass"
    case timothy = "Timothy"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .mixed: return "leaf.fill"
        case .bermuda: return "leaf"
        case .fescue: return "leaf.arrow.circlepath"
        case .clover: return "leaf.circle"
        case .alfalfa: return "leaf.circle.fill"
        case .orchard: return "tree"
        case .timothy: return "leaf.arrow.triangle.circlepath"
        case .other: return "questionmark.circle"
        }
    }
}

enum PastureCondition: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case overgrazed = "Overgrazed"
    case resting = "Resting"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .overgrazed: return "red"
        case .resting: return "gray"
        }
    }
}

struct GrazingRecord: Identifiable, Codable {
    let id = UUID()
    var startDate: Date
    var endDate: Date?
    var numberOfGoats: Int
    var goatIds: [UUID]
    var conditionBefore: PastureCondition
    var conditionAfter: PastureCondition?
    var notes: String
    
    init(startDate: Date = Date(), endDate: Date? = nil, numberOfGoats: Int = 0, goatIds: [UUID] = [], conditionBefore: PastureCondition = .good, conditionAfter: PastureCondition? = nil, notes: String = "") {
        self.startDate = startDate
        self.endDate = endDate
        self.numberOfGoats = numberOfGoats
        self.goatIds = goatIds
        self.conditionBefore = conditionBefore
        self.conditionAfter = conditionAfter
        self.notes = notes
    }
} 