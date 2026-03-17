// InterventionAlertView.swift
// VOXMOD — AI Pause-Before-Send Intervention

import SwiftUI

/// Full-screen blur overlay that appears when the user's message
/// exceeds the risk threshold. Presents the risk score, a calmer
/// AI-suggested rephrase, and options to pause or send anyway.
struct InterventionAlertView: View {
    
    @ObservedObject var viewModel: ComposerViewModel
    @State private var cardOffset: CGFloat = 300
    @State private var showContent = false
    @State private var pulseGlow = false
    
    var body: some View {
        ZStack {
            // Blur backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    Color.vmDanger.opacity(0.05)
                        .ignoresSafeArea()
                )
                .onTapGesture {
                    viewModel.dismissIntervention()
                }
            
            // Intervention card
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: VMSpacing.xl) {
                    // Handle
                    Capsule()
                        .fill(Color.vmTextTertiary.opacity(0.4))
                        .frame(width: 36, height: 4)
                        .padding(.top, VMSpacing.md)
                    
                    // Alert header
                    alertHeader
                    
                    // Risk score display
                    riskDisplay
                    
                    // Suggested rephrase
                    if let rephrase = viewModel.suggestedRephrase {
                        rephraseSection(rephrase)
                    }
                    
                    // Action buttons
                    actionButtons
                        .padding(.bottom, VMSpacing.xxl)
                }
                .padding(.horizontal, VMSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: VMRadius.xl)
                        .fill(Color.vmSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: VMRadius.xl)
                                .stroke(Color.vmDanger.opacity(pulseGlow ? 0.3 : 0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.vmDanger.opacity(pulseGlow ? 0.2 : 0.05),
                                radius: pulseGlow ? 30 : 10)
                )
                .offset(y: cardOffset)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardOffset = 0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
    
    // MARK: - Alert Header
    
    private var alertHeader: some View {
        VStack(spacing: VMSpacing.md) {
            // Animated warning icon
            ZStack {
                Circle()
                    .fill(Color.vmDanger.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.vmDanger)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            Text("Pause & Reflect")
                .font(.vmTitle)
                .foregroundStyle(.white)
            
            Text("Your message may come across as aggressive.\nTake a moment before sending.")
                .font(.vmCallout)
                .foregroundStyle(Color.vmTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }
    
    // MARK: - Risk Display
    
    private var riskDisplay: some View {
        GlassCard {
            HStack(spacing: VMSpacing.lg) {
                // Risk score
                VStack(spacing: VMSpacing.xs) {
                    Text("\(Int(viewModel.riskScore))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.riskColor(for: viewModel.riskScore))
                    
                    Text("/100")
                        .font(.vmCaption)
                        .foregroundStyle(Color.vmTextSecondary)
                }
                
                Divider()
                    .frame(height: 50)
                    .overlay(Color.white.opacity(0.1))
                
                // Tone details
                VStack(alignment: .leading, spacing: VMSpacing.sm) {
                    HStack(spacing: VMSpacing.xs) {
                        Text(viewModel.dominantTone.emoji)
                        Text("Detected Tone")
                            .font(.vmCaptionSmall)
                            .foregroundStyle(Color.vmTextTertiary)
                    }
                    
                    Text(viewModel.dominantTone.rawValue)
                        .font(.vmHeadline)
                        .foregroundStyle(Color.riskColor(for: viewModel.riskScore))
                    
                    Text("Recipient may feel defensive")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextSecondary)
                }
                
                Spacer()
            }
        }
        .opacity(showContent ? 1 : 0)
    }
    
    // MARK: - Rephrase Section
    
    private func rephraseSection(_ rephrase: String) -> some View {
        VStack(alignment: .leading, spacing: VMSpacing.md) {
            HStack(spacing: VMSpacing.sm) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vmIndigo)
                
                Text("AI Suggested Rephrase")
                    .font(.vmCallout)
                    .foregroundStyle(Color.vmTextSecondary)
            }
            
            // Original vs suggested
            VStack(alignment: .leading, spacing: VMSpacing.md) {
                // Original
                VStack(alignment: .leading, spacing: VMSpacing.xs) {
                    Text("ORIGINAL")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmDanger.opacity(0.7))
                        .tracking(0.8)
                    
                    Text(viewModel.messageText)
                        .font(.vmBody)
                        .foregroundStyle(Color.vmTextSecondary)
                        .strikethrough(true, color: Color.vmDanger.opacity(0.4))
                        .lineLimit(3)
                }
                .padding(VMSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: VMRadius.md)
                        .fill(Color.vmDanger.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: VMRadius.md)
                                .stroke(Color.vmDanger.opacity(0.15), lineWidth: 1)
                        )
                )
                
                // Arrow
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.vmIndigo)
                    .frame(maxWidth: .infinity)
                
                // Suggested
                VStack(alignment: .leading, spacing: VMSpacing.xs) {
                    Text("CALMER VERSION")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmCalm.opacity(0.7))
                        .tracking(0.8)
                    
                    Text(rephrase)
                        .font(.vmBody)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                }
                .padding(VMSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: VMRadius.md)
                        .fill(Color.vmCalm.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: VMRadius.md)
                                .stroke(Color.vmCalm.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
        .opacity(showContent ? 1 : 0)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: VMSpacing.md) {
            // Accept rephrase
            GlowButton(
                title: "Use Calmer Version",
                icon: "checkmark",
                color: .vmCalm
            ) {
                viewModel.acceptRephrase()
            }
            
            // Send anyway
            Button {
                viewModel.forceSend()
            } label: {
                Text("Send Original Anyway")
                    .font(.vmCallout)
                    .foregroundStyle(Color.vmTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VMSpacing.md)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vmBackground.ignoresSafeArea()
        
        InterventionAlertView(
            viewModel: {
                let vm = ComposerViewModel()
                vm.messageText = "You always mess everything up. This is unacceptable."
                vm.riskScore = 74
                vm.dominantTone = .aggressive
                vm.suggestedRephrase = "I'd like to share my perspective on this. Could we discuss a constructive way forward?"
                vm.showIntervention = true
                return vm
            }()
        )
    }
}
