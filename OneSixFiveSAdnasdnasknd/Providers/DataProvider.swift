import Foundation
import SwiftUI

@MainActor
class DataProvider: ObservableObject {
    static let shared = DataProvider()
    
    @Published var goats: [Goat] = []
    @Published var feedingSchedules: [FeedingSchedule] = []
    @Published var breedingRecords: [BreedingRecord] = []
    @Published var equipment: [Equipment] = []
    @Published var pastures: [Pasture] = []
    @Published var feedConsumption: [FeedConsumption] = []
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadData()
        createSampleData()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        if let goatsData = userDefaults.data(forKey: "goats"),
           let decodedGoats = try? JSONDecoder().decode([Goat].self, from: goatsData) {
            goats = decodedGoats
        }
        
        if let feedingData = userDefaults.data(forKey: "feedingSchedules"),
           let decodedFeeding = try? JSONDecoder().decode([FeedingSchedule].self, from: feedingData) {
            feedingSchedules = decodedFeeding
        }
        
        if let breedingData = userDefaults.data(forKey: "breedingRecords"),
           let decodedBreeding = try? JSONDecoder().decode([BreedingRecord].self, from: breedingData) {
            breedingRecords = decodedBreeding
        }
        
        if let equipmentData = userDefaults.data(forKey: "equipment"),
           let decodedEquipment = try? JSONDecoder().decode([Equipment].self, from: equipmentData) {
            equipment = decodedEquipment
        }
        
        if let pasturesData = userDefaults.data(forKey: "pastures"),
           let decodedPastures = try? JSONDecoder().decode([Pasture].self, from: pasturesData) {
            pastures = decodedPastures
        }
        
        if let consumptionData = userDefaults.data(forKey: "feedConsumption"),
           let decodedConsumption = try? JSONDecoder().decode([FeedConsumption].self, from: consumptionData) {
            feedConsumption = decodedConsumption
        }
    }
    
    func saveData() {
        if let goatsData = try? JSONEncoder().encode(goats) {
            userDefaults.set(goatsData, forKey: "goats")
        }
        
        if let feedingData = try? JSONEncoder().encode(feedingSchedules) {
            userDefaults.set(feedingData, forKey: "feedingSchedules")
        }
        
        if let breedingData = try? JSONEncoder().encode(breedingRecords) {
            userDefaults.set(breedingData, forKey: "breedingRecords")
        }
        
        if let equipmentData = try? JSONEncoder().encode(equipment) {
            userDefaults.set(equipmentData, forKey: "equipment")
        }
        
        if let pasturesData = try? JSONEncoder().encode(pastures) {
            userDefaults.set(pasturesData, forKey: "pastures")
        }
        
        if let consumptionData = try? JSONEncoder().encode(feedConsumption) {
            userDefaults.set(consumptionData, forKey: "feedConsumption")
        }
    }
    
    // MARK: - Sample Data Creation
    
    private func createSampleData() {
        if goats.isEmpty {
            let sampleGoats = [
                Goat(name: "Bella", breed: "Nubian", age: 3, sex: .female, healthStatus: .healthy, lineage: "Champion bloodline", temperamentNotes: "Gentle and friendly", photo: "🐐"),
                Goat(name: "Max", breed: "Boer", age: 2, sex: .male, healthStatus: .healthy, lineage: "Strong genetics", temperamentNotes: "Protective leader", photo: "🐐"),
                Goat(name: "Luna", breed: "Alpine", age: 1, sex: .female, healthStatus: .checkup, lineage: "Mountain heritage", temperamentNotes: "Playful and curious", photo: "🐐")
            ]
            goats = sampleGoats
            saveData()
        }
        
        if pastures.isEmpty {
            let samplePastures = [
                Pasture(name: "North Field", size: 2.5, grassType: .mixed, condition: .good, restPeriod: 30, capacity: 6, currentOccupancy: 0, notes: "Well-drained area with natural shade"),
                Pasture(name: "South Meadow", size: 1.8, grassType: .clover, condition: .excellent, restPeriod: 25, capacity: 4, currentOccupancy: 0, notes: "Rich soil, recently reseeded")
            ]
            pastures = samplePastures
            saveData()
        }
        
        if equipment.isEmpty {
            let sampleEquipment = [
                Equipment(name: "Main Feeder", type: .feeder, condition: .good, purchaseDate: Date().addingTimeInterval(-365*24*60*60), cost: 150.0, location: "Barn", notes: "Holds 50 lbs of feed"),
                Equipment(name: "Water Trough", type: .waterer, condition: .excellent, purchaseDate: Date().addingTimeInterval(-200*24*60*60), cost: 85.0, location: "Pasture", notes: "Automatic refill system")
            ]
            equipment = sampleEquipment
            saveData()
        }
    }
    
    // MARK: - CRUD Operations
    
    // Goats
    func addGoat(_ goat: Goat) {
        goats.append(goat)
        saveData()
    }
    
    func updateGoat(_ goat: Goat) {
        if let index = goats.firstIndex(where: { $0.id == goat.id }) {
            goats[index] = goat
            saveData()
        }
    }
    
    func deleteGoat(_ goat: Goat) {
        goats.removeAll { $0.id == goat.id }
        saveData()
    }
    
    // Feeding Schedules
    func addFeedingSchedule(_ schedule: FeedingSchedule) {
        feedingSchedules.append(schedule)
        saveData()
    }
    
    func updateFeedingSchedule(_ schedule: FeedingSchedule) {
        if let index = feedingSchedules.firstIndex(where: { $0.id == schedule.id }) {
            feedingSchedules[index] = schedule
            saveData()
        }
    }
    
    func deleteFeedingSchedule(_ schedule: FeedingSchedule) {
        feedingSchedules.removeAll { $0.id == schedule.id }
        saveData()
    }
    
    // Breeding Records
    func addBreedingRecord(_ record: BreedingRecord) {
        breedingRecords.append(record)
        saveData()
    }
    
    func updateBreedingRecord(_ record: BreedingRecord) {
        if let index = breedingRecords.firstIndex(where: { $0.id == record.id }) {
            breedingRecords[index] = record
            saveData()
        }
    }
    
    func deleteBreedingRecord(_ record: BreedingRecord) {
        breedingRecords.removeAll { $0.id == record.id }
        saveData()
    }
    
    // Equipment
    func addEquipment(_ item: Equipment) {
        equipment.append(item)
        saveData()
    }
    
    func updateEquipment(_ item: Equipment) {
        if let index = equipment.firstIndex(where: { $0.id == item.id }) {
            equipment[index] = item
            saveData()
        }
    }
    
    func deleteEquipment(_ item: Equipment) {
        equipment.removeAll { $0.id == item.id }
        saveData()
    }
    
    // Pastures
    func addPasture(_ pasture: Pasture) {
        pastures.append(pasture)
        saveData()
    }
    
    func updatePasture(_ pasture: Pasture) {
        if let index = pastures.firstIndex(where: { $0.id == pasture.id }) {
            pastures[index] = pasture
            saveData()
        }
    }
    
    func deletePasture(_ pasture: Pasture) {
        pastures.removeAll { $0.id == pasture.id }
        saveData()
    }
    
    // Helper Methods
    func getGoat(by id: UUID) -> Goat? {
        return goats.first { $0.id == id }
    }
    
    func getPasture(by id: UUID) -> Pasture? {
        return pastures.first { $0.id == id }
    }
} 