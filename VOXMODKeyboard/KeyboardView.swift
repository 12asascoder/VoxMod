// KeyboardView.swift
// VOXMODKeyboard

import SwiftUI

struct KeyboardView: View {
    let actionHandler: (KeyboardAction) -> Void
    let textDocumentProxy: UITextDocumentProxy
    
    // Shared settings access
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.spazorlabs.VOXMOD") ?? .standard
    @AppStorage("analysisEnabled", store: sharedDefaults) var analysisEnabled: Bool = true
    
    // Using a timer to poll text changes for analysis context
    @State private var currentText: String = ""
    @State private var riskScore: Double = 0
    @State private var suggestedRephrase: String? = nil
    @State private var isAnalyzing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Smart AI Bar
            AISmartBar(
                riskScore: riskScore,
                suggestedRephrase: suggestedRephrase,
                isAnalyzing: isAnalyzing,
                isIntegrated: analysisEnabled,
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
        .onReceive(Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()) { _ in
            pollText()
        }
    }
    
    private func pollText() {
        guard analysisEnabled else {
            riskScore = 0
            suggestedRephrase = nil
            return
        }
        
        // Fetch surrounding text from proxy
        let beforeContext = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterContext = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = beforeContext + afterContext
        
        // Only analyse if text actually changed and isn't empty
        if !combined.isEmpty && combined != currentText {
            currentText = combined
            isAnalyzing = true
            
            Task {
                let analysis = await ToneAnalysisService.shared.analyse(combined)
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.riskScore = analysis.riskScore
                        self.suggestedRephrase = analysis.suggestedRephrase
                        self.isAnalyzing = false
                    }
                }
            }
        } else if combined.isEmpty {
            currentText = ""
            riskScore = 0
            suggestedRephrase = nil
            isAnalyzing = false
        }
    }
}

// MARK: - Smart AI Bar
struct AISmartBar: View {
    let riskScore: Double
    let suggestedRephrase: String?
    let isAnalyzing: Bool
    let isIntegrated: Bool
    let onRephrase: (String) -> Void
    
    var body: some View {
        HStack {
            // Risk / Status indicator
            ZStack {
                if isAnalyzing {
                    Circle()
                        .stroke(Color.vmIndigo.opacity(0.3), lineWidth: 2)
                        .frame(width: 16, height: 16)
                        .scaleEffect(1.5)
                        .opacity(0)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isAnalyzing)
                }
                
                Circle()
                    .fill(isIntegrated ? Color.riskColor(for: riskScore) : Color.vmTextTertiary)
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
            .padding(.trailing, 4)
            
            // Status Text
            if !isIntegrated {
                Text("INTEGRATION PAUSED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.vmTextTertiary)
            } else if riskScore > 50, let rephrase = suggestedRephrase {
                // Rephrase button
                Button(action: {
                    onRephrase(rephrase)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Use: \"\(rephrase)\"")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.vmCalm.opacity(0.2))
                    .cornerRadius(12)
                }
            } else {
                // Listening status
                HStack(spacing: 6) {
                    Text(isAnalyzing ? "ANALYZING..." : "VOXMOD INTEGRATED")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isAnalyzing ? Color.vmIndigo : Color.vmCalm.opacity(0.8))
                    
                    if isAnalyzing {
                        WaveformView(barCount: 6, color: Color.vmIndigo, maxHeight: 12)
                            .frame(width: 30)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.vmCalm.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // App Branding
            Text("VOXMOD")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(Color.vmIndigo.opacity(0.5))
        }
        .frame(height: 38)
        .padding(.horizontal, 12)
        .background(Color.vmSurface)
        .cornerRadius(19)
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
