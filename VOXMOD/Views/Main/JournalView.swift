// JournalView.swift
// VOXMOD — Tone Reflection Journal

import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @FocusState private var isFocused: Bool
    @State private var animateIn = false
    
    // For the history sheet
    @State private var showHistory = false
    @State private var pastEntries: [StorageService.JournalEntry] = []
    
    var body: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                journalHeader
                
                // Text Editor
                journalEditor
                
                // Bottom Analysis Bar
                if viewModel.text != viewModel.savedEntry?.text && !viewModel.text.isEmpty {
                    analysisBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let entry = viewModel.savedEntry {
                    insightCard(entry: entry)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            pastEntries = StorageService.shared.getAllJournalEntries()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showHistory) {
            historySheet
        }
    }
    
    // MARK: - Header
    
    private var journalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Journal")
                    .font(.vmTitle)
                    .foregroundStyle(.white)
                
                Text(Date(), style: .date)
                    .font(.vmCallout)
                    .foregroundStyle(Color.vmTextSecondary)
            }
            
            Spacer()
            
            // History Button
            Button {
                showHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.vmTextSecondary)
                    .padding(VMSpacing.md)
                    .glassBackground(cornerRadius: VMRadius.md)
            }
        }
        .padding(.horizontal, VMSpacing.xl)
        .padding(.top, VMSpacing.lg)
        .padding(.bottom, VMSpacing.lg)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Editor
    
    private var journalEditor: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.text.isEmpty {
                Text("Write your thoughts down here. VOXMOD will gently analyze your tone as you reflect on your day...")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(Color.vmTextTertiary)
                    .padding(.horizontal, VMSpacing.xl)
                    .padding(.top, VMSpacing.sm)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $viewModel.text)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(.white)
                .tint(Color.vmIndigo)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, VMSpacing.lg)
                .focused($isFocused)
                // Add padding to bottom so text doesn't hide behind analysis bar
                .padding(.bottom, 120) 
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeIn(duration: 0.5), value: viewModel.text.isEmpty)
    }
    
    // MARK: - Analysis Bar
    
    private var analysisBar: some View {
        VStack(spacing: 0) {
            // Gradient separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.riskColor(for: viewModel.riskScore).opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            HStack(spacing: VMSpacing.md) {
                // Waveform
                WaveformView(
                    amplitudes: viewModel.waveformAmplitudes,
                    color: Color.riskColor(for: viewModel.riskScore)
                )
                .frame(width: 60)
                
                if viewModel.isAnalysing {
                    ProgressView()
                        .tint(Color.vmIndigo)
                        .scaleEffect(0.8)
                } else {
                    // Insights
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Tone")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.vmTextTertiary)
                            .tracking(1.0)
                        
                        HStack(spacing: 6) {
                            Text(viewModel.dominantTone.emoji)
                                .font(.system(size: 14))
                            
                            Text(viewModel.dominantTone.rawValue)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.riskColor(for: viewModel.riskScore))
                        }
                    }
                }
                
                Spacer()
                
                // Done / Save
                Button {
                    isFocused = false
                    viewModel.saveDailyEntry()
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(Color.vmIndigo)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.vmIndigo)
                    }
                }
                .disabled(viewModel.isSaving)
            }
            .padding(.horizontal, VMSpacing.xl)
            .padding(.top, VMSpacing.lg)
            .padding(.bottom, VMSpacing.lg + 90) // Added clearance for the custom tab bar
            .background(
                Rectangle()
                    .fill(Color.vmSurface.opacity(0.95))
                    .overlay(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
    
    // MARK: - Insight Card
    
    private func insightCard(entry: StorageService.JournalEntry) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: VMSpacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.vmIndigo)
                    
                    Text("Tomorrow's Insight")
                        .font(.vmCallout)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(entry.tone.emoji)
                        .font(.system(size: 16))
                }
                
                if let insight = entry.insight, !insight.isEmpty {
                    Text(insight)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(Color.vmTextSecondary)
                        .lineSpacing(4)
                } else {
                    Text("Take a deep breath and rest well. Tomorrow is a new day.")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(Color.vmTextSecondary)
                }
            }
        }
        .padding(.horizontal, VMSpacing.xl)
        .padding(.top, VMSpacing.md)
        .padding(.bottom, VMSpacing.lg + 90) // clearance for tab bar
    }
    
    // MARK: - History Sheet
    
    private var historySheet: some View {
        ZStack {
            Color.vmBackground.ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Past Reflections")
                        .font(.vmTitle2)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        showHistory = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.vmTextSecondary)
                    }
                }
                .padding()
                
                if pastEntries.isEmpty {
                    Spacer()
                    Text("No past journal entries.")
                        .font(.vmCallout)
                        .foregroundStyle(Color.vmTextSecondary)
                    Spacer()
                } else {
                    List {
                        ForEach(pastEntries) { entry in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(entry.tone.emoji)
                                    Text(entry.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(Color.vmTextSecondary)
                                    Spacer()
                                    Text(entry.tone.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(Color.riskColor(for: entry.riskScore))
                                }
                                
                                Text(entry.text)
                                    .font(.system(size: 14, design: .serif))
                                    .foregroundStyle(.white)
                                    .lineLimit(3)
                                
                                if let insight = entry.insight, !insight.isEmpty {
                                    HStack(alignment: .top) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.vmIndigo)
                                        Text(insight)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.vmTextTertiary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.vmSurface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

#Preview {
    JournalView()
}
