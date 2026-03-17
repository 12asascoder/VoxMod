// OnboardingView.swift
// VOXMOD — Cinematic Story-Driven Onboarding

import SwiftUI

struct OnboardingView: View {
    
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void
    
    // Animation states
    @State private var backgroundOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0
    @State private var particlePhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dynamic background
            backgroundLayer
            
            // Floating particles
            particleLayer
            
            VStack(spacing: 0) {
                Spacer()
                
                // Scene content
                sceneContent
                
                Spacer()
                
                // Progress indicators
                progressDots
                    .padding(.bottom, VMSpacing.xl)
                
                // CTA Area
                ctaArea
                    .padding(.bottom, VMSpacing.xxxl)
            }
            .padding(.horizontal, VMSpacing.xl)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                backgroundOpacity = 1
                iconScale = 1
                contentOffset = 0
                contentOpacity = 1
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            // Radial accent glow matching current scene
            RadialGradient(
                colors: [
                    currentSceneColor.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            // Subtle moving gradient
            LinearGradient(
                colors: [
                    currentSceneColor.opacity(0.05),
                    Color.clear,
                    Color.vmPurple.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Particles
    
    private var particleLayer: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<20 {
                    let seed = Double(i) * 1.37
                    let x = (sin(time * 0.3 + seed) * 0.4 + 0.5) * size.width
                    let y = (cos(time * 0.2 + seed * 1.5) * 0.4 + 0.5) * size.height
                    let opacity = sin(time * 0.5 + seed) * 0.3 + 0.3
                    let radius: CGFloat = CGFloat(2 + sin(time + seed) * 1.5)
                    
                    let rect = CGRect(x: x - radius, y: y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(currentSceneColor.opacity(opacity * 0.5))
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - Scene Content
    
    private var sceneContent: some View {
        let scene = viewModel.scenes[viewModel.currentScene]
        
        return VStack(spacing: VMSpacing.xxl) {
            // Scene illustration
            ZStack {
                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [scene.accentColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 180, height: 180)
                
                // Icon container
                ZStack {
                    Circle()
                        .fill(Color.vmCardBackground.opacity(0.6))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(scene.accentColor.opacity(0.3), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: scene.systemIcon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [scene.accentColor, scene.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                }
            }
            .frame(height: 200)
            
            // Text content
            VStack(spacing: VMSpacing.lg) {
                Text(scene.title)
                    .font(.vmLargeTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(scene.subtitle)
                    .font(.vmBody)
                    .foregroundStyle(Color.vmTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .offset(y: contentOffset)
            .opacity(contentOpacity)
        }
        .id(viewModel.currentScene)  // Force re-render on scene change
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Progress Dots
    
    private var progressDots: some View {
        HStack(spacing: VMSpacing.sm) {
            ForEach(0..<viewModel.scenes.count, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentScene
                          ? Color.vmIndigo
                          : Color.vmTextTertiary.opacity(0.4))
                    .frame(
                        width: index == viewModel.currentScene ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentScene)
            }
        }
    }
    
    // MARK: - CTA Area
    
    private var ctaArea: some View {
        VStack(spacing: VMSpacing.lg) {
            if viewModel.showCTA {
                GlowButton(
                    title: "Start Communicating Smarter",
                    icon: "arrow.right"
                ) {
                    onComplete()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                GlowButton(
                    title: "Continue",
                    icon: "arrow.right"
                ) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        resetAnimations()
                        viewModel.advanceScene()
                        playEntranceAnimation()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var currentSceneColor: Color {
        viewModel.scenes[viewModel.currentScene].accentColor
    }
    
    private func resetAnimations() {
        iconScale = 0.7
        contentOffset = 30
        contentOpacity = 0
    }
    
    private func playEntranceAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
            iconScale = 1
            contentOffset = 0
            contentOpacity = 1
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
