// PulseAnimation.swift
// VOXMOD

import SwiftUI

/// Breathing pulse animation with concentric rings.
/// Intensity and color adapt to the current risk level.
/// Used behind the risk meter and on the intervention alert.
struct PulseAnimation: View {
    
    let riskScore: Double
    let size: CGFloat
    
    @State private var isAnimating = false
    
    private var riskColor: Color {
        Color.riskColor(for: riskScore)
    }
    
    private var pulseSpeed: Double {
        switch riskScore {
        case 0..<25:   return 2.0    // Slow, calm breathing
        case 25..<50:  return 1.5
        case 50..<75:  return 1.0    // Faster pulse
        default:       return 0.6    // Rapid alert pulse
        }
    }
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(riskColor.opacity(0.15), lineWidth: 2)
                .frame(width: size * 1.6, height: size * 1.6)
                .scaleEffect(isAnimating ? 1.2 : 0.9)
                .opacity(isAnimating ? 0 : 0.6)
            
            // Middle ring
            Circle()
                .stroke(riskColor.opacity(0.25), lineWidth: 2)
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(isAnimating ? 1.15 : 0.95)
                .opacity(isAnimating ? 0.1 : 0.7)
            
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [riskColor.opacity(0.3), riskColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: pulseSpeed)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
        .onChange(of: riskScore) { _, _ in
            // Reset animation with new speed
            isAnimating = false
            withAnimation(
                .easeInOut(duration: pulseSpeed)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vmBackground.ignoresSafeArea()
        
        VStack(spacing: 40) {
            PulseAnimation(riskScore: 20, size: 60)
            PulseAnimation(riskScore: 55, size: 60)
            PulseAnimation(riskScore: 85, size: 60)
        }
    }
}
