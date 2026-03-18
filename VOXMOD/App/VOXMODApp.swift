// VOXMODApp.swift
// VOXMOD — Intelligent Speech Modulation & Personal Development System

import SwiftUI

@main
struct VOXMODApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(coordinator)
                } else {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onReceive(NotificationCenter.default.publisher(for: .voxmodFullReset)) { _ in
                // Full cold reset: navigate back to onboarding and clear coordinator state
                coordinator.resetToRoot()
                withAnimation(.easeInOut(duration: 0.5)) {
                    hasCompletedOnboarding = false
                }
            }
        }
    }
}
