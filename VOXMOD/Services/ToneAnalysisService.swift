// ToneAnalysisService.swift
// VOXMOD — 3-Layer Tone Analysis Engine

import Foundation
import NaturalLanguage

/// On-device tone analysis engine implementing a 3-layer scoring model:
///
/// Layer 1 — Keyword Toxicity Detection (via ToxicityLayer)
/// Layer 2 — Sentiment Polarity (Apple NaturalLanguage)
/// Layer 3 — Conversational Intent (urgency + accusatory classifier)
///
/// Final tone = weighted fusion of all three layers.
/// Calm is gated: it ONLY resolves when all three layers confirm safety.
final class ToneAnalysisService {

    static let shared = ToneAnalysisService()
    private init() {}

    // MARK: - Rephrase Templates

    private let rephraseTemplates: [String: String] = [
        "you always":            "I've noticed a pattern where",
        "you never":             "I'd appreciate it if you could",
        "this is your fault":    "I think we can improve this together",
        "you failed":            "I noticed an update was needed on",
        "that's stupid":         "I see this differently — what if we",
        "you're incompetent":    "I think we could explore a different approach",
        "shut up":               "I need a moment to collect my thoughts",
        "i hate":                "I'm frustrated by",
        "this is ridiculous":    "I find this situation challenging",
        "what's wrong with you": "I'd like to understand your perspective"
    ]

    // MARK: - Public Analysis

    /// Analyse the tone of the given text and return a ToneAnalysis result.
    /// Uses the OpenAI backend when available; otherwise falls back to the
    /// full 3-layer on-device engine.
    func analyse(_ text: String) async -> ToneAnalysis {
        if let aiResult = await OpenAIService.shared.analyse(text: text) {
            // Apply local toxicity override after AI result
            let overriddenTone = applyToxicityOverride(
                text: text,
                aiTone: Tone(rawValue: aiResult.dominantTone.lowercased()) ?? .calm,
                aiRisk: aiResult.riskScore
            )
            let finalRisk = max(aiResult.riskScore, overriddenTone.minimumRisk)
            let result = ToneAnalysis(
                riskScore: finalRisk,
                dominantTone: overriddenTone,
                suggestedRephrase: aiResult.suggestedRephrase,
                insightExplanation: aiResult.insightExplanation,
                sentimentBreakdown: sentimentBreakdown(risk: finalRisk)
            )
            logDebug(text: text, result: result)
            return result
        }

        // Full on-device fallback
        return await analyseOnDevice(text)
    }

    // MARK: - 3-Layer On-Device Engine

    private func analyseOnDevice(_ text: String) async -> ToneAnalysis {
        let toxicity = ToxicityLayer.shared.toxicityScore(for: text)
        let sentiment = ToxicityLayer.shared.sentimentPolarity(for: text)
        let urgency   = ToxicityLayer.shared.urgencyScore(for: text)
        let isAccusatory = ToxicityLayer.shared.isAccusatory(text)

        // Layer 3: intent score (0–1)
        let intentScore: Double = isAccusatory ? 0.85 : (urgency > 0.5 ? 0.6 : urgency)

        // Weighted fusion: toxicity 50%, sentiment 30%, intent 20%
        // Normalise sentiment to 0–100 risk units (negative = high risk)
        let sentimentRisk = max(0, (-sentiment + 0.1) * 80)          // -1 → ~88 risk, 0 → ~8 risk
        let intentRisk    = intentScore * 60

        let fusedRisk = (toxicity * 0.50) + (sentimentRisk * 0.30) + (intentRisk * 0.20)
        let finalRisk = min(100, fusedRisk)

        // Determine tone — calm gate applied
        let tone: Tone
        if ToxicityLayer.shared.calmIsAllowed(toxicity: toxicity,
                                               sentiment: sentiment,
                                               urgency: urgency,
                                               text: text) {
            tone = dominantTone(for: finalRisk)
        } else {
            // Force minimum assertive when calm gate fails
            let rawTone = dominantTone(for: finalRisk)
            tone = rawTone == .calm ? .assertive :
                   rawTone == .neutral ? .assertive : rawTone
        }

        let rephrase = suggestRephrase(for: text)
        let insight  = generateInsight(for: text, tone: tone)

        let result = ToneAnalysis(
            riskScore: finalRisk,
            dominantTone: tone,
            suggestedRephrase: (finalRisk > 30) ? rephrase : nil,
            insightExplanation: insight,
            sentimentBreakdown: sentimentBreakdown(risk: finalRisk)
        )

        logDebug(text: text,
                 toxicity: toxicity,
                 sentiment: sentiment,
                 intentScore: intentScore,
                 result: result)

        return result
    }

