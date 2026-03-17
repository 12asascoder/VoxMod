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
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        let lowered = text.lowercased()
        
        // 1. Apple NaturalLanguage sentiment (-1.0 to 1.0)
        let sentiment = sentimentScore(for: text)
        
        // 2. Keyword-based risk scoring
        let keywordRisk = keywordRiskScore(for: lowered)
        
        // 3. Combine scores (weighted blend)
        let sentimentRisk = max(0, (1.0 - sentiment) * 50) // sentiment -1→100, 1→0
        let combinedRisk = min(100, (sentimentRisk * 0.4) + (keywordRisk * 0.6))
        
        // 4. Determine dominant tone
        let tone = dominantTone(for: combinedRisk)
        
        // 5. Generate rephrase suggestion if risky
        let rephrase = combinedRisk >= 40 ? suggestRephrase(for: text) : nil
        
        // 6. Sentiment breakdown
        let breakdown = sentimentBreakdown(risk: combinedRisk)
        
        // Log event silently to Storage if it crossed a notable threshold
        // (Keyboard extension will fire this on continuous analysis)
        if combinedRisk >= 50 {
            // We assume false for `wasRegulated` initially. It can be updated by UI later if needed.
            StorageService.shared.logEvent(riskScore: combinedRisk, tone: tone, wasRegulated: false)
        }
        
        return ToneAnalysis(
            riskScore: combinedRisk,
            dominantTone: tone,
            suggestedRephrase: rephrase,
            sentimentBreakdown: breakdown
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
