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
        }
    }
}
