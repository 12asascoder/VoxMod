// ComposerView.swift
// VOXMOD — Smart Message Composer with Cross-App Integration

import SwiftUI

struct ComposerView: View {
    
    @StateObject private var viewModel = ComposerViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showConversations = true
    @State private var animateIn = false
    @State private var selectedConversation: ActiveConversation?
    @State private var navigateToConversation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vmBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    composerHeader
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: VMSpacing.xl) {
                            // Active conversations section
                            activeConversationsSection
                            
                            // Composer section
                            composerSection
                            
                            // Risk meter section
                            riskSection
                            
                            // Sent messages
                            sentMessagesSection
                            
                            // Bottom padding for tab bar
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, VMSpacing.xl)
                        .padding(.top, VMSpacing.lg)
                    }
                    
                    // Waveform
                    if !viewModel.messageText.isEmpty {
                        waveformSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Floating composer
                    floatingComposer
                }
                
                // Success glow overlay
                if viewModel.showSendSuccess {
                    successOverlay
                        .transition(.opacity)
                }
                
                // Intervention alert
                if viewModel.showIntervention {
                    InterventionAlertView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showIntervention)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateIn = true
                }
            }
            .navigationDestination(isPresented: $navigateToConversation) {
                if let conv = selectedConversation {
                    ConversationDetailView(conversation: conv)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var composerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Composer")
                    .font(.vmTitle)
                    .foregroundStyle(.white)
                
                Text("Monitor & compose mindfully")
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextTertiary)
            }
            
            Spacer()
            
            // Tone indicator badge
            if !viewModel.messageText.isEmpty {
                HStack(spacing: VMSpacing.xs) {
                    Circle()
                        .fill(Color.riskColor(for: viewModel.riskScore))
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.dominantTone.rawValue)
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextSecondary)
                }
                .padding(.horizontal, VMSpacing.md)
                .padding(.vertical, VMSpacing.xs)
                .glassBackground(cornerRadius: VMRadius.full)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, VMSpacing.xl)
        .padding(.top, VMSpacing.lg)
        .padding(.bottom, VMSpacing.md)
    }
    
    // MARK: - Active Conversations Section
    
    private var activeConversationsSection: some View {
        VStack(alignment: .leading, spacing: VMSpacing.lg) {
            // Section header
            HStack {
                HStack(spacing: VMSpacing.sm) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vmIndigo)
                    
                    Text("Active Conversations")
                        .font(.vmTitle2)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: VMSpacing.xs) {
                    Circle()
                        .fill(Color.vmCalm)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.vmCalm.opacity(0.3), lineWidth: 2)
                                .scaleEffect(animateIn ? 1.8 : 1.0)
                                .opacity(animateIn ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                    value: animateIn
                                )
                        )
                    
                    Text("LIVE")
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmCalm)
                        .tracking(1.0)
                }
            }
            
            // Connected apps strip
            connectedAppsStrip
            
            // Active conversation cards
            ForEach(Array(ActiveConversation.samples.enumerated()), id: \.element.id) { index, convo in
                conversationCard(convo, index: index)
                    .onTapGesture {
                        selectedConversation = convo
                        navigateToConversation = true
                    }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Connected Apps Strip
    
    private var connectedAppsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VMSpacing.md) {
                ForEach(ConnectedApp.available) { app in
                    VStack(spacing: VMSpacing.xs) {
                        ZStack {
                            Circle()
                                .fill(app.isConnected ? Color.vmCardBackground : Color.vmSurface)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            app.isConnected
                                            ? Color.vmIndigo.opacity(0.4)
                                            : Color.white.opacity(0.06),
                                            lineWidth: 1.5
                                        )
                                )
                            
                            Image(systemName: app.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(
                                    app.isConnected ? Color.vmIndigo : Color.vmTextTertiary
                                )
                        }
                        .overlay(alignment: .topTrailing) {
                            if app.isConnected {
                                Circle()
                                    .fill(Color.vmCalm)
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.vmBackground, lineWidth: 2)
                                    )
                                    .offset(x: 2, y: -2)
                            }
                        }
                        
                        Text(app.name)
                            .font(.vmCaptionSmall)
                            .foregroundStyle(
                                app.isConnected ? Color.vmTextSecondary : Color.vmTextTertiary
                            )
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Conversation Card
    
    private func conversationCard(_ conversation: ActiveConversation, index: Int) -> some View {
        GlassCard(padding: VMSpacing.md) {
            HStack(spacing: VMSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.riskColor(for: conversation.riskScore).opacity(0.3),
                                    Color.vmCardBackground
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(conversation.contactInitials)
                        .font(.vmCallout)
                        .foregroundStyle(.white)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: conversation.appIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Circle().fill(Color.vmSurface))
                        .offset(x: 4, y: 4)
                }
                
                // Content
                VStack(alignment: .leading, spacing: VMSpacing.xs) {
                    HStack {
                        Text(conversation.contactName)
                            .font(.vmHeadline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(conversation.lastMessageTime, style: .relative)
                            .font(.vmCaptionSmall)
                            .foregroundStyle(Color.vmTextTertiary)
                    }
                    
                    Text(conversation.lastMessage)
                        .font(.vmCallout)
                        .foregroundStyle(Color.vmTextSecondary)
                        .lineLimit(1)
                    
                    // Tone insight badge
                    HStack(spacing: VMSpacing.sm) {
                        toneTag(conversation.currentTone, conversation.riskScore)
                        
                        if conversation.riskScore >= 40 {
                            HStack(spacing: VMSpacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9))
                                Text("Needs attention")
                                    .font(.vmCaptionSmall)
                            }
                            .foregroundStyle(Color.vmWarning)
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 15)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8)
                .delay(0.1 + Double(index) * 0.08),
            value: animateIn
        )
    }
    
    private func toneTag(_ tone: Tone, _ risk: Double) -> some View {
        HStack(spacing: VMSpacing.xs) {
            Text(tone.emoji)
                .font(.system(size: 10))
            
            Text(tone.rawValue)
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.riskColor(for: risk))
            
            Text("•")
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.vmTextTertiary)
            
            Text("\(Int(risk))")
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.riskColor(for: risk))
        }
        .padding(.horizontal, VMSpacing.sm)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.riskColor(for: risk).opacity(0.1))
        )
    }
    
    // MARK: - Composer Section (Empty State)
    
    private var composerSection: some View {
        Group {
            if viewModel.messageText.isEmpty && viewModel.sentMessages.isEmpty {
                VStack(spacing: VMSpacing.lg) {
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                        
                        Text("QUICK COMPOSE")
                            .font(.vmCaptionSmall)
                            .foregroundStyle(Color.vmTextTertiary)
                            .tracking(1.5)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                    }
                    
                    // Info card
                    GlassCard {
                        HStack(spacing: VMSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.vmIndigo.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "waveform.and.magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.vmIndigo)
                            }
                            
                            VStack(alignment: .leading, spacing: VMSpacing.xs) {
                                Text("Tone-Aware Messaging")
                                    .font(.vmHeadline)
                                    .foregroundStyle(.white)
                                
                                Text("Type below to analyse tone in real-time. Tap a conversation above to reply with insights.")
                                    .font(.vmCallout)
                                    .foregroundStyle(Color.vmTextSecondary)
                                    .lineSpacing(2)
                            }
                        }
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)
            }
        }
    }
    
    // MARK: - Risk Section
    
    private var riskSection: some View {
        VStack(spacing: VMSpacing.lg) {
            if viewModel.riskScore > 0 {
                VStack(spacing: VMSpacing.lg) {
                    ZStack {
                        PulseAnimation(
                            riskScore: viewModel.riskScore,
                            size: 160
                        )
                        
                        RiskMeter(score: viewModel.riskScore)
                            .scaleEffect(1.2)
                    }
                    .padding(.top, VMSpacing.xl)
                    
                    // Risk level label
                    HStack(spacing: VMSpacing.xl) {
                        riskTag("TONE", viewModel.dominantTone.rawValue,
                                Color.riskColor(for: viewModel.riskScore))
                        riskTag("IMPACT",
                                viewModel.riskScore >= 50 ? "High Risk" : "Low Risk",
                                viewModel.riskScore >= 50 ? .vmWarning : .vmCalm)
                    }
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.riskScore > 0)
    }
    
    private func riskTag(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.vmTextTertiary)
                .tracking(1.0)
            Text(value)
                .font(.vmTitle2)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Sent Messages
    
    private var sentMessagesSection: some View {
        ForEach(viewModel.sentMessages) { message in
            HStack {
                Spacer()
                
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
                    
                    Text(message.timestamp, style: .time)
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextTertiary)
                }
            }
        }
    }
    
    // MARK: - Waveform
    
    private var waveformSection: some View {
        HStack(spacing: VMSpacing.md) {
            WaveformView(
                amplitudes: viewModel.waveformAmplitudes,
                color: Color.riskColor(for: viewModel.riskScore)
            )
            
            if viewModel.isAnalysing {
                ProgressView()
                    .tint(Color.vmIndigo)
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, VMSpacing.xl)
        .padding(.vertical, VMSpacing.sm)
    }
    
    // MARK: - Floating Composer
    
    private var floatingComposer: some View {
        HStack(spacing: VMSpacing.md) {
            // Text input
            TextField("Type your message...", text: $viewModel.messageText, axis: .vertical)
                .font(.vmBody)
                .foregroundStyle(.white)
                .tint(Color.vmIndigo)
                .lineLimit(1...4)
                .focused($isInputFocused)
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
            
            // Send button
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
        .padding(.horizontal, VMSpacing.xl)
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
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.vmCalm.opacity(0.08)
                .ignoresSafeArea()
            
            VStack(spacing: VMSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.vmCalm)
                
                Text("Message Sent Safely")
                    .font(.vmHeadline)
                    .foregroundStyle(Color.vmCalm)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ComposerView()
}
