import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversationId: UUID?
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var selectedModel = "deepseek-r1:8b"
    @Published var availableModels: [String] = []
    @Published var errorMessage: String?
    
    var selectedConversation: Conversation? {
        conversations.first { $0.id == selectedConversationId }
    }
    
    var selectedConversationIndex: Int? {
        conversations.firstIndex { $0.id == selectedConversationId }
    }
    
    init() {
        Task {
            await loadModels()
        }
    }
    
    private func loadModels() async {
        do {
            availableModels = try await OllamaService.shared.listModels()
            print("Loaded models: \(availableModels)")
            if availableModels.isEmpty {
                availableModels = ["deepseek-r1:8b"]
            }
        } catch {
            print("Error loading models: \(error)")
            availableModels = ["deepseek-r1:8b"]
        }
    }
    
    func newConversation() {
        let conversation = Conversation(model: selectedModel)
        conversations.insert(conversation, at: 0)
        selectedConversationId = conversation.id
    }
    
    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if selectedConversationId == id {
            selectedConversationId = conversations.first?.id
        }
    }
    
    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let conversationIndex = conversations.firstIndex(where: { $0.id == selectedConversationId }) else {
            newConversation()
            return
        }
        
        let userMessage = ChatMessage(role: .user, content: inputMessage)
        let prompt = inputMessage
        inputMessage = ""
        isLoading = true
        errorMessage = nil
        
        conversations[conversationIndex].messages.append(userMessage)
        
        do {
            let assistantMessage = ChatMessage(role: .assistant, content: "")
            conversations[conversationIndex].messages.append(assistantMessage)
            let assistantIndex = conversations[conversationIndex].messages.count - 1
            
            print("Sending message: \(prompt)")
            let stream = try await OllamaService.shared.generateResponse(
                prompt: prompt,
                messages: Array(conversations[conversationIndex].messages.dropLast()),
                model: conversations[conversationIndex].model
            )
            
            print("Starting to receive response...")
            for try await text in stream {
                print("Received chunk: \(text)")
                conversations[conversationIndex].messages[assistantIndex].content += text
            }
            print("Finished receiving response")
            
            // If we got no response, show an error
            if conversations[conversationIndex].messages[assistantIndex].content.isEmpty {
                conversations[conversationIndex].messages.removeLast()
                errorMessage = "No response received from the model"
            }
            
        } catch {
            print("Error generating response: \(error)")
            // Remove the empty assistant message if it exists
            if conversations[conversationIndex].messages.last?.role == .assistant {
                conversations[conversationIndex].messages.removeLast()
            }
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
