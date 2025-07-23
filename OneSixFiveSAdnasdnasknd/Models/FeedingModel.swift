import Foundation

struct FeedingSchedule: Identifiable, Codable {
    let id = UUID()
    var goatId: UUID?
    var feedType: FeedType
    var quantity: Double // in kg
    var feedingTime: Date
    var supplements: [String]
    var notes: String
    var isGroupFeeding: Bool
    var dateCreated: Date
    
    init(goatId: UUID? = nil, feedType: FeedType = .hay, quantity: Double = 0.0, feedingTime: Date = Date(), supplements: [String] = [], notes: String = "", isGroupFeeding: Bool = false) {
        self.goatId = goatId
        self.feedType = feedType
        self.quantity = quantity
        self.feedingTime = feedingTime
        self.supplements = supplements
        self.notes = notes
        self.isGroupFeeding = isGroupFeeding
        self.dateCreated = Date()
    }
}

enum FeedType: String, CaseIterable, Codable {
    case hay = "Hay"
    case grain = "Grain"
    case pellets = "Pellets"
    case grass = "Fresh Grass"
    case browse = "Browse"
    case silage = "Silage"
    case minerals = "Minerals"
    
    var icon: String {
        switch self {
        case .hay: return "leaf"
        case .grain: return "circle.fill"
        case .pellets: return "circle.grid.2x2"
        case .grass: return "leaf.fill"
        case .browse: return "tree"
        case .silage: return "square.stack"
        case .minerals: return "diamond"
        }
    }
}

struct FeedConsumption: Identifiable, Codable {
    let id = UUID()
    var goatId: UUID
    var date: Date
    var feedType: FeedType
    var plannedQuantity: Double
    var actualQuantity: Double
    var consumptionRate: Double // percentage
    var notes: String
    
    init(goatId: UUID, date: Date = Date(), feedType: FeedType = .hay, plannedQuantity: Double = 0.0, actualQuantity: Double = 0.0, notes: String = "") {
        self.goatId = goatId
        self.date = date
        self.feedType = feedType
        self.plannedQuantity = plannedQuantity
        self.actualQuantity = actualQuantity
        self.consumptionRate = plannedQuantity > 0 ? (actualQuantity / plannedQuantity) * 100 : 0
        self.notes = notes
    }
} 