// JournalViewModel.swift
// VOXMOD — Long-form Tone Reflection

import SwiftUI
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var riskScore: Double = 0
    @Published var dominantTone: Tone = .neutral
    @Published var isAnalysing: Bool = false
    
    // Waveform amplitudes for visual feedback
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 0.1, count: 8)

    private let analysisService = ToneAnalysisService.shared
    private var analysisTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Debounce text input for tone analysis
        $text
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.analyseText(text)
            }
            .store(in: &cancellables)
            
        // Animate waveform while typing
        $text
            .sink { [weak self] text in
                self?.updateWaveform(isTyping: !text.isEmpty)
            }
            .store(in: &cancellables)
    }
    
    private func analyseText(_ text: String) {
        analysisTask?.cancel()
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.easeOut(duration: 0.5)) {
                riskScore = 0
                dominantTone = .neutral
            }
            return
        }
        
        isAnalysing = true
        
        analysisTask = Task {
            let result = await analysisService.analyse(text)
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                self.riskScore = result.riskScore
                self.dominantTone = result.dominantTone
                self.isAnalysing = false
            }
        }
    }
    
    private func updateWaveform(isTyping: Bool) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isTyping {
                waveformAmplitudes = (0..<8).map { _ in CGFloat.random(in: 0.2...0.9) }
            } else {
                waveformAmplitudes = Array(repeating: 0.1, count: 8)
            }
        }
    }
}
