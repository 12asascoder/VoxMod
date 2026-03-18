// NVIDIAService.swift
// VOXMOD — NVIDIA Qwen 3.5 AI Backend for Tone Analysis

import Foundation

/// Handles communication with the NVIDIA Qwen 3.5 122B model
/// via the NVIDIA Integrate API for AI-powered tone analysis.
///
/// This replaces the hard-coded keyword/lexicon checks with genuine
/// language-model understanding of tone, risk, and conversational intent.
@MainActor
final class NVIDIAService {

    static let shared = NVIDIAService()

    private let endpoint = "https://integrate.api.nvidia.com/v1/chat/completions"
    private let model    = "qwen/qwen3.5-122b-a10b"

    // Read from UserDefaults (set via Settings), or fall back to compile-time constant.
    private var apiKey: String {
        let sharedDefaults = UserDefaults(suiteName: "group.com.spazorlabs.VOXMOD") ?? .standard
        let stored = sharedDefaults.string(forKey: "nvidiaAPIKey") ?? ""
        return stored.isEmpty ? NVIDIAService.defaultAPIKey : stored
    }

    // 🚨 Replace with your real NVIDIA API key for development/deployment
    private static let defaultAPIKey = "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"

    private init() {}

    // MARK: - Response Model

    struct ToneResult: Codable {
        let riskScore: Double
        let dominantTone: String
        let suggestedRephrase: String?
        let insightExplanation: String?
    }

    // MARK: - Public API

    /// Analyse the given text using the NVIDIA Qwen 3.5 model.
    /// Returns `nil` if the API is unreachable or the key is missing,
    /// allowing the caller to fall back to on-device analysis.
    func analyse(text: String) async -> ToneResult? {
        guard !apiKey.contains("NVIDIA_API_KEY_HERE"),
              !apiKey.isEmpty else {
            print("[VOXMOD] NVIDIA API key not configured — skipping AI analysis.")
            return nil
        }

        let systemPrompt = """
        You are a professional communication coach AI embedded in a messaging app.
        Analyze the user's message for emotional tone and communication risk.

        Return ONLY a valid JSON object with these exact fields:
        {
          "riskScore": <number 0-100, where 0 is perfectly calm and 100 is extremely hostile>,
          "dominantTone": "<one of: calm, neutral, assertive, aggressive, hostile>",
          "suggestedRephrase": "<a calmer, more constructive version if riskScore > 30, otherwise null>",
          "insightExplanation": "<one sentence explaining why the text was scored this way>"
        }

        CRITICAL RULES:
        - If the message contains profanity, slurs, insults, or severe hostility, the dominantTone MUST be "aggressive" or "hostile" and riskScore MUST be >= 55.
        - If the message contains accusatory phrasing (e.g. "you always", "you never", "this is your fault"), dominantTone MUST be at least "assertive" with riskScore >= 35.
        - If the message contains urgent/pressuring language, dominantTone should be at least "assertive".
        - Only return "calm" if the message is genuinely respectful, clear, and non-confrontational.
        - The suggestedRephrase should preserve the original intent but use empathetic, non-violent communication style.
        - Return ONLY the JSON object. No markdown, no code fences, no additional text.
        """

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Analyze this message: \"\(text)\""]
            ],
            "max_tokens": 512,
            "temperature": 0.20,
            "top_p": 0.95,
            "stream": false
            // enable_thinking: true disabled for stability and speed
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30s is plenty without thinking enabled

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, httpResponse) = try await URLSession.shared.data(for: request)

            if let http = httpResponse as? HTTPURLResponse, http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "no body"
                print("[VOXMOD] NVIDIA API HTTP \(http.statusCode): \(body.prefix(300))")
                return nil
            }

            do {
                let apiResponse = try JSONDecoder().decode(NVIDIAChatResponse.self, from: data)
                
                guard let content = apiResponse.choices.first?.message.content else {
                    print("[VOXMOD] NVIDIA API returned no content.")
                    return nil
                }

                let cleanJSON = extractJSON(from: content)
                guard let jsonData = cleanJSON.data(using: .utf8) else { return nil }
                
                let result = try JSONDecoder().decode(ToneResult.self, from: jsonData)
                print("[VOXMOD] ✅ NVIDIA AI: \(result.dominantTone) (Risk: \(result.riskScore))")
                return result
            } catch {
                let rawBody = String(data: data, encoding: .utf8) ?? "Unreadable data"
                print("[VOXMOD] NVIDIA Decoding Error: \(error)")
                print("[VOXMOD] Raw Response Body: \(rawBody.prefix(800))")
                return nil
            }
        } catch {
            print("[VOXMOD] NVIDIA Network Error: \(error)")
            return nil
        }
    }

    // MARK: - JSON Extraction

    /// Extracts the JSON object from model output that might contain:
    /// - Thinking tags: <think>...</think>
    /// - Markdown fences: ```json ... ```
    /// - Raw JSON
    private func extractJSON(from raw: String) -> String {
        var text = raw

        // Remove <think>...</think> blocks (Qwen thinking output)
        if let thinkRange = text.range(of: "<think>"),
           let endThink = text.range(of: "</think>") {
            text = String(text[endThink.upperBound...])
        }

        // Remove markdown code fences
        text = text.replacingOccurrences(of: "```json", with: "")
        text = text.replacingOccurrences(of: "```", with: "")

        // Find the JSON object boundaries
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            text = String(text[start...end])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - NVIDIA API Response Models (OpenAI-compatible format)

struct NVIDIAChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String?
            let content: String?
        }
        let message: Message
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    let id: String?
    let choices: [Choice]
    let usage: Usage?

    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
