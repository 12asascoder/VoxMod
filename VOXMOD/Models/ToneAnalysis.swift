// ToneAnalysis.swift
// VOXMOD

import Foundation

/// Result of AI tone analysis on user text input.
struct ToneAnalysis: Equatable {
    /// Overall risk score from 0 (perfectly calm) to 100 (hostile).
    let riskScore: Double
    
    /// The dominant detected tone.
    let dominantTone: Tone
    
    /// AI-suggested calmer rephrase of the original text.
    let suggestedRephrase: String?
    
    /// Explanation of why the text was analyzed this way (e.g. "Contains hostile keywords...")
    let insightExplanation: String?
    
    /// Breakdown of sentiment percentages.
    let sentimentBreakdown: SentimentBreakdown
    
    /// Risk level derived from the score.
    var riskLevel: RiskLevel {
        switch riskScore {
        case 0..<25:   return .low
        case 25..<50:  return .moderate
        case 50..<75:  return .high
        default:       return .critical
        }
    }
    
    /// Whether the intervention alert should be shown.
    var shouldIntervene: Bool {
        riskScore >= 50
    }
}

// MARK: - Tone

enum Tone: String, CaseIterable {
    case calm       = "Calm"
    case neutral    = "Neutral"
    case assertive  = "Assertive"
    case aggressive = "Aggressive"
    case hostile    = "Hostile"
    
    var emoji: String {
        switch self {
        case .calm:       return "😌"
        case .neutral:    return "😐"
        case .assertive:  return "😤"
        case .aggressive: return "😡"
        case .hostile:    return "🔥"
        }
    }
}

// MARK: - Risk Level

enum RiskLevel: String {
    case low      = "Low Risk"
    case moderate = "Moderate"
    case high     = "High Risk"
    case critical = "Critical"
}

// MARK: - Sentiment Breakdown

struct SentimentBreakdown: Equatable {
    let cooperative: Double   // 0.0 – 1.0
    let defensive: Double
    let neutral: Double
    
    static let balanced = SentimentBreakdown(
        cooperative: 0.6,
        defensive: 0.1,
        neutral: 0.3
    )
}

// MARK: - Tone Minimum Risk

extension Tone {
    /// Minimum risk score that should accompany this tone level.
    /// Used by tone enforcement logic across ViewModels and Services.
    var minimumRisk: Double {
        switch self {
        case .calm:       return 0
        case .neutral:    return 15
        case .assertive:  return 35
        case .aggressive: return 55
        case .hostile:    return 75
        }
    }
}
