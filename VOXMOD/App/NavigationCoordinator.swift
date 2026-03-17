// NavigationCoordinator.swift
// VOXMOD

import SwiftUI

/// Centralized navigation state manager for the VOXMOD app.
/// Uses NavigationPath for programmatic, type-safe navigation.
final class NavigationCoordinator: ObservableObject {
    
    enum Tab: Int, CaseIterable {
        case dashboard = 0
        case composer
        case journal
        case settings
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .composer:  return "Composer"
            case .journal:   return "Journal"
            case .settings:  return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .composer:  return "bubble.left.and.text.bubble.right.fill"
            case .journal:   return "book.fill"
            case .settings:  return "gearshape.fill"
            }
        }
    }
    
    @Published var selectedTab: Tab = .dashboard
    @Published var isTabBarVisible: Bool = true
    @Published var dashboardPath = NavigationPath()
    @Published var composerPath = NavigationPath()
    
    func resetToRoot() {
        dashboardPath = NavigationPath()
        composerPath = NavigationPath()
    }
}
