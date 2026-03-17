// ComposerView.swift
// VOXMOD — Smart Message Composer with Cross-App Integration

import SwiftUI

struct ComposerView: View {
    
    @State private var showConversations = true
    @State private var animateIn = false
    @State private var selectedConversation: ActiveConversation?
    @State private var navigateToConversation: Bool = false
    
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
                            
                            // Bottom padding for tab bar
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, VMSpacing.xl)
                        .padding(.top, VMSpacing.lg)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateIn = true
                }
            }
            .navigationDestination(for: ActiveConversation.self) { convo in
                ConversationDetailView(conversation: convo)
            }
        }
    }
    
    // MARK: - Header
    
    private var composerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Inbox")
                    .font(.vmTitle)
                    .foregroundStyle(.white)
                
                Text("Select a conversation to reply carefully")
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextTertiary)
            }
            
            Spacer()
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
            ForEach(0..<ActiveConversation.samples.count, id: \.self) { index in
                let convo = ActiveConversation.samples[index]
                NavigationLink(value: convo) {
                    conversationCard(convo, index: index)
                }
                .buttonStyle(.plain)
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
    

}

// MARK: - Preview

#Preview {
    ComposerView()
}
