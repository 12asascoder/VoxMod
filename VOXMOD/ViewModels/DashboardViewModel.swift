// DashboardViewModel.swift
// VOXMOD

import SwiftUI

/// Drives the Behaviour Insight Dashboard with mock analytics data.
@MainActor
final class DashboardViewModel: ObservableObject {
    
    @Published var insightData: InsightData?
    @Published var isLoading: Bool = false
    @Published var animateCharts: Bool = false
    
    private let service = InsightService.shared
    @Published var chartDrawProgress: [Bool] = []
    
    private let insightService = InsightService.shared
    
    func loadData() {
        isLoading = true
        
        Task {
            do {
                let data = try await insightService.fetchDashboardInsights()
                
                await MainActor.run {
                    self.insightData = data
                    self.isLoading = false
                    self.chartDrawProgress = Array(repeating: false, count: data.weeklyTrends.count)
                    self.triggerAnimations()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func triggerAnimations() {
        Task {
            for i in 0..<(insightData?.weeklyTrends.count ?? 0) {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        self.chartDrawProgress[i] = true
                    }
                }
            }
        }
    }
}
