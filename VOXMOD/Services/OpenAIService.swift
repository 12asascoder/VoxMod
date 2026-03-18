// OpenAIService.swift
// VOXMOD — AI Backend for Tone Analysis (NVIDIA Qwen 3.5)

import Foundation

/// Handles AI-powered tone analysis by delegating to the NVIDIA Qwen 3.5 backend.
///
/// Previously contained hard-coded keyword lexicons in `simulateAnalysis()`.
/// Now uses genuine AI analysis via `NVIDIAService`, with the on-device
/// `ToxicityLayer` serving as the offline fallback (handled by `ToneAnalysisService`).
@MainActor
final class OpenAIService {

    static let shared = OpenAIService()

    private init() {}

    struct AnalysisResponse: Codable {
        let riskScore: Double
        let dominantTone: String
        let suggestedRephrase: String?
        let insightExplanation: String?
    }

    /// Analyzes the message text using the NVIDIA Qwen 3.5 AI model.
    /// Returns `nil` if the AI backend is unavailable, allowing the caller
    /// to fall back to on-device analysis via `ToxicityLayer`.
    func analyse(text: String) async -> AnalysisResponse? {
        // Delegate to NVIDIA service
        guard let nvidiaResult = await NVIDIAService.shared.analyse(text: text) else {
            return nil  // Caller (ToneAnalysisService) will use on-device fallback
        }

        // Convert NVIDIAService.ToneResult → AnalysisResponse
        return AnalysisResponse(
            riskScore: nvidiaResult.riskScore,
            dominantTone: nvidiaResult.dominantTone,
            suggestedRephrase: nvidiaResult.suggestedRephrase,
            insightExplanation: nvidiaResult.insightExplanation
        )
    }
}
