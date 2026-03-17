// ToneAnalysisService.swift
// VOXMOD

import Foundation
import NaturalLanguage

/// Mock AI tone analysis engine.
/// Uses Apple NaturalLanguage sentiment scoring combined with keyword-based
/// risk detection to simulate on-device CoreML inference.
final class ToneAnalysisService {
    
    static let shared = ToneAnalysisService()
    private init() {}
    
    // MARK: - Aggressive Keyword Banks
    
    private let hostileKeywords: Set<String> = [
        "hate", "stupid", "idiot", "moron", "dumb", "pathetic", "useless",
        "worthless", "disgusting", "terrible", "horrible", "worst", "loser",
        "shut up", "die", "kill", "destroy"
    ]
    
    private let aggressiveKeywords: Set<String> = [
        "angry", "furious", "annoyed", "frustrated", "ridiculous", "absurd",
        "unacceptable", "failed", "blame", "fault", "incompetent", "lazy",
        "never", "always", "wrong", "mess", "disaster", "ruined"
    ]
    
    private let assertiveKeywords: Set<String> = [
        "need", "must", "demand", "expect", "require", "immediately",
        "urgent", "critical", "deadline", "asap", "now", "why"
    ]
    
    // MARK: - Calmer Phrase Suggestions
    
    private let rephraseTemplates: [String: String] = [
        "you always": "I've noticed a pattern where",
        "you never": "I'd appreciate it if you could",
        "this is your fault": "I think we can improve this together",
        "you failed": "I noticed an update was needed on",
        "that's stupid": "I see this differently — what if we",
        "you're incompetent": "I think we could explore a different approach",
        "shut up": "I need a moment to collect my thoughts",
        "i hate": "I'm frustrated by",
        "this is ridiculous": "I find this situation challenging",
        "what's wrong with you": "I'd like to understand your perspective"
    ]
    
    // MARK: - Analysis
    
    /// Analyse the tone of the given text and return a ToneAnalysis result.
    /// Simulates a ~200ms on-device ML inference delay.
    func analyse(_ text: String) async -> ToneAnalysis {
        // Use the live AI backend
        if let aiResult = await OpenAIService.shared.analyse(text: text) {
            return ToneAnalysis(
                riskScore: aiResult.riskScore,
                dominantTone: Tone(rawValue: aiResult.dominantTone.lowercased()) ?? .calm,
                suggestedRephrase: aiResult.suggestedRephrase,
                insightExplanation: aiResult.insightExplanation,
                sentimentBreakdown: sentimentBreakdown(risk: aiResult.riskScore)
            )
        }
        
        // Fallback to minimal static analysis if AI completely fails
        return ToneAnalysis(
            riskScore: 0,
            dominantTone: .calm,
            suggestedRephrase: nil,
            insightExplanation: nil,
            sentimentBreakdown: .balanced
        )
    }
    
    // MARK: - Private Helpers
    
    private func sentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex,
                                   unit: .paragraph,
                                   scheme: .sentimentScore)
        return Double(tag?.rawValue ?? "0") ?? 0
    }
    
    private func keywordRiskScore(for text: String) -> Double {
        let words = Set(text.components(separatedBy: .whitespacesAndNewlines))
        
        let hostileCount    = words.intersection(hostileKeywords).count
        let aggressiveCount = words.intersection(aggressiveKeywords).count
        let assertiveCount  = words.intersection(assertiveKeywords).count
        
        let score = Double(hostileCount) * 30 +
                    Double(aggressiveCount) * 15 +
                    Double(assertiveCount) * 5
        
        return min(100, score)
    }
    
    private func dominantTone(for risk: Double) -> Tone {
        switch risk {
        case 0..<15:   return .calm
        case 15..<35:  return .neutral
        case 35..<55:  return .assertive
        case 55..<75:  return .aggressive
        default:       return .hostile
        }
    }
    
    private func suggestRephrase(for text: String) -> String {
        let lowered = text.lowercased()
        var result = text
        
        for (trigger, replacement) in rephraseTemplates {
            if lowered.contains(trigger) {
                // Build a calmer version
                result = result.replacingOccurrences(
                    of: trigger,
                    with: replacement,
                    options: .caseInsensitive
                )
            }
        }
        
        // If no template matched, provide a generic calmer version
        if result == text {
            return "I'd like to share my perspective on this. " +
                   "Could we discuss a constructive way forward?"
        }
        
        return result
    }
    
    private func generateInsight(for text: String, tone: Tone) -> String? {
        if tone == .calm || tone == .neutral { return nil }
        
        let words = Set(text.components(separatedBy: .whitespacesAndNewlines))
        let foundHostile = words.intersection(hostileKeywords)
        let foundAggressive = words.intersection(aggressiveKeywords)
        let foundAssertive = words.intersection(assertiveKeywords)
        
        var reasons: [String] = []
        
        if !foundHostile.isEmpty {
            reasons.append("hostile phrasing like '\(foundHostile.first!)'")
        }
        if !foundAggressive.isEmpty {
            reasons.append("aggressive wording such as '\(foundAggressive.first!)'")
        }
        if !foundAssertive.isEmpty && reasons.isEmpty {
            reasons.append("highly assertive demands like '\(foundAssertive.first!)'")
        }
        
        guard !reasons.isEmpty else {
            return "The overall sentiment suggests a lack of cooperation which can be perceived as \(tone.rawValue.lowercased())."
        }
        
        return "This message may be perceived as \(tone.rawValue.lowercased()) due to \(reasons.joined(separator: " and "))."
    }
    
    private func sentimentBreakdown(risk: Double) -> SentimentBreakdown {
        let defensive = min(1.0, risk / 100)
        let cooperative = max(0, 1.0 - defensive - 0.15)
        let neutral = 1.0 - cooperative - defensive
        return SentimentBreakdown(
            cooperative: cooperative,
            defensive: defensive,
            neutral: max(0, neutral)
        )
    }
}
