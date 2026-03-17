// DashboardView.swift
// VOXMOD — Premium Insight Dashboard

import SwiftUI

struct DashboardView: View {
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            // Complex background for premium feel
            Color.vmBackground.ignoresSafeArea()
            
            // Subtle animated ambient glow
            RadialGradient(
                colors: [Color.vmCalm.opacity(0.08), .clear],
                center: .topLeading,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
            .opacity(animateCards ? 1 : 0)
            .animation(.easeOut(duration: 2.0), value: animateCards)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: VMSpacing.xxl) {
                    
                    // Welcome & Hero harmony score
                    heroSection
                    
                    // Metric Cards
                    metricsSection
                    
                    // Tone Trends
                    VStack(alignment: .leading, spacing: VMSpacing.md) {
                        Text("Risk Trajectory")
                            .font(.vmTitle2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, VMSpacing.xl)
                        
                        toneTrendsChart
                            .padding(.horizontal, VMSpacing.xl)
                    }
                    
                    // AI Insights
                    VStack(alignment: .leading, spacing: VMSpacing.md) {
                        Text("AI Insights")
                            .font(.vmTitle2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, VMSpacing.xl)
                        
                        insightsList
                            .padding(.horizontal, VMSpacing.xl)
                    }
                    
                    Spacer(minLength: 120) // Bottom tab bar clearance
                }
                .padding(.top, VMSpacing.xl)
            }
        }
        .onAppear {
            viewModel.loadData()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: VMSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.vmHeadline)
                        .foregroundStyle(Color.vmTextTertiary)
                    
                    Text("Your Vibe is Calm")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                
                Button {} label: {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.vmCalm)
                        .padding(14)
                        .glassBackground(cornerRadius: VMRadius.full)
                }
            }
            .padding(.horizontal, VMSpacing.xl)
            
            // Major visual stability element
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.vmCalm.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(height: 180)
                
                Circle()
                    .stroke(Color.vmCalm.opacity(0.3), lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateCards ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateCards)
                
                VStack(spacing: 2) {
                    Text("\(viewModel.insightData?.emotionalStabilityScore ?? 100)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vmCalm)
                        .contentTransition(.numericText())
                    
                    Text("STABILITY SCORE")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextTertiary)
                        .tracking(1.5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, VMSpacing.sm)
        }
    }
    
    // MARK: - Metrics Cards
    
    private var metricsSection: some View {
        HStack(spacing: VMSpacing.md) {
            // Interventions
            dashboardCard(
                title: "INTERVENTIONS",
                value: "\(viewModel.insightData?.highRiskInterventions ?? 0)",
                icon: "shield.lefthalf.filled",
                color: .vmDanger,
                subtitle: "Prevented"
            )
            
            // Messages Analyzed
            dashboardCard(
                title: "ANALYZED",
                value: "\(viewModel.insightData?.totalMessagesSent ?? 0)",
                icon: "waveform",
                color: .vmIndigo,
                subtitle: "Messages"
            )
        }
        .padding(.horizontal, VMSpacing.xl)
    }
    
    private func dashboardCard(title: String, value: String, icon: String, color: Color, subtitle: String) -> some View {
        GlassCard(padding: VMSpacing.lg) {
            VStack(alignment: .leading, spacing: VMSpacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(color)
                    }
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 4) {
                        Text(subtitle)
                            .font(.vmCaption)
                            .foregroundStyle(color)
                        
                        Text("•")
                            .font(.vmCaptionSmall)
                            .foregroundStyle(Color.vmTextTertiary)
                        
                        Text(title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.vmTextTertiary)
                    }
                }
            }
            .frame(height: 120)
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Tone Trends Chart
    
    private var toneTrendsChart: some View {
        GlassCard(padding: VMSpacing.lg) {
            VStack(spacing: VMSpacing.md) {
                HStack {
                    legendDot(color: .vmDanger, label: "Risk")
                    Spacer()
                    Text("Past 7 Days")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextSecondary)
                }
                
                // Chart area
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height: CGFloat = 120
                    
                    if let data = viewModel.insightData?.weeklyTrends, !data.isEmpty {
                        ZStack(alignment: .bottom) {
                            // Subtle background grid
                            VStack(spacing: height / 3) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.04))
                                        .frame(height: 1)
                                }
                            }
                            .frame(height: height)
                            
                            // Glowing line and area
                            chartArea(data: data.map { $0.averageRisk / 100.0 }, width: width, height: height)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.vmDanger.opacity(0.3), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(viewModel.chartDrawProgress.last == true ? 1 : 0)
                                .animation(.easeIn(duration: 0.5), value: viewModel.chartDrawProgress.last)
                            
                            chartLine(data: data.map { $0.averageRisk / 100.0 }, width: width, height: height)
                                .trim(from: 0, to: viewModel.chartDrawProgress.last == true ? 1 : 0)
                                .stroke(
                                    Color.vmDanger,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                                .shadow(color: Color.vmDanger.opacity(0.5), radius: 5, y: 3)
                        }
                        .frame(height: height)
                    }
                }
                .frame(height: 120)
                
                // Axis labels
                if let data = viewModel.insightData?.weeklyTrends {
                    HStack {
                        ForEach(data) { point in
                            Text(point.day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.vmTextSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 25)
        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: animateCards)
    }
    
    // MARK: - Insights List
    
    private var insightsList: some View {
        VStack(spacing: VMSpacing.sm) {
            if let tips = viewModel.insightData?.actionableTips {
                ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                    GlassCard {
                        HStack(alignment: .top, spacing: VMSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(iconColor(for: tip.type).opacity(0.12))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: tip.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(iconColor(for: tip.type))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title)
                                    .font(.vmHeadline)
                                    .foregroundStyle(.white)
                                
                                Text(tip.description)
                                    .font(.vmCallout)
                                    .foregroundStyle(Color.vmTextSecondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(VMSpacing.md)
                    }
                    .opacity(animateCards ? 1 : 0)
                    .offset(x: animateCards ? 0 : -30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2 + 0.1 * Double(index)), value: animateCards)
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
                path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: controlX1, y: prevY), control2: CGPoint(x: controlX2, y: y))
            }
        }
        return path
    }
    
    private func chartArea(data: [Double], width: CGFloat, height: CGFloat) -> Path {
        var path = chartLine(data: data, width: width, height: height)
        let stepX = width / CGFloat(max(1, data.count - 1))
        
        path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
    
    // MARK: - Mini Helpers
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }
    
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: VMSpacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.vmCaptionSmall).foregroundStyle(Color.vmTextSecondary).tracking(1.0)
        }
    }
    
    private func iconColor(for type: InsightData.Tip.Priority) -> Color {
        switch type {
        case .positive: return .vmCalm
        case .warning:  return .vmDanger
        case .neutral:  return .vmIndigo
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
