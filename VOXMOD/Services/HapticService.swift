// HapticService.swift
// VOXMOD

import UIKit

/// Contextual haptic feedback engine providing emotionally appropriate
/// tactile responses throughout the VOXMOD experience.
final class HapticService {
    
    static let shared = HapticService()
    private init() {}
    
    private let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact  = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection    = UISelectionFeedbackGenerator()
    
    /// Gentle tap for UI interactions (button press, tab switch).
    func tap() {
        lightImpact.impactOccurred()
    }
    
    /// Medium pulse for tone analysis completion.
    func pulse() {
        mediumImpact.impactOccurred()
    }
    
    /// Strong alert for high-risk detection.
    func alert() {
        heavyImpact.impactOccurred()
    }
    
    /// Success feedback after safe send or rephrase acceptance.
    func success() {
        notification.notificationOccurred(.success)
    }
    
    /// Warning feedback when risk threshold is crossed.
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    /// Selection change feedback (e.g. onboarding scene transition).
    func selectionChanged() {
        selection.selectionChanged()
    }
}
