import Foundation

class ConversationManager: ObservableObject {
    private let saveKey = "savedConversations"
    @Published private(set) var conversations: [Conversation] = []
    
    init() {
        loadConversations()
    }
    
    func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            self.conversations = decoded
        }
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addConversation() {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        saveConversations()
    }
    
    func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        saveConversations()
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        saveConversations()
    }
    
    func renameConversation(_ conversation: Conversation, newTitle: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var updated = conversation
            updated.title = newTitle
            conversations[index] = updated
            saveConversations()
        }
    }
}