    // MARK: - Toxicity Override (post-AI)

    /// When the AI returns Calm but local toxicity rules forbid it, override the tone.
    private func applyToxicityOverride(text: String, aiTone: Tone, aiRisk: Double) -> Tone {
        guard aiTone == .calm || aiTone == .neutral else { return aiTone }

        let toxicity  = ToxicityLayer.shared.toxicityScore(for: text)
        let sentiment = ToxicityLayer.shared.sentimentPolarity(for: text)
        let urgency   = ToxicityLayer.shared.urgencyScore(for: text)

        let calmOk = ToxicityLayer.shared.calmIsAllowed(toxicity: toxicity,
                                                         sentiment: sentiment,
                                                         urgency: urgency,
                                                         text: text)
        if calmOk { return aiTone }

        // Determine override level based on toxicity severity
        if toxicity >= 60 { return .hostile }
        if toxicity >= 35 { return .aggressive }
        return .assertive
    }

    // MARK: - Tone Resolver

    private func dominantTone(for risk: Double) -> Tone {
        switch risk {
        case 0..<15:  return .calm
        case 15..<35: return .neutral
        case 35..<55: return .assertive
        case 55..<75: return .aggressive
        default:      return .hostile
        }
    }

    // MARK: - Rephrase & Insight

    private func suggestRephrase(for text: String) -> String {
        let lowered = text.lowercased()
        var result  = text
        for (trigger, replacement) in rephraseTemplates {
            if lowered.contains(trigger) {
                result = result.replacingOccurrences(of: trigger, with: replacement, options: .caseInsensitive)
            }
        }
        if result == text {
            return "I'd like to share my perspective on this. Could we discuss a constructive way forward?"
        }
        return result
    }

    private func generateInsight(for text: String, tone: Tone) -> String? {
        if tone == .calm || tone == .neutral { return nil }

        var reasons: [String] = []
        if ToxicityLayer.shared.hasProfanity(text) {
            reasons.append("profanity or hostile language")
        }
        if ToxicityLayer.shared.hasSlang(text) {
            reasons.append("aggressive or dismissive wording")
        }
        if ToxicityLayer.shared.isAccusatory(text) {
            reasons.append("accusatory phrasing")
        }

        guard !reasons.isEmpty else {
            return "The overall sentiment suggests tension that may be perceived as \(tone.rawValue.lowercased())."
        }
        return "This message may be perceived as \(tone.rawValue.lowercased()) due to \(reasons.joined(separator: " and "))."
    }

    // MARK: - Sentiment Breakdown

    private func sentimentBreakdown(risk: Double) -> SentimentBreakdown {
        let defensive    = min(1.0, risk / 100)
        let cooperative  = max(0, 1.0 - defensive - 0.15)
        let neutral      = 1.0 - cooperative - defensive
        return SentimentBreakdown(
            cooperative: cooperative,
            defensive: defensive,
            neutral: max(0, neutral)
        )
    }

    // MARK: - Debug Logging

    private func logDebug(text: String,
                          toxicity: Double = -1,
                          sentiment: Double = 0,
                          intentScore: Double = 0,
                          result: ToneAnalysis) {
        let toxStr  = toxicity >= 0 ? String(format: "%.1f", toxicity) : "n/a (AI path)"
        let sentStr = toxicity >= 0 ? String(format: "%.3f", sentiment) : "n/a (AI path)"
        let intStr  = toxicity >= 0 ? String(format: "%.2f", intentScore) : "n/a (AI path)"
        print("""
        [VOXMOD Tone Debug] ─────────────────────────────
          message:    \"\(text.prefix(80))\"
          toxicity:   \(toxStr)
          sentiment:  \(sentStr)
          intent:     \(intStr)
          final tone: \(result.dominantTone.rawValue)
          risk score: \(String(format: "%.1f", result.riskScore))
          confidence: \(String(format: "%.0f%%", min(100, result.riskScore + 10)))
        ─────────────────────────────────────────────────
        """)
    }
}
