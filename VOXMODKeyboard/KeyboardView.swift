// KeyboardView.swift
// VOXMODKeyboard

import SwiftUI

struct KeyboardView: View {
    let actionHandler: (KeyboardAction) -> Void
    let textDocumentProxy: UITextDocumentProxy
    
    // Using a timer to poll text changes for analysis context
    @State private var currentText: String = ""
    @State private var riskScore: Double = 0
    @State private var suggestedRephrase: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Smart AI Bar
            AISmartBar(
                riskScore: riskScore,
                suggestedRephrase: suggestedRephrase,
                onRephrase: { rephrase in
                    actionHandler(.replaceText(rephrase))
                    riskScore = 0
                    suggestedRephrase = nil
                }
            )
            .padding(.bottom, 8)
            
            // Minimal Key Layout
            MinimalKeys(actionHandler: actionHandler)
        }
        .padding(8)
        .background(Color.vmBackground)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            pollText()
        }
    }
    
    private func pollText() {
        // Fetch surrounding text from proxy
        let beforeContext = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterContext = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = beforeContext + afterContext
        
        if combined != currentText {
            currentText = combined
            // In a real app, this would call ToneAnalysisService
            // For now, we simulate basic detection to ensure UI works
            if combined.lowercased().contains("hate") || combined.lowercased().contains("stupid") {
                withAnimation {
                    riskScore = 80
                    suggestedRephrase = "I strongly disagree with this approach."
                }
            } else {
                withAnimation {
                    riskScore = 0
                    suggestedRephrase = nil
                }
            }
        }
    }
}

// MARK: - Smart AI Bar
struct AISmartBar: View {
    let riskScore: Double
    let suggestedRephrase: String?
    let onRephrase: (String) -> Void
    
    var body: some View {
        HStack {
            // Risk indicator
            ZStack {
                Circle()
                    .fill(Color.riskColor(for: riskScore))
                    .frame(width: 8, height: 8)
                
                if riskScore > 50 {
                    Circle()
                        .stroke(Color.riskColor(for: riskScore).opacity(0.5))
                        .frame(width: 16, height: 16)
                        .scaleEffect(1.2)
                        .opacity(0.5)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: riskScore)
                }
            }
            .padding(.trailing, 8)
            
            if riskScore > 50, let rephrase = suggestedRephrase {
                // Rephrase button
                Button(action: {
                    onRephrase(rephrase)
                }) {
                    Text("Use: \"\(rephrase)\"")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.vmCalm.opacity(0.2))
                        .cornerRadius(12)
                }
            } else {
                // Waveform placeholder when typing normally
                WaveformView(barCount: 8, color: Color.vmIndigo, maxHeight: 16)
                    .frame(width: 40)
            }
            
            Spacer()
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
        .background(Color.vmSurface)
        .cornerRadius(18)
    }
}

// MARK: - Dummy Minimal Keys
// Real keyboard development requires massive customized layout structs.
struct MinimalKeys: View {
    let actionHandler: (KeyboardAction) -> Void
    
    let rows = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Next", "Z", "X", "C", "V", "B", "N", "M", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { key in
                        KeyButton(key: key, actionHandler: actionHandler)
                    }
                }
            }
            // Spacebar row
            HStack(spacing: 6) {
                KeyButton(key: "space", actionHandler: actionHandler)
                KeyButton(key: "return", actionHandler: actionHandler)
            }
        }
    }
}

struct KeyButton: View {
    let key: String
    let actionHandler: (KeyboardAction) -> Void
    
    var body: some View {
        Button(action: {
            if key == "Next" { actionHandler(.nextKeyboard) }
            else if key == "⌫" { actionHandler(.delete) }
            else if key == "space" { actionHandler(.space) }
            else if key == "return" { actionHandler(.return) }
            else { actionHandler(.character(key.lowercased())) }
        }) {
            Text(key == "space" ? "" : key)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.vmTextPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(key == "Next" || key == "return" ? Color.vmIndigo.opacity(0.3) : Color.vmCardBackground)
                .cornerRadius(6)
        }
    }
}

extension Color {
    // Basic duplication of DesignSystem for independence if needed, or link DesignSystem target
    static let vmBackgroundK     = Color(red: 0.039, green: 0.055, blue: 0.153)
    static let vmSurfaceK        = Color(red: 0.067, green: 0.082, blue: 0.192)
    static let vmCardBackgroundK = Color(red: 0.098, green: 0.118, blue: 0.243)
    
    // Fallbacks just in case Target inclusion fails initially
}
