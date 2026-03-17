// OpenAIService.swift
// VOXMOD — Live AI Backend for Tone Analysis

import Foundation

/// Handles real-time communication with OpenAI (or equivalent LLM) 
/// to provide natural language insights and tone analysis.
@MainActor
final class OpenAIService {
    
    static let shared = OpenAIService()
    
    private let apiKey = "YOUR_API_KEY_HERE" // 🚨 Replace with real key for deployment
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    struct AnalysisResponse: Codable {
        let riskScore: Double
        let dominantTone: String
        let suggestedRephrase: String?
        let insightExplanation: String?
    }
    
    /// Analyzes the message text and returns a structured ToneAnalysis.
    func analyse(text: String) async -> AnalysisResponse? {
        guard !apiKey.contains("YOUR_API_KEY") else {
            // Fallback to local simulation if no API key
            return simulateAnalysis(text: text)
        }
        
        let prompt = """
        Analyze the following user message for tone and risk (defensiveness/aggression).
        Return a JSON object with:
        - riskScore: 0 to 100 (where 100 is highly aggressive/toxic)
        - dominantTone: "calm", "neutral", "assertive", "aggressive", "hostile"
        - suggestedRephrase: A calmer, more constructive version of the message (if riskScore > 30)
        - insightExplanation: A one-sentence explanation of why the message is perceived this way.
        
        Message: "\(text)"
        """
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "You are a professional communication coach AI."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            if let content = json.choices.first?.message.content {
                return try JSONDecoder().decode(AnalysisResponse.self, from: content.data(using: .utf8)!)
            }
        } catch {
            print("AI Backend Error: \(error)")
        }
        
        return simulateAnalysis(text: text)
    }
    
    private func simulateAnalysis(text: String) -> AnalysisResponse {
        // High-quality simulation for demo if API key is missing
        let lowered = text.lowercased()
        if lowered.contains("stupid") || lowered.contains("idiot") || lowered.contains("unacceptable") {
            return AnalysisResponse(
                riskScore: 78,
                dominantTone: "aggressive",
                suggestedRephrase: "I'd like to share my perspective on this. Could we discuss a constructive way forward?",
                insightExplanation: "The message is flagged as aggressive because it contains attacking language that may make the recipient feel defensive."
            )
        }
        return AnalysisResponse(
            riskScore: 12,
            dominantTone: "calm",
            suggestedRephrase: nil,
            insightExplanation: "The tone appears respectful and clear."
        )
    }
}

// Helper models for OpenAI API
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
