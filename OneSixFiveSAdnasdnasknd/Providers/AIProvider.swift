import Foundation
import SwiftUI

@MainActor
class AIProvider: ObservableObject {
    static let shared = AIProvider()
    
    @Published var isLoading = false
    @Published var lastResponse = ""
    @Published var errorMessage = ""
    @Published var loadingTasks: Set<String> = []
    
    private let apiKey = "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"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    // MARK: - AI Integration Methods
    
    func generateGoatProfileSummary(for goat: Goat) async -> String {
        let prompt = """
        Generate a brief, friendly summary for this goat profile:
        Name: \(goat.name)
        Breed: \(goat.breed)
        Age: \(goat.age) years
        Sex: \(goat.sex.rawValue)
        Health Status: \(goat.healthStatus.rawValue)
        Temperament: \(goat.temperamentNotes)
        
        Please provide 2-3 sentences highlighting the goat's key characteristics and any notable traits.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are a helpful goat farming assistant. Provide concise, friendly summaries.", taskId: "profile-\(goat.id.uuidString)")
    }
    
    func generateFeedingPlan(for goat: Goat) async -> String {
        let prompt = """
        Suggest an optimized feeding plan for this goat:
        Name: \(goat.name)
        Breed: \(goat.breed)
        Age: \(goat.age) years
        Sex: \(goat.sex.rawValue)
        Health Status: \(goat.healthStatus.rawValue)
        
        Please provide specific recommendations for feed types, quantities, and feeding schedule.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert in goat nutrition. Provide practical feeding advice.", taskId: "feeding-\(goat.id.uuidString)")
    }
    
    func generateBreedingTips(for goat: Goat) async -> String {
        let prompt = """
        Provide breeding tips and best practices for this goat:
        Name: \(goat.name)
        Breed: \(goat.breed)
        Age: \(goat.age) years
        Sex: \(goat.sex.rawValue)
        Health Status: \(goat.healthStatus.rawValue)
        
        Include timing recommendations, health considerations, and breeding best practices.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are a goat breeding expert. Provide helpful breeding guidance.", taskId: "breeding-\(goat.id.uuidString)")
    }
    
    func analyzeHealthSymptoms(symptoms: String, goat: Goat) async -> String {
        let prompt = """
        Analyze these health symptoms for a goat and suggest treatments:
        Goat Details:
        - Name: \(goat.name)
        - Breed: \(goat.breed)
        - Age: \(goat.age) years
        - Sex: \(goat.sex.rawValue)
        
        Symptoms: \(symptoms)
        
        Please provide possible causes, recommended treatments, and when to consult a veterinarian.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are a veterinary assistant specializing in goat health. Provide helpful but not diagnostic advice.", taskId: "health-\(goat.id.uuidString)")
    }
    
    func interpretMilkYieldTrends(records: [MilkRecord], goat: Goat) async -> String {
        let totalYield = records.reduce(0) { $0 + $1.quantity }
        let averageYield = records.isEmpty ? 0 : totalYield / Double(records.count)
        
        let prompt = """
        Interpret milk yield trends for this goat:
        Goat: \(goat.name) (\(goat.breed), \(goat.age) years old)
        Total records: \(records.count)
        Average daily yield: \(String(format: "%.2f", averageYield)) liters
        
        Recent yield data shows variations. Please analyze potential causes for yield changes and suggest improvements for milk production.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are a dairy goat specialist. Provide insights on milk production optimization.", taskId: "milk-\(goat.id.uuidString)")
    }
    
    func generatePastureManagementAdvice(for pasture: Pasture) async -> String {
        let prompt = """
        Provide pasture management advice for this field:
        Name: \(pasture.name)
        Size: \(pasture.size) acres
        Grass Type: \(pasture.grassType.rawValue)
        Condition: \(pasture.condition.rawValue)
        Capacity: \(pasture.capacity) goats
        Current Occupancy: \(pasture.currentOccupancy) goats
        Rest Period: \(pasture.restPeriod) days
        
        Please suggest optimal grazing strategies, rest periods, and pasture improvement techniques.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are a pasture management expert. Provide practical grazing advice.", taskId: "pasture-\(pasture.id.uuidString)")
    }
    
    func generateEquipmentMaintenanceTips(for equipment: Equipment) async -> String {
        let prompt = """
        Provide maintenance tips for this farm equipment:
        Name: \(equipment.name)
        Type: \(equipment.type.rawValue)
        Condition: \(equipment.condition.rawValue)
        Location: \(equipment.location)
        
        Please suggest maintenance schedules, care tips, and upgrade recommendations if needed.
        """
        
        return await makeAPIRequest(prompt: prompt, systemMessage: "You are a farm equipment specialist. Provide practical maintenance advice.", taskId: "equipment-\(equipment.id.uuidString)")
    }
    
    func answerGeneralQuestion(_ question: String) async -> String {
        return await makeAPIRequest(prompt: question, systemMessage: "You are a knowledgeable goat farming advisor. Provide helpful, practical advice for small-scale goat farmers.", taskId: "general-question")
    }
    
    // MARK: - Loading State Helpers
    
    func isLoadingTask(_ taskId: String) -> Bool {
        return loadingTasks.contains(taskId)
    }
    
    func isLoadingGoatProfile(_ goat: Goat) -> Bool {
        return loadingTasks.contains("profile-\(goat.id.uuidString)")
    }
    
    func isLoadingYieldAnalysis(_ goat: Goat) -> Bool {
        return loadingTasks.contains("milk-\(goat.id.uuidString)")
    }
    
    func isLoadingPastureAdvice(_ pasture: Pasture) -> Bool {
        return loadingTasks.contains("pasture-\(pasture.id.uuidString)")
    }
    
    func isLoadingMaintenanceTips(_ equipment: Equipment) -> Bool {
        return loadingTasks.contains("equipment-\(equipment.id.uuidString)")
    }
    
    func isLoadingFeedingPlan(_ goat: Goat) -> Bool {
        return loadingTasks.contains("feeding-\(goat.id.uuidString)")
    }
    
    func isLoadingBreedingTips(_ goat: Goat) -> Bool {
        return loadingTasks.contains("breeding-\(goat.id.uuidString)")
    }
    
    // MARK: - Private API Methods
    
    private func makeAPIRequest(prompt: String, systemMessage: String, taskId: String? = nil) async -> String {
        let taskIdentifier = taskId ?? UUID().uuidString
        
        isLoading = true
        loadingTasks.insert(taskIdentifier)
        errorMessage = ""
        
        defer {
            isLoading = loadingTasks.count > 1
            loadingTasks.remove(taskIdentifier)
        }
        
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid API URL"
            return "Error: Could not connect to AI service"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": systemMessage
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    errorMessage = "API Error: \(httpResponse.statusCode)"
                    return "Sorry, I'm unable to provide advice right now. Please try again later."
                }
            }
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                lastResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return lastResponse
            }
            
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            return "I'm having trouble connecting right now. Here's some general advice: Ensure your goats have access to fresh water, quality hay, and regular health check-ups. Monitor their behavior daily for any changes."
        }
        
        return "Unable to get AI response at this time."
    }
} 