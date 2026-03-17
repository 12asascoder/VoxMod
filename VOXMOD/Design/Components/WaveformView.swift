// WaveformView.swift
// VOXMOD

import SwiftUI

/// Animated audio-style waveform that visualises typing analysis.
/// Bars animate with different phases to create an organic, living feel.
struct WaveformView: View {
    
    let amplitudes: [CGFloat]   // 0.0 – 1.0 per bar
    let barCount: Int
    let color: Color
    let maxHeight: CGFloat
    
    @State private var isAnimating = false
    
    init(
        amplitudes: [CGFloat] = [],
        barCount: Int = 12,
        color: Color = .vmIndigo,
        maxHeight: CGFloat = 32
    ) {
        self.amplitudes = amplitudes
        self.barCount = barCount
        self.color = color
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let amplitude = index < amplitudes.count
                    ? amplitudes[index]
                    : CGFloat.random(in: 0.1...0.3)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: maxHeight * amplitude)
                    .animation(
                        .spring(
                            response: 0.4,
                            dampingFraction: 0.5
                        )
                        .delay(Double(index) * 0.03),
                        value: amplitude
                    )
            }
        }
        .frame(height: maxHeight)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vmBackground.ignoresSafeArea()
        
        VStack(spacing: 30) {
            WaveformView(
                amplitudes: [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6, 0.3, 0.7, 0.5, 0.8, 0.4],
                color: .vmIndigo
            )
            
            WaveformView(
                amplitudes: Array(repeating: 0.1, count: 12),
                color: .vmTextTertiary
            )
        }
    }
}
