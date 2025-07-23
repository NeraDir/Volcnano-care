import Foundation

struct Equipment: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: EquipmentType
    var condition: EquipmentCondition
    var purchaseDate: Date
    var lastMaintenanceDate: Date?
    var nextMaintenanceDate: Date?
    var cost: Double
    var location: String
    var notes: String
    var maintenanceHistory: [MaintenanceRecord]
    var dateCreated: Date
    
    init(name: String = "", type: EquipmentType = .feeder, condition: EquipmentCondition = .good, purchaseDate: Date = Date(), cost: Double = 0.0, location: String = "", notes: String = "") {
        self.name = name
        self.type = type
        self.condition = condition
        self.purchaseDate = purchaseDate
        self.lastMaintenanceDate = nil
        self.nextMaintenanceDate = nil
        self.cost = cost
        self.location = location
        self.notes = notes
        self.maintenanceHistory = []
        self.dateCreated = Date()
    }
}

enum EquipmentType: String, CaseIterable, Codable {
    case feeder = "Feeder"
    case waterer = "Waterer"
    case fence = "Fence"
    case gate = "Gate"
    case shelter = "Shelter"
    case milkingStand = "Milking Stand"
    case scale = "Scale"
    case tools = "Tools"
    case medical = "Medical Equipment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .feeder: return "tray"
        case .waterer: return "drop"
        case .fence: return "rectangle.grid.1x2"
        case .gate: return "door.left.hand.open"
        case .shelter: return "house"
        case .milkingStand: return "table"
        case .scale: return "scalemass"
        case .tools: return "wrench"
        case .medical: return "cross.case"
        case .other: return "square.grid.2x2"
        }
    }
}

enum EquipmentCondition: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case needsReplacement = "Needs Replacement"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .needsReplacement: return "red"
        }
    }
}

struct MaintenanceRecord: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var type: MaintenanceType
    var description: String
    var cost: Double
    var performedBy: String
    var nextMaintenanceDate: Date?
    
    init(date: Date = Date(), type: MaintenanceType = .routine, description: String = "", cost: Double = 0.0, performedBy: String = "", nextMaintenanceDate: Date? = nil) {
        self.date = date
        self.type = type
        self.description = description
        self.cost = cost
        self.performedBy = performedBy
        self.nextMaintenanceDate = nextMaintenanceDate
    }
}

enum MaintenanceType: String, CaseIterable, Codable {
    case routine = "Routine"
    case repair = "Repair"
    case replacement = "Replacement"
    case cleaning = "Cleaning"
    case inspection = "Inspection"
} 