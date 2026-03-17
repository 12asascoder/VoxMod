// GlassCard.swift
// VOXMOD

import SwiftUI

/// A glassmorphism card with ultra-thin material backdrop,
/// subtle border, and soft shadow. Used throughout the app
/// for stat cards, insight tiles, and content containers.
struct GlassCard<Content: View>: View {
    
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        cornerRadius: CGFloat = VMRadius.lg,
        padding: CGFloat = VMSpacing.lg,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.vmCardBackground.opacity(0.6))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vmBackground.ignoresSafeArea()
        
        GlassCard {
            VStack(alignment: .leading, spacing: VMSpacing.sm) {
                Text("IMPULSES REGULATED")
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextSecondary)
                    .tracking(1.2)
                
                HStack(alignment: .firstTextBaseline, spacing: VMSpacing.sm) {
                    Text("14")
                        .font(.vmLargeTitle)
                        .foregroundStyle(.white)
                    
                    Text("~20%")
                        .font(.vmCaption)
                        .foregroundStyle(Color.vmCalm)
                }
            }
        }
        .padding()
    }
}
