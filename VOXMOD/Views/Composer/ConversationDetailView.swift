// ConversationDetailView.swift
// VOXMOD — Chat-style view with inline tone insights

import SwiftUI

/// Shows a chat thread from a connected app with real-time tone
/// analysis badges on each user-sent message.
struct ConversationDetailView: View {
    
    let conversation: ActiveConversation
    @StateObject private var viewModel = ComposerViewModel()
    @State private var animateIn = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: NavigationCoordinator
    
    var body: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                conversationHeader
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: VMSpacing.md) {
                            ForEach(0..<conversation.messages.count, id: \.self) { index in
                                let message = conversation.messages[index]
                                chatBubble(for: message, index: index)
                            }
                            
                            // Sent messages from current session
                            ForEach(viewModel.sentMessages) { message in
                                sessionBubble(for: message)
                            }
                        }
                        .padding(.horizontal, VMSpacing.lg)
                        .padding(.top, VMSpacing.lg)
                        .padding(.bottom, VMSpacing.xxxl)
                    }
                }
                
                // Tone insight bar
                if !viewModel.messageText.isEmpty {
                    toneInsightBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Composer input
                composeBar
            }
            
            // Intervention overlay
            if viewModel.showIntervention {
                InterventionAlertView(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showIntervention)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.riskScore > 0)
        .navigationBarHidden(true)
        .onAppear {
            coordinator.isTabBarVisible = false
        }
        .onDisappear {
            coordinator.isTabBarVisible = true
        }
    }
    
    // MARK: - Header
    
    private var conversationHeader: some View {
        HStack(spacing: VMSpacing.md) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.vmIndigo, .vmPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text(conversation.contactInitials)
                    .font(.vmCallout)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.contactName)
                    .font(.vmHeadline)
                    .foregroundStyle(.white)
                
                HStack(spacing: VMSpacing.xs) {
                    Image(systemName: conversation.appIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.vmTextTertiary)
                    
                    Text("via \(conversation.appName)")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextTertiary)
                }
            }
            
            Spacer()
            
            // Live tone indicator
            HStack(spacing: VMSpacing.xs) {
                Circle()
                    .fill(Color.riskColor(for: conversation.riskScore))
                    .frame(width: 8, height: 8)
                
                Text(conversation.currentTone.rawValue)
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextSecondary)
            }
            .padding(.horizontal, VMSpacing.md)
            .padding(.vertical, VMSpacing.xs)
            .glassBackground(cornerRadius: VMRadius.full)
        }
        .padding(.horizontal, VMSpacing.lg)
        .padding(.vertical, VMSpacing.md)
        .background(
            Rectangle()
                .fill(Color.vmSurface.opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Chat Bubble
    
    private func chatBubble(for message: ChatMessage, index: Int) -> some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: VMSpacing.xs) {
                // Message text
                Text(message.text)
                    .font(.vmBody)
                    .foregroundStyle(.white)
                    .padding(.horizontal, VMSpacing.lg)
                    .padding(.vertical, VMSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: VMRadius.lg)
                            .fill(
                                message.isFromUser
                                ? LinearGradient(
                                    colors: [.vmIndigo, .vmPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.vmCardBackground, Color.vmSurface],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                // Tone insight badge (only for user messages with analysis)
                if message.isFromUser, let tone = message.toneTag, let risk = message.riskScore {
                    toneInsightBadge(tone: tone, risk: risk)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextTertiary)
            }
            
            if !message.isFromUser { Spacer(minLength: 60) }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
    
    private func sessionBubble(for message: Message) -> some View {
        HStack {
            Spacer(minLength: 60)
            
            VStack(alignment: .trailing, spacing: VMSpacing.xs) {
                Text(message.text)
                    .font(.vmBody)
                    .foregroundStyle(.white)
                    .padding(.horizontal, VMSpacing.lg)
                    .padding(.vertical, VMSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: VMRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [.vmIndigo, .vmPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                if let analysis = message.toneAnalysis {
                    toneInsightBadge(tone: analysis.dominantTone, risk: analysis.riskScore)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextTertiary)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Tone Insight Badge
    
    private func toneInsightBadge(tone: Tone, risk: Double) -> some View {
        HStack(spacing: VMSpacing.xs) {
            Text(tone.emoji)
                .font(.system(size: 11))
            
            Text(tone.rawValue)
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.riskColor(for: risk))
            
            Text("•")
                .foregroundStyle(Color.vmTextTertiary)
                .font(.vmCaptionSmall)
            
            Text("Risk \(Int(risk))")
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.riskColor(for: risk))
        }
        .padding(.horizontal, VMSpacing.sm)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.riskColor(for: risk).opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.riskColor(for: risk).opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Tone Insight Bar
    
    private var toneInsightBar: some View {
        HStack(spacing: VMSpacing.md) {
            if viewModel.isAnalysing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.vmIndigo)
                    .frame(width: 28, height: 28)
                
                Text("Analyzing tone...")
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextTertiary)
            } else {
                // Animated risk dot
                ZStack {
                    Circle()
                        .fill(Color.riskColor(for: viewModel.riskScore).opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .fill(Color.riskColor(for: viewModel.riskScore))
                        .frame(width: 10, height: 10)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.riskScore < 25 ? "AI Verification" : "Live Tone Analysis")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextTertiary)
                        .tracking(0.5)
                    
                    HStack(spacing: VMSpacing.sm) {
                        if viewModel.riskScore < 25 {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.vmCalm)
                            Text("Good to send")
                                .font(.vmCallout)
                                .foregroundStyle(Color.vmCalm)
                        } else {
                            Text(viewModel.dominantTone.emoji)
                                .font(.system(size: 14))
                            
                            Text(viewModel.dominantTone.rawValue)
                                .font(.vmCallout)
                                .foregroundStyle(Color.riskColor(for: viewModel.riskScore))
                            
                            Text("• Risk \(Int(viewModel.riskScore))")
                                .font(.vmCallout)
                                .foregroundStyle(Color.vmTextSecondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if !viewModel.isAnalysing && viewModel.riskScore >= 40, let rephrase = viewModel.suggestedRephrase {
                Button {
                    viewModel.acceptRephrase()
                } label: {
                    HStack(spacing: VMSpacing.xs) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12))
                        Text("Soften")
                            .font(.vmCaptionSmall)
                    }
                    .foregroundStyle(Color.vmCalm)
                    .padding(.horizontal, VMSpacing.md)
                    .padding(.vertical, VMSpacing.sm)
                    .background(
                        Capsule()
                            .fill(Color.vmCalm.opacity(0.15))
                    )
                }
            }
        }
        .padding(.horizontal, VMSpacing.lg)
        .padding(.vertical, VMSpacing.sm)
        .background(
            Rectangle()
                .fill(Color.vmSurface.opacity(0.95))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.white.opacity(0.04)),
                    alignment: .top
                )
        )
    }
    
    // MARK: - Compose Bar
    
    private var composeBar: some View {
        HStack(spacing: VMSpacing.md) {
            TextField("Type your reply...", text: $viewModel.messageText, axis: .vertical)
                .font(.vmBody)
                .foregroundStyle(.white)
                .tint(Color.vmIndigo)
                .lineLimit(1...4)
                .padding(.horizontal, VMSpacing.lg)
                .padding(.vertical, VMSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: VMRadius.xl)
                        .fill(Color.vmCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: VMRadius.xl)
                                .stroke(
                                    viewModel.riskScore >= 50
                                    ? Color.riskColor(for: viewModel.riskScore).opacity(0.5)
                                    : Color.white.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                )
            
            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        viewModel.messageText.isEmpty
                        ? Color.vmTextTertiary
                        : Color.riskColor(for: viewModel.riskScore)
                    )
                    .scaleEffect(viewModel.messageText.isEmpty ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6),
                               value: viewModel.messageText.isEmpty)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, VMSpacing.lg)
        .padding(.vertical, VMSpacing.md)
        .background(
            Rectangle()
                .fill(Color.vmBackground.opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConversationDetailView(conversation: ActiveConversation.samples[0])
    }
}
