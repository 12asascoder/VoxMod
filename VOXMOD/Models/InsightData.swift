// InsightData.swift
// VOXMOD

import Foundation

/// Aggregated insight data powering the Behaviour Dashboard.
struct InsightData {
    let totalMessagesSent: Int
    let highRiskInterventions: Int
    let emotionalStabilityScore: Int
    let weeklyTrends: [DailyTrend]
    let actionableTips: [Tip]
    
    struct DailyTrend: Identifiable {
        let id = UUID()
        let day: String
        let averageRisk: Double
    }
    
    struct Tip: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String // SF Symbol
        let type: Priority
        
        enum Priority {
            case positive, warning, neutral
        }
    }
}
