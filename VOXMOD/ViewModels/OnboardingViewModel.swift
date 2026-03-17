// OnboardingViewModel.swift
// VOXMOD

import SwiftUI
import Combine

/// Manages the 3-scene cinematic onboarding experience.
@MainActor
final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Scene Definition
    
    struct Scene: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let systemIcon: String
        let accentColor: Color
    }
    
    // MARK: - Published State
    
    @Published var currentScene: Int = 0
    @Published var isAnimating: Bool = false
    @Published var showCTA: Bool = false
    
    let scenes: [Scene] = [
        Scene(
            id: 0,
            title: "The Impulse Trap",
            subtitle: "Late night. Frustration builds.\nYour fingers fly across the keyboard.\nThe message is sharp. Hurtful. Irreversible.",
            systemIcon: "bolt.fill",
            accentColor: .vmDanger
        ),
        Scene(
            id: 1,
            title: "VOXMOD Intervenes",
            subtitle: "A soft glow. A gentle pause.\nYour words transform — same intent,\nkinder delivery. Conflict avoided.",
            systemIcon: "wand.and.stars",
            accentColor: .vmIndigo
        ),
        Scene(
            id: 2,
            title: "Conscious Communication",
            subtitle: "Clarity replaces chaos.\nProductivity improves. Relationships heal.\nYour digital life, finally calm.",
            systemIcon: "leaf.fill",
            accentColor: .vmCalm
        )
    ]
    
    var isLastScene: Bool {
        currentScene == scenes.count - 1
    }
    
    // MARK: - Actions
    
    func advanceScene() {
        guard currentScene < scenes.count - 1 else {
            showCTA = true
            return
        }
        
        HapticService.shared.selectionChanged()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.currentScene += 1
                self.isAnimating = false
            }
            
            if self.isLastScene {
                withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                    self.showCTA = true
                }
            }
        }
    }
    
    func skipToEnd() {
        HapticService.shared.tap()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentScene = scenes.count - 1
            showCTA = true
        }
    }
}
