// MainTabView.swift
// VOXMOD

import SwiftUI

/// Root tab view after onboarding completion.
/// Custom-styled tab bar with 4 primary destinations.
struct MainTabView: View {
    
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var tabBarVisible = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $coordinator.selectedTab) {
                DashboardView()
                    .tag(NavigationCoordinator.Tab.dashboard)
                
                ComposerView()
                    .tag(NavigationCoordinator.Tab.composer)
                
                JournalView()
                    .tag(NavigationCoordinator.Tab.journal)
                
                SettingsView()
                    .tag(NavigationCoordinator.Tab.settings)
            }
            
            // Custom tab bar
            customTabBar
                .offset(y: tabBarVisible ? 0 : 100)
        }
        .onAppear {
            // Hide default tab bar
            UITabBar.appearance().isHidden = true
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                tabBarVisible = true
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(NavigationCoordinator.Tab.allCases, id: \.rawValue) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, VMSpacing.md)
        .padding(.vertical, VMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: VMRadius.xl)
                .fill(Color.vmSurface.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: VMRadius.xl)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .padding(.horizontal, VMSpacing.xl)
        .padding(.bottom, VMSpacing.sm)
    }
    
    private func tabButton(for tab: NavigationCoordinator.Tab) -> some View {
        Button {
            HapticService.shared.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                coordinator.selectedTab = tab
            }
        } label: {
            VStack(spacing: VMSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: coordinator.selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(
                        coordinator.selectedTab == tab
                        ? Color.vmIndigo
                        : Color.vmTextTertiary
                    )
                    .scaleEffect(coordinator.selectedTab == tab ? 1.1 : 1.0)
                
                Text(tab.title)
                    .font(.vmCaptionSmall)
                    .foregroundStyle(
                        coordinator.selectedTab == tab
                        ? Color.vmIndigo
                        : Color.vmTextTertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, VMSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(NavigationCoordinator())
}
