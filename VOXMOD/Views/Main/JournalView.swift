// JournalView.swift
// VOXMOD — Tone Reflection Journal

import SwiftUI

/// Shows a timeline of tone events with daily summaries,
/// replacing the previous placeholder.
struct JournalView: View {
    
    @State private var events: [StorageService.ToneEvent] = []
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                journalHeader
                
                if events.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: VMSpacing.md) {
                            let groups = groupedEvents
                            ForEach(0..<groups.count, id: \.self) { index in
                                let group = groups[index]
                                Section {
                                    ForEach(group.value) { event in
                                        eventRow(event)
                                    }
                                } header: {
                                    Text(group.key)
                                        .font(.vmCaptionSmall)
                                        .foregroundStyle(Color.vmTextTertiary)
                                        .tracking(1.0)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, VMSpacing.lg)
                                }
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, VMSpacing.xl)
                        .padding(.top, VMSpacing.lg)
                    }
                }
            }
        }
        .onAppear {
            events = StorageService.shared.getAllEvents()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Header
    
    private var journalHeader: some View {
        VStack(alignment: .leading, spacing: VMSpacing.xs) {
            HStack(spacing: VMSpacing.sm) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.vmIndigo)
                
                Text("JOURNAL")
                    .font(.vmCallout)
                    .foregroundStyle(.white)
                    .tracking(2)
            }
            
            Text("Tone Reflection Log")
                .font(.vmTitle)
                .foregroundStyle(.white)
            
            Text("Track your communication patterns over time.")
                .font(.vmCallout)
                .foregroundStyle(Color.vmTextSecondary)
        }
        .padding(.horizontal, VMSpacing.xl)
        .padding(.top, VMSpacing.lg)
        .padding(.bottom, VMSpacing.md)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: VMSpacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.vmIndigo.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.vmIndigo.opacity(0.5))
            }
            
            VStack(spacing: VMSpacing.sm) {
                Text("No Entries Yet")
                    .font(.vmTitle2)
                    .foregroundStyle(.white)
                
                Text("Your tone analysis events will appear here as you\nuse the Composer and Keyboard extension.")
                    .font(.vmCallout)
                    .foregroundStyle(Color.vmTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            
            GlowButton(title: "Start Composing", icon: "pencil.line") {}
            .padding(.horizontal, VMSpacing.xxxl)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Grouped Events
    
    private var groupedEvents: [(key: String, value: [StorageService.ToneEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        
        let grouped = Dictionary(grouping: events.reversed()) { event in
            if Calendar.current.isDateInToday(event.timestamp) {
                return "TODAY"
            } else if Calendar.current.isDateInYesterday(event.timestamp) {
                return "YESTERDAY"
            } else {
                return formatter.string(from: event.timestamp).uppercased()
            }
        }
        
        return grouped.sorted { $0.value.first?.timestamp ?? Date() > $1.value.first?.timestamp ?? Date() }
    }
    
    // MARK: - Event Row
    
    private func eventRow(_ event: StorageService.ToneEvent) -> some View {
        GlassCard(padding: VMSpacing.md) {
            HStack(spacing: VMSpacing.md) {
                // Tone circle
                ZStack {
                    Circle()
                        .fill(Color.riskColor(for: event.riskScore).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Text(event.dominantTone.emoji)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: VMSpacing.xs) {
                    HStack {
                        Text(event.dominantTone.rawValue)
                            .font(.vmHeadline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(event.timestamp, style: .time)
                            .font(.vmCaptionSmall)
                            .foregroundStyle(Color.vmTextTertiary)
                    }
                    
                    HStack(spacing: VMSpacing.sm) {
                        // Risk badge
                        HStack(spacing: VMSpacing.xs) {
                            Circle()
                                .fill(Color.riskColor(for: event.riskScore))
                                .frame(width: 6, height: 6)
                            
                            Text("Risk \(Int(event.riskScore))")
                                .font(.vmCaptionSmall)
                                .foregroundStyle(Color.riskColor(for: event.riskScore))
                        }
                        .padding(.horizontal, VMSpacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.riskColor(for: event.riskScore).opacity(0.1))
                        )
                        
                        // Regulated badge
                        if event.wasRegulated {
                            HStack(spacing: VMSpacing.xs) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 9))
                                Text("Regulated")
                                    .font(.vmCaptionSmall)
                            }
                            .foregroundStyle(Color.vmCalm)
                            .padding(.horizontal, VMSpacing.sm)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.vmCalm.opacity(0.1))
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    JournalView()
}
