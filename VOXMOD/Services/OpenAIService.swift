// OpenAIService.swift
// VOXMOD — Live AI Backend for Tone Analysis

import Foundation

/// Handles real-time communication with OpenAI (or equivalent LLM)
/// to provide natural language insights and tone analysis.
@MainActor
final class OpenAIService {

    static let shared = OpenAIService()

    private let apiKey  = "YOUR_API_KEY_HERE" // 🚨 Replace with real key for deployment
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    private init() {}

    struct AnalysisResponse: Codable {
        let riskScore: Double
        let dominantTone: String
        let suggestedRephrase: String?
        let insightExplanation: String?
    }

    /// Analyzes the message text and returns a structured AnalysisResponse.
    func analyse(text: String) async -> AnalysisResponse? {
        guard !apiKey.contains("YOUR_API_KEY") else {
            // No API key — use full on-device simulation
            return simulateAnalysis(text: text)
        }

        let prompt = """
        Analyze the following user message for tone and risk (defensiveness/aggression).
        Return a JSON object with:
        - riskScore: 0 to 100 (where 100 is highly aggressive/toxic)
        - dominantTone: "calm", "neutral", "assertive", "aggressive", "hostile"
        - suggestedRephrase: A calmer, more constructive version (if riskScore > 30)
        - insightExplanation: A one-sentence explanation.

        IMPORTANT: If the message contains profanity, insults, or accusatory phrasing,
        the dominantTone must be "assertive", "aggressive", or "hostile" — NEVER "calm".

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
            print("[VOXMOD] AI Backend Error: \(error)")
        }

        return simulateAnalysis(text: text)
    }

    // MARK: - On-Device Simulation (Full Lexicon)

    private func simulateAnalysis(text: String) -> AnalysisResponse {
        let lowered = text.lowercased()
        let words   = Set(lowered.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })

        // --- Profanity check (highest priority) ---
        let hardProfanity: Set<String> = [
            "motherfucker", "motherfuckers", "mf", "fucker", "fuck", "fucking", "fucked",
            "shit", "bullshit", "asshole", "bitch", "bastard", "cunt", "dick", "dickhead",
            "wtf", "wth", "idiot", "moron", "imbecile", "retard", "dumbass"
        ]
        let hardPhrases = ["piece of shit", "go to hell", "damn you", "screw you", "piss off",
                           "what the hell", "what the fuck", "piece of idiot", "shut up"]

        let hasProfanity = hardProfanity.contains { words.contains($0) }
                        || hardPhrases.contains { lowered.contains($0) }

        if hasProfanity {
            let riskScore: Double = lowered.contains("motherfucker") || lowered.contains("piece of shit") ? 88 : 72
            return AnalysisResponse(
                riskScore: riskScore,
                dominantTone: riskScore >= 80 ? "hostile" : "aggressive",
                suggestedRephrase: "I'd like to share my concerns in a more constructive way. Could we discuss this calmly?",
                insightExplanation: "The message contains profanity or severe insults that would be perceived as hostile."
            )
        }

        // --- Slang / strong-negative check ---
        let slangWords: Set<String> = [
            "stupid", "dumb", "pathetic", "useless", "worthless", "disgusting",
            "terrible", "horrible", "trash", "garbage", "ridiculous", "absurd",
            "nonsense", "unacceptable", "loser", "idiot"
        ]
        let slangPhrases = ["shut it", "back off", "get lost", "are you serious",
                            "hate you", "such a joke", "this is ridiculous", "piece of crap"]

        let hasSlang = slangWords.contains { words.contains($0) }
                    || slangPhrases.contains { lowered.contains($0) }

        if hasSlang {
            return AnalysisResponse(
                riskScore: 62,
                dominantTone: "aggressive",
                suggestedRephrase: "I find this situation frustrating. Could we look at this differently?",
                insightExplanation: "The message contains aggressive or dismissive language that may put the recipient on the defensive."
            )
        }

        // --- Accusatory phrasing ---
        let accusatoryPhrases = ["why didn't you", "you never", "you always", "this is your fault",
                                 "you failed", "because of you", "what's wrong with you", "how could you"]
        let isAccusatory = accusatoryPhrases.contains { lowered.contains($0) }

        if isAccusatory {
            return AnalysisResponse(
                riskScore: 48,
                dominantTone: "assertive",
                suggestedRephrase: "I've been struggling with this. Could we find a way forward together?",
                insightExplanation: "The message contains accusatory phrasing that may feel confrontational to the recipient."
            )
        }

        // --- Urgency / frustration check ---
        let urgencyWords: Set<String> = [
            "immediately", "asap", "urgent", "deadline", "overdue", "waiting", "hurry"
        ]
        let urgencyPhrases = ["right now", "as soon as possible", "still waiting", "how long does it"]

        let hasUrgency = urgencyWords.contains { words.contains($0) }
                      || urgencyPhrases.contains { lowered.contains($0) }

        if hasUrgency {
            return AnalysisResponse(
                riskScore: 34,
                dominantTone: "assertive",
                suggestedRephrase: nil,
                insightExplanation: "The message expresses urgency which could create undue pressure on the recipient."
            )
        }

        // --- Default: calm / neutral ---
        return AnalysisResponse(
            riskScore: 10,
            dominantTone: "calm",
            suggestedRephrase: nil,
            insightExplanation: "The tone appears respectful and clear."
        )
    }
}

// MARK: - Helper Models

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
