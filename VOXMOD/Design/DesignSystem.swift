// DesignSystem.swift
// VOXMOD — Central Design Tokens

import SwiftUI

// MARK: - Color Palette

extension Color {
    // Core backgrounds
    static let vmBackground     = Color(red: 0.039, green: 0.055, blue: 0.153)   // #0A0E27
    static let vmSurface        = Color(red: 0.067, green: 0.082, blue: 0.192)   // #111531
    static let vmCardBackground = Color(red: 0.098, green: 0.118, blue: 0.243)   // #191E3E
    
    // Accents
    static let vmIndigo         = Color(red: 0.310, green: 0.275, blue: 0.898)   // #4F46E5
    static let vmElectricBlue   = Color(red: 0.353, green: 0.467, blue: 1.0)     // #5A77FF
    static let vmPurple         = Color(red: 0.545, green: 0.361, blue: 0.957)   // #8B5CF6
    
    // Risk spectrum
    static let vmCalm           = Color(red: 0.204, green: 0.827, blue: 0.600)   // #34D399
    static let vmCaution        = Color(red: 1.0,   green: 0.757, blue: 0.027)   // #FFC107
    static let vmWarning        = Color(red: 1.0,   green: 0.565, blue: 0.204)   // #FF9034
    static let vmDanger         = Color(red: 0.937, green: 0.267, blue: 0.267)   // #EF4444
    
    // Text
    static let vmTextPrimary    = Color.white
    static let vmTextSecondary  = Color(red: 0.600, green: 0.620, blue: 0.720)   // #999EB8
    static let vmTextTertiary   = Color(red: 0.400, green: 0.420, blue: 0.540)   // #666B8A
    
    /// Returns a risk-appropriate color for the given score (0–100).
    static func riskColor(for score: Double) -> Color {
        switch score {
        case 0..<25:   return .vmCalm
        case 25..<50:  return .vmCaution
        case 50..<75:  return .vmWarning
        default:       return .vmDanger
        }
    }
    
    /// Returns a gradient representing the risk spectrum.
    static var riskGradient: LinearGradient {
        LinearGradient(
            colors: [.vmCalm, .vmCaution, .vmWarning, .vmDanger],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Typography

extension Font {
    static let vmLargeTitle  = Font.system(size: 32, weight: .bold, design: .rounded)
    static let vmTitle       = Font.system(size: 24, weight: .bold, design: .rounded)
    static let vmTitle2      = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let vmHeadline    = Font.system(size: 17, weight: .semibold, design: .default)
    static let vmBody        = Font.system(size: 16, weight: .regular, design: .default)
    static let vmCallout     = Font.system(size: 14, weight: .medium, design: .default)
    static let vmCaption     = Font.system(size: 12, weight: .medium, design: .default)
    static let vmCaptionSmall = Font.system(size: 10, weight: .semibold, design: .default)
}

// MARK: - Spacing & Radii

enum VMSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum VMRadius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let full: CGFloat = 100
}

// MARK: - View Modifiers

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = VMRadius.lg
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = VMRadius.lg) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}
