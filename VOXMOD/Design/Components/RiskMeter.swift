// RiskMeter.swift
// VOXMOD

import SwiftUI

/// Semi-circular gauge that displays the current risk score (0–100)
/// with a gradient fill from green (calm) to red (hostile)
/// and an animated needle.
struct RiskMeter: View {
    
    let score: Double
    let size: CGFloat
    
    init(score: Double, size: CGFloat = 160) {
        self.score = score
        self.size = size
    }
    
    private var normalised: Double {
        min(1.0, max(0, score / 100))
    }
    
    private var needleAngle: Angle {
        // Map 0–1 to -90°...+90° (180° arc)
        .degrees(-90 + (normalised * 180))
    }
    
    var body: some View {
        ZStack {
            // Background arc
            arcShape
                .stroke(Color.vmSurface, style: StrokeStyle(lineWidth: 12, lineCap: .round))
            
            // Gradient fill arc
            arcShape
                .trim(from: 0, to: normalised)
                .stroke(
                    AngularGradient(
                        colors: [.vmCalm, .vmCaution, .vmWarning, .vmDanger],
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
            
            // Needle
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2.5, height: size * 0.28)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
            }
            .rotationEffect(needleAngle, anchor: .bottom)
            .offset(y: -size * 0.06)
            
            // Score label
            VStack(spacing: 2) {
                Text("\(Int(score))")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("/100")
                    .font(.vmCaption)
                    .foregroundStyle(Color.vmTextSecondary)
            }
            .offset(y: size * 0.15)
        }
        .frame(width: size, height: size * 0.6)
        .animation(.spring(response: 0.7, dampingFraction: 0.65), value: score)
    }
    
    private var arcShape: some Shape {
        Arc()
    }
}

// MARK: - Arc Shape

private struct Arc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY * 0.85),
            radius: min(rect.width, rect.height * 1.6) * 0.45,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vmBackground.ignoresSafeArea()
        
        VStack(spacing: 30) {
            RiskMeter(score: 25)
            RiskMeter(score: 74)
        }
    }
}
