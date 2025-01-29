import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversationId: UUID?
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var currentStreamContent = ""
    @Published var selectedModel = ""
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
            if !availableModels.isEmpty {
                selectedModel = availableModels[0]
            }
        } catch {
            print("Error loading models: \(error)")
            errorMessage = "Failed to load models: \(error.localizedDescription)"
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
        guard let conversationIndex = selectedConversationIndex,
              !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(role: .user, content: inputMessage)
        conversations[conversationIndex].messages.append(userMessage)
        inputMessage = ""
        isLoading = true
        currentStreamContent = ""
        
        do {
            var streamedResponse = ""
            let stream = try await OllamaService.shared.generateResponse(
                prompt: userMessage.content,
                messages: Array(conversations[conversationIndex].messages.dropLast()),
                model: selectedModel
            )
            
            isStreaming = true
            for try await chunk in stream {
                streamedResponse += chunk
                currentStreamContent = streamedResponse
            }
            
            let assistantMessage = ChatMessage(role: .assistant, content: streamedResponse)
            conversations[conversationIndex].messages.append(assistantMessage)
            isStreaming = false
            currentStreamContent = ""
        } catch {
            print("Error sending message: \(error)")
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
