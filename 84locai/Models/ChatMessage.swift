import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: String // "user" | "assistant" | "system"
    var content: String
    var createdAt: Date
    var isStreaming: Bool

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
        self.isStreaming = false
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}
