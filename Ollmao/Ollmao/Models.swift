import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    var id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum MessageRole: String, Codable, Equatable {
    case user
    case assistant
    case system
}

struct Conversation: Identifiable {
    var id: UUID
    var title: String
    var messages: [ChatMessage]
    let model: String
    let timestamp: Date
    
    init(id: UUID = UUID(), title: String = "New Chat", messages: [ChatMessage] = [], model: String, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.model = model
        self.timestamp = timestamp
    }
}
