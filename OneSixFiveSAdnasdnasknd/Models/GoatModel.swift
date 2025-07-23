import Foundation

struct Goat: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var breed: String
    var age: Int
    var sex: GoatSex
    var healthStatus: HealthStatus
    var lineage: String
    var medicalHistory: [MedicalRecord]
    var milkProduction: [MilkRecord]
    var temperamentNotes: String
    var photo: String // System image name
    var dateAdded: Date
    
    init(name: String = "", breed: String = "", age: Int = 0, sex: GoatSex = .female, healthStatus: HealthStatus = .healthy, lineage: String = "", temperamentNotes: String = "", photo: String = "goat") {
        self.name = name
        self.breed = breed
        self.age = age
        self.sex = sex
        self.healthStatus = healthStatus
        self.lineage = lineage
        self.medicalHistory = []
        self.milkProduction = []
        self.temperamentNotes = temperamentNotes
        self.photo = photo
        self.dateAdded = Date()
    }
}

enum GoatSex: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
}

enum HealthStatus: String, CaseIterable, Codable {
    case healthy = "Healthy"
    case sick = "Sick"
    case recovering = "Recovering"
    case checkup = "Needs Checkup"
    
    var color: String {
        switch self {
        case .healthy: return "green"
        case .sick: return "red"
        case .recovering: return "orange"
        case .checkup: return "yellow"
        }
    }
}

struct MedicalRecord: Identifiable, Codable, Hashable {
    let id = UUID()
    var date: Date
    var type: MedicalType
    var description: String
    var treatment: String
    var veterinarian: String
    
    init(date: Date = Date(), type: MedicalType = .vaccination, description: String = "", treatment: String = "", veterinarian: String = "") {
        self.date = date
        self.type = type
        self.description = description
        self.treatment = treatment
        self.veterinarian = veterinarian
    }
}

enum MedicalType: String, CaseIterable, Codable {
    case vaccination = "Vaccination"
    case illness = "Illness"
    case injury = "Injury"
    case checkup = "Checkup"
    case treatment = "Treatment"
}

struct MilkRecord: Identifiable, Codable, Hashable {
    let id = UUID()
    var date: Date
    var quantity: Double // in liters
    var quality: MilkQuality
    var notes: String
    
    init(date: Date = Date(), quantity: Double = 0.0, quality: MilkQuality = .good, notes: String = "") {
        self.date = date
        self.quantity = quantity
        self.quality = quality
        self.notes = notes
    }
}

enum MilkQuality: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
} 