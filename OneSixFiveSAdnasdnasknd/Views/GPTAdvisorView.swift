import SwiftUI

struct GPTAdvisorView: View {
    @StateObject private var aiProvider = AIProvider.shared
    @State private var question = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var showingSampleQuestions = true
    
    let sampleQuestions = [
        "How to treat hoof rot naturally?",
        "Best feed supplements for lactating does?",
        "Signs of pregnancy in goats?",
        "How to prevent parasites in goats?",
        "What causes low milk production?",
        "How to handle aggressive goats?",
        "Best breeding age for does?",
        "Natural remedies for goat coughs?"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if chatHistory.isEmpty && showingSampleQuestions {
                                // Welcome message and sample questions
                                VStack(spacing: 20) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 60))
                                            .foregroundColor(.blue)
                                        
                                        Text("GPT Goat Advisor")
                                            .font(.title)
                                            .fontWeight(.bold)
                                        
                                        Text("Ask me anything about goat care, feeding, breeding, health, and farm management. I'm here to help with expert advice!")
                                            .font(.body)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Try asking:")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                            ForEach(sampleQuestions, id: \.self) { sampleQuestion in
                                                Button(sampleQuestion) {
                                                    question = sampleQuestion
                                                    askQuestion()
                                                }
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(16)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(chatHistory) { message in
                                    ChatMessageView(message: message)
                                        .id(message.id)
                                }
                                
                                if aiProvider.isLoading {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Thinking...")
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatHistory.count) {
                        if let lastMessage = chatHistory.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input Area
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Ask about goat care, feeding, breeding...", text: $question, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                        
                        Button("Send") {
                            askQuestion()
                        }
                        .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiProvider.isLoading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiProvider.isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if !chatHistory.isEmpty {
                        HStack {
                            Button("Clear Chat") {
                                chatHistory.removeAll()
                                showingSampleQuestions = true
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Text("Powered by OpenAI GPT")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("GPT Advisor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
    }
    
    private func askQuestion() {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty && !aiProvider.isLoading else { return }
        
        showingSampleQuestions = false
        
        // Add user message
        let userMessage = ChatMessage(
            content: trimmedQuestion,
            isFromUser: true,
            timestamp: Date()
        )
        chatHistory.append(userMessage)
        
        // Clear input
        question = ""
        
        // Get AI response
        Task {
            let response = await aiProvider.answerGeneralQuestion(trimmedQuestion)
            
            let aiMessage = ChatMessage(
                content: response,
                isFromUser: false,
                timestamp: Date()
            )
            
            await MainActor.run {
                chatHistory.append(aiMessage)
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct ChatMessageView: View {
    let message: ChatMessage
    @State private var isExpanded = false
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .cornerRadius(4, corners: .bottomRight)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity * 0.75, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.content)
                                .lineLimit(isExpanded ? nil : 10)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                                .cornerRadius(4, corners: .bottomLeft)
                            
                            if message.content.count > 400 {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isExpanded.toggle()
                                    }
                                }) {
                                    Text(isExpanded ? "Show less" : "Show more")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Spacer()
                            .frame(width: 24) // Align with icon
                        
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity * 0.85, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    GPTAdvisorView()
} 