// Conversation.swift
// VOXMOD — Cross-app conversation models

import Foundation

/// Represents an external messaging app that VOXMOD integrates with.
struct ConnectedApp: Identifiable {
    let id = UUID()
    let name: String
    let icon: String          // SF Symbol
    let accentHex: String     // Hex colour for branding
    let isConnected: Bool
    
    /// A sample subset of well-known messaging apps.
    static let available: [ConnectedApp] = [
        ConnectedApp(name: "Messages",  icon: "message.fill",         accentHex: "#34D399", isConnected: true),
        ConnectedApp(name: "WhatsApp",  icon: "phone.bubble.fill",    accentHex: "#25D366", isConnected: true),
        ConnectedApp(name: "Slack",     icon: "number.square.fill",   accentHex: "#4A154B", isConnected: false),
        ConnectedApp(name: "Telegram",  icon: "paperplane.fill",      accentHex: "#0088CC", isConnected: false),
        ConnectedApp(name: "Instagram", icon: "camera.fill",          accentHex: "#E1306C", isConnected: false)
    ]
}

/// A simulated active conversation being monitored.
struct ActiveConversation: Identifiable {
    let id = UUID()
    let contactName: String
    let contactInitials: String
    let appName: String
    let appIcon: String
    let lastMessage: String
    let lastMessageTime: Date
    var currentTone: Tone
    var riskScore: Double
    var messages: [ChatMessage]
    
    /// Factory for demo data.
    static let samples: [ActiveConversation] = [
        ActiveConversation(
            contactName: "Neha Sharma",
            contactInitials: "NS",
            appName: "WhatsApp",
            appIcon: "phone.bubble.fill",
            lastMessage: "Why didn't you respond to my email? This is unacceptable.",
            lastMessageTime: Date().addingTimeInterval(-120),
            currentTone: .aggressive,
            riskScore: 68,
            messages: [
                ChatMessage(text: "Hey, did you see the project update?", isFromUser: false, timestamp: Date().addingTimeInterval(-3600)),
                ChatMessage(text: "Yeah I saw it, looks good", isFromUser: true, timestamp: Date().addingTimeInterval(-3540)),
                ChatMessage(text: "Can you finish the report by tomorrow?", isFromUser: false, timestamp: Date().addingTimeInterval(-1800)),
                ChatMessage(text: "Why didn't you respond to my email? This is unacceptable.", isFromUser: true, timestamp: Date().addingTimeInterval(-120), toneTag: .aggressive, riskScore: 68)
            ]
        ),
        ActiveConversation(
            contactName: "Arjun Patel",
            contactInitials: "AP",
            appName: "Messages",
            appIcon: "message.fill",
            lastMessage: "Sure, let's meet tomorrow at 3pm.",
            lastMessageTime: Date().addingTimeInterval(-600),
            currentTone: .calm,
            riskScore: 8,
            messages: [
                ChatMessage(text: "Hey! Free for lunch tomorrow?", isFromUser: false, timestamp: Date().addingTimeInterval(-7200)),
                ChatMessage(text: "Sure, let's meet tomorrow at 3pm.", isFromUser: true, timestamp: Date().addingTimeInterval(-600), toneTag: .calm, riskScore: 8)
            ]
        ),
        ActiveConversation(
            contactName: "Team Lead",
            contactInitials: "TL",
            appName: "Slack",
            appIcon: "number.square.fill",
            lastMessage: "This deadline is ridiculous, we need more time",
            lastMessageTime: Date().addingTimeInterval(-300),
            currentTone: .assertive,
            riskScore: 42,
            messages: [
                ChatMessage(text: "Sprint review at 4pm today", isFromUser: false, timestamp: Date().addingTimeInterval(-5400)),
                ChatMessage(text: "Got it, will be there", isFromUser: true, timestamp: Date().addingTimeInterval(-5000)),
                ChatMessage(text: "Also, the client wants the feature by Friday", isFromUser: false, timestamp: Date().addingTimeInterval(-1200)),
                ChatMessage(text: "This deadline is ridiculous, we need more time", isFromUser: true, timestamp: Date().addingTimeInterval(-300), toneTag: .assertive, riskScore: 42)
            ]
        )
    ]
}

/// A single message in a conversation thread.
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    var toneTag: Tone?
    var riskScore: Double?
    
    init(
        text: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        toneTag: Tone? = nil,
        riskScore: Double? = nil
    ) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.toneTag = toneTag
        self.riskScore = riskScore
    }
}
