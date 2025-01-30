import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
}
