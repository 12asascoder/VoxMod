// GlowButton.swift
// VOXMOD

import SwiftUI

/// A call-to-action button with a subtle animated outer glow.
/// Used for primary actions throughout the app.
struct GlowButton: View {
    
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isGlowing = false
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        color: Color = .vmIndigo,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticService.shared.tap()
            action()
        }) {
            HStack(spacing: VMSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.vmHeadline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VMSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: VMRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: VMRadius.xl)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(isGlowing ? 0.5 : 0.2),
                    radius: isGlowing ? 16 : 8,
                    x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isGlowing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vmBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlowButton(title: "Start Communicating Smarter", icon: "arrow.right") {}
            GlowButton(title: "Accept Calmer Tone", icon: "checkmark", color: .vmCalm) {}
            GlowButton(title: "High Risk", color: .vmDanger) {}
        }
        .padding()
    }
}
