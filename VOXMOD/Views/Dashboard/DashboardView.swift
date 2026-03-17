// DashboardView.swift
// VOXMOD — Behaviour Insight Dashboard

import SwiftUI

struct DashboardView: View {
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: VMSpacing.xl) {
                    // Header
                    dashboardHeader
                    
                    // Stat cards row
                    statCards
                    
                    // Tone trends chart
                    toneTrendsSection
                    
                    // Insights feed
                    insightsSection
                    
                    // Bottom padding for tab bar
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, VMSpacing.xl)
                .padding(.top, VMSpacing.lg)
            }
        }
        .onAppear {
            viewModel.loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Header
    
    private var dashboardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: VMSpacing.xs) {
                HStack(spacing: VMSpacing.sm) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.vmIndigo)
                    
                    Text("VOXMOD")
                        .font(.vmCallout)
                        .foregroundStyle(.white)
                        .tracking(2)
                }
                
                Text("Your Communication Growth")
                    .font(.vmTitle)
                    .foregroundStyle(.white)
                
                Text("Review your weekly progress and patterns.")
                    .font(.vmCallout)
                    .foregroundStyle(Color.vmTextSecondary)
            }
            
            Spacer()
            
            // Notification bell
            Button {} label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.vmTextSecondary)
                    .padding(VMSpacing.md)
                    .glassBackground(cornerRadius: VMRadius.md)
            }
        }
    }
    
    // MARK: - Stat Cards
    
    private var statCards: some View {
        HStack(spacing: VMSpacing.md) {
            // Impulses regulated
            GlassCard {
                VStack(alignment: .leading, spacing: VMSpacing.sm) {
                    Text("RISK INTERVENTIONS")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextSecondary)
                        .tracking(1.0)
                    
                    HStack(alignment: .firstTextBaseline, spacing: VMSpacing.sm) {
                        Text("\(viewModel.insightData?.highRiskInterventions ?? 0)")
                            .font(.vmLargeTitle)
                            .foregroundStyle(.white)
                        
                        Text("Past 7 Days")
                            .font(.vmCaption)
                            .foregroundStyle(Color.vmTextTertiary)
                    }
                }
            }
            .scaleEffect(animateCards ? 1 : 0.9)
            .opacity(animateCards ? 1 : 0)
            
            // Emotional stability
            GlassCard {
                VStack(alignment: .leading, spacing: VMSpacing.sm) {
                    Text("STABILITY SCORE")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextSecondary)
                        .tracking(1.0)
                    
                    HStack(alignment: .firstTextBaseline, spacing: VMSpacing.sm) {
                        Text("\(viewModel.insightData?.emotionalStabilityScore ?? 100)")
                            .font(.vmLargeTitle)
                            .foregroundStyle(.white)
                        
                        Text("/ 100")
                            .font(.vmCaption)
                            .foregroundStyle(Color.vmTextTertiary)
                    }
                }
            }
            .scaleEffect(animateCards ? 1 : 0.9)
            .opacity(animateCards ? 1 : 0)
        }
    }
    
    // MARK: - Tone Trends
    
    private var toneTrendsSection: some View {
        VStack(alignment: .leading, spacing: VMSpacing.lg) {
            // Section header
            HStack {
                Text("Tone Risk Average")
                    .font(.vmTitle2)
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Legend
                HStack(spacing: VMSpacing.lg) {
                    legendDot(color: .vmDanger, label: "RISK")
                }
            }
            
            // Chart
            toneTrendsChart
        }
    }
    
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: VMSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.vmTextSecondary)
                .tracking(0.6)
        }
    }
    
    private var toneTrendsChart: some View {
        GlassCard(padding: VMSpacing.md) {
            VStack(spacing: VMSpacing.sm) {
                // Chart area
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height: CGFloat = 140
                    
                    if let data = viewModel.insightData?.weeklyTrends,
                       !data.isEmpty {
                        ZStack(alignment: .bottom) {
                            // Grid lines
                            VStack(spacing: height / 4) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.04))
                                        .frame(height: 1)
                                }
                            }
                            .frame(height: height)
                            
                            // Risk line (scaled out of 100)
                            chartLine(data: data.map { $0.averageRisk / 100.0 },
                                      width: width, height: height)
                                .trim(from: 0, to: viewModel.chartDrawProgress.last == true ? 1 : 0)
                                .stroke(
                                    LinearGradient(
                                        colors: [.vmCaution, .vmDanger],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                        }
                        .frame(height: height)
                    }
                }
                .frame(height: 140)
                
                // Day labels
                if let data = viewModel.insightData?.weeklyTrends {
                    HStack {
                        ForEach(data) { point in
                            Text(point.day)
                                .font(.vmCaptionSmall)
                                .foregroundStyle(Color.vmTextTertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Chart Helpers
    
    private func chartLine(data: [Double], width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }
        
        let stepX = width / CGFloat(data.count - 1)
        
        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = height * (1 - CGFloat(value))
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(index - 1) * stepX
                let prevY = height * (1 - CGFloat(data[index - 1]))
                let controlX1 = prevX + stepX * 0.4
                let controlX2 = x - stepX * 0.4
                path.addCurve(
                    to: CGPoint(x: x, y: y),
                    control1: CGPoint(x: controlX1, y: prevY),
                    control2: CGPoint(x: controlX2, y: y)
                )
            }
        }
        
        return path
    }
    
    private func chartPath(data: [Double], width: CGFloat, height: CGFloat) -> Path {
        var path = chartLine(data: data, width: width, height: height)
        
        let stepX = width / CGFloat(max(1, data.count - 1))
        
        // Close the path for fill
        path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: VMSpacing.lg) {
            Text("Insights")
                .font(.vmTitle2)
                .foregroundStyle(.white)
            
            if let tips = viewModel.insightData?.actionableTips {
                ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                    insightCard(tip: tip, index: index)
                }
            }
        }
    }
    
    private func insightCard(tip: InsightData.Tip, index: Int) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: VMSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor(for: tip.type).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: tip.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor(for: tip.type))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(tip.description)
                        .font(.vmCallout)
                        .foregroundStyle(Color.vmTextSecondary)
                        .lineSpacing(3)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8)
                .delay(0.1 * Double(index)),
            value: animateCards
        )
    }
    
    private func iconColor(for type: InsightData.Tip.Priority) -> Color {
        switch type {
        case .positive: return .vmCalm
        case .warning:  return .vmCaution
        case .neutral:  return .vmIndigo
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
