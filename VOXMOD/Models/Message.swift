// Message.swift
// VOXMOD

import Foundation

/// Represents a single message in the composer or conversation history.
struct Message: Identifiable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    let isFromUser: Bool
    var toneAnalysis: ToneAnalysis?
    
    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        isFromUser: Bool = true,
        toneAnalysis: ToneAnalysis? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.toneAnalysis = toneAnalysis
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
