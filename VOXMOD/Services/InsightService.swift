// InsightService.swift
// VOXMOD

import Foundation

/// Provides mock analytics data for the Behaviour Insight Dashboard.
final class InsightService {
    
    static let shared = InsightService()
    private init() {}
    
    /// Load weekly insight data. In production this would query a local
    /// CoreData/SwiftData store of historical tone analyses.
    func fetchDashboardInsights() async throws -> InsightData {
        // Give UI a chance to render skeleton/glass
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Fetch all generic events from shared storage
        let allEvents = StorageService.shared.getAllEvents()
        
        let totalSent = allEvents.count
        
        // Filter events considered high-risk
        let riskyEvents = allEvents.filter { $0.riskScore >= 50 }
        let highRiskCount = riskyEvents.count
        
        // Calculate the percentage of risky events that were "regulated" (rephrased/paused)
        let regulatedCount = riskyEvents.filter { $0.wasRegulated }.count
        let stabilityScore = highRiskCount == 0 ? 100 : Int((Double(regulatedCount) / Double(highRiskCount)) * 100)
        
        // Aggregate daily trends (last 7 days max for standard view)
        var trends: [InsightData.DailyTrend] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayName = i == 0 ? "Today" : Formatter.shortDay.string(from: date)
            
            // Average risk for this specific day
            let dayEvents = allEvents.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            
            let avgScore = dayEvents.isEmpty ? 0 : dayEvents.reduce(0.0) { $0 + $1.riskScore } / Double(dayEvents.count)
            trends.append(InsightData.DailyTrend(day: dayName, averageRisk: avgScore))
        }
        
        // Ensure we always have 7 days of data for the chart layout
        if trends.isEmpty {
            trends = (0..<7).map { i in
                InsightData.DailyTrend(day: "Day \(i)", averageRisk: 0)
            }
        }
        
        // Build dynamic tips
        var tips: [InsightData.Tip] = []
        if highRiskCount > 0 && regulatedCount > 0 {
            tips.append(InsightData.Tip(title: "Great Restraint", description: "You paused before sending \(regulatedCount) risky messages this week.", icon: "shield.fill", type: .positive))
        } else if highRiskCount > 0 {
             tips.append(InsightData.Tip(title: "Impulse Alert", description: "You've had \(highRiskCount) high-risk typing moments. Remember to pause.", icon: "exclamationmark.triangle.fill", type: .warning))
        } else {
             tips.append(InsightData.Tip(title: "Perfect Flow", description: "Your communication has been completely calm.", icon: "leaf.fill", type: .positive))
        }
        
        return InsightData(
            totalMessagesSent: totalSent,
            highRiskInterventions: highRiskCount,
            emotionalStabilityScore: stabilityScore,
            weeklyTrends: trends,
            actionableTips: tips
        )
    }
}

fileprivate extension Formatter {
    static let shortDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}
