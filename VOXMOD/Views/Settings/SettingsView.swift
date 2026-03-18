// SettingsView.swift
// VOXMOD — Settings & Privacy Trust Screen

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showDeleteConfirmation = false
    @State private var animateBadges = false
    
    var body: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: VMSpacing.xl) {
                    // Header
                    settingsHeader
                    
                    // Privacy trust badges
                    privacyBadgesSection
                    
                    // Analysis settings
                    analysisSection
                    
                    // Preferences
                    preferencesSection
                    
                    // Data management
                    dataSection
                    
                    // App info
                    appInfoSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, VMSpacing.xl)
                .padding(.top, VMSpacing.lg)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateBadges = true
            }
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteAllData()
                // Notify the app entry-point to navigate back to onboarding
                NotificationCenter.default.post(name: .voxmodFullReset, object: nil)
            }
        } message: {
            Text("This will erase all data including analytics, settings, and preferences, and reset the app to its initial state. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: VMSpacing.xs) {
            Text("Settings")
                .font(.vmTitle)
                .foregroundStyle(.white)
            
            Text("Privacy & preferences")
                .font(.vmCallout)
                .foregroundStyle(Color.vmTextSecondary)
        }
    }
    
    // MARK: - Privacy Badges
    
    private var privacyBadgesSection: some View {
        VStack(spacing: VMSpacing.md) {
            ForEach(Array(viewModel.privacyBadges.enumerated()), id: \.offset) { index, badge in
                GlassCard {
                    HStack(spacing: VMSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(Color.vmCalm.opacity(0.12))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: badge.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.vmCalm)
                        }
                        
                        VStack(alignment: .leading, spacing: VMSpacing.xs) {
                            Text(badge.title)
                                .font(.vmHeadline)
                                .foregroundStyle(.white)
                            
                            Text(badge.subtitle)
                                .font(.vmCaption)
                                .foregroundStyle(Color.vmTextSecondary)
                                .lineSpacing(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.vmCalm.opacity(0.6))
                    }
                }
                .opacity(animateBadges ? 1 : 0)
                .offset(y: animateBadges ? 0 : 15)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(0.08 * Double(index)),
                    value: animateBadges
                )
            }
        }
    }
    
    // MARK: - Analysis Settings
    
    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: VMSpacing.md) {
            sectionHeader("Analysis")
            
            GlassCard {
                VStack(spacing: VMSpacing.lg) {
                    // Enable toggle
                    settingsToggle(
                        icon: "brain.head.profile",
                        title: "Real-time Analysis",
                        subtitle: "Analyse message tone while you type",
                        isOn: $viewModel.analysisEnabled
                    )
                    
                    Divider().overlay(Color.white.opacity(0.06))
                    
                    // Sensitivity slider
                    VStack(alignment: .leading, spacing: VMSpacing.md) {
                        HStack {
                            Text("Sensitivity")
                                .font(.vmCallout)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Text("\(Int(viewModel.sensitivity))%")
                                .font(.vmCallout)
                                .foregroundStyle(Color.vmIndigo)
                        }
                        
                        Slider(value: $viewModel.sensitivity, in: 10...100, step: 5)
                            .tint(Color.vmIndigo)
                        
                        HStack {
                            Text("Relaxed")
                                .font(.vmCaptionSmall)
                                .foregroundStyle(Color.vmTextTertiary)
                            Spacer()
                            Text("Strict")
                                .font(.vmCaptionSmall)
                                .foregroundStyle(Color.vmTextTertiary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Preferences
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: VMSpacing.md) {
            sectionHeader("Preferences")
            
            GlassCard {
                VStack(spacing: VMSpacing.lg) {
                    settingsToggle(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptic Feedback",
                        subtitle: "Vibration for risk alerts and actions",
                        isOn: $viewModel.hapticFeedback
                    )
                    
                    Divider().overlay(Color.white.opacity(0.06))
                    
                    settingsToggle(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        subtitle: "Daily insights and milestone alerts",
                        isOn: $viewModel.notificationsEnabled
                    )
                }
            }
        }
    }
    
    // MARK: - Data Management
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: VMSpacing.md) {
            sectionHeader("Data")

            GlassCard {
                VStack(spacing: VMSpacing.lg) {
                    settingsButton(
                        icon: "square.and.arrow.up",
                        title: "Export Analytics",
                        subtitle: "Download your data as JSON",
                        color: .vmIndigo
                    ) {
                        viewModel.exportData()
                    }

                    Divider().overlay(Color.white.opacity(0.06))

                    settingsButton(
                        icon: "trash.fill",
                        title: "Delete All Data",
                        subtitle: "Permanently erase all data and reset app",
                        color: .vmDanger
                    ) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
    }
    
    // MARK: - App Info
    
    private var appInfoSection: some View {
        VStack(spacing: VMSpacing.md) {
            Text("VOXMOD v1.0.0")
                .font(.vmCaption)
                .foregroundStyle(Color.vmTextTertiary)
            
            Text("Built with care for conscious communication.")
                .font(.vmCaptionSmall)
                .foregroundStyle(Color.vmTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, VMSpacing.lg)
    }
    
    // MARK: - Shared Components
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.vmTitle2)
            .foregroundStyle(.white)
    }
    
    private func settingsToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: VMSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.vmIndigo)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.vmCallout)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.vmCaptionSmall)
                    .foregroundStyle(Color.vmTextSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Color.vmIndigo)
                .labelsHidden()
        }
    }
    
    private func settingsButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: VMSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.vmCallout)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.vmCaptionSmall)
                        .foregroundStyle(Color.vmTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vmTextTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
