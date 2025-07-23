import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HerdOverviewView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Herd")
                }
            
            FeedingNutritionView()
                .tabItem {
                    Image(systemName: "leaf")
                    Text("Feeding")
                }
            
            BreedingTrackerView()
                .tabItem {
                    Image(systemName: "heart.circle")
                    Text("Breeding")
                }
            
            GPTAdvisorView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Advisor")
                }
            
            MilkYieldLogView()
                .tabItem {
                    Image(systemName: "drop.circle")
                    Text("Milk")
                }
            
            PastureRotationView()
                .tabItem {
                    Image(systemName: "leaf.circle")
                    Text("Pasture")
                }
            
            EquipmentInventoryView()
                .tabItem {
                    Image(systemName: "wrench")
                    Text("Equipment")
                }
        }
        .accentColor(.brown)
    }
}

#Preview {
    MainTabView()
} 