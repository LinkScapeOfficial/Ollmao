import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var selectedConversationId: UUID?
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var currentStreamContent = ""
    @Published var selectedModel = ""
    @Published var availableModels: [String] = []
    @Published var errorMessage: String?
    @Published var showSetup = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    
    private let conversationManager: ConversationManager
    
    var conversations: [Conversation] {
        conversationManager.conversations
    }
    
    var selectedConversation: Conversation? {
        conversations.first { $0.id == selectedConversationId }
    }
    
    var selectedConversationIndex: Int? {
        conversations.firstIndex { $0.id == selectedConversationId }
    }
    
    init(conversationManager: ConversationManager) {
        self.conversationManager = conversationManager
        self.selectedConversationId = conversationManager.conversations.first?.id
        
        if !hasCompletedSetup {
            showSetup = true
        }
        
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
        let conversation = Conversation()
        conversationManager.updateConversation(conversation)
        selectedConversationId = conversation.id
    }
    
    func deleteConversation(_ id: UUID) {
        if let conversation = conversations.first(where: { $0.id == id }) {
            conversationManager.deleteConversation(conversation)
            if selectedConversationId == id {
                selectedConversationId = conversations.first?.id
            }
        }
    }
    
    func sendMessage() async {
        guard let conversationIndex = selectedConversationIndex,
              !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(role: .user, content: inputMessage)
        var updatedConversation = conversations[conversationIndex]
        updatedConversation.messages.append(userMessage)
        conversationManager.updateConversation(updatedConversation)
        
        inputMessage = ""
        isLoading = true
        currentStreamContent = ""
        
        do {
            let stream = try await OllamaService.shared.generateResponse(
                prompt: userMessage.content,
                messages: Array(updatedConversation.messages.dropLast()),
                model: selectedModel
            )
            
            isStreaming = true
            var streamedResponse = ""
            
            for try await text in stream {
                streamedResponse += text
                currentStreamContent = streamedResponse
            }
            
            updatedConversation.messages.append(ChatMessage(role: .assistant, content: streamedResponse))
            conversationManager.updateConversation(updatedConversation)
            
            isStreaming = false
            currentStreamContent = ""
        } catch {
            print("Error: \(error)")
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func completeSetup() {
        hasCompletedSetup = true
        showSetup = false
    }
    
    func showSetupGuide() {
        showSetup = true
    }
    
    func downloadModel(_ modelName: String) async throws {
        do {
            try await OllamaService.shared.pullModel(name: modelName)
            await loadModels()
        } catch {
            errorMessage = "Failed to download model \(modelName): \(error.localizedDescription)"
            throw error
        }
    }
}
