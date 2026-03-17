# VOXMOD — Intelligent Speech Modulation & Personal Development System

A production-ready iOS application that prevents emotionally harmful digital messages by analysing tone in real time and guiding users toward calmer communication.

## ✨ Features

- **Real-time Tone Analysis** — AI analyses message tone while you type using Apple NaturalLanguage framework
- **Impulse Risk Score** — Visual risk meter with animated gradient gauge (0–100)
- **Pause-Before-Send** — Intelligent intervention alert when aggressive text is detected
- **AI Calmer Rephrasing** — Suggested alternative phrasing to de-escalate
- **Behaviour Dashboard** — Weekly analytics with insights, tone trends, and growth tracking
- **Privacy-First** — All processing happens on-device, zero cloud dependency

## 🏗 Architecture

```
MVVM + Clean Architecture
├── App/          → Entry point, navigation coordinator
├── Design/       → Design tokens, reusable components
├── Models/       → Data models (Message, ToneAnalysis, InsightData)
├── Services/     → Mock AI services (Tone, Insight, Haptic)
├── ViewModels/   → Reactive state management (Combine + async/await)
└── Views/        → SwiftUI screens (Onboarding, Composer, Dashboard, Settings)
```

## 🚀 Setup & Run

1. Open `VOXMOD.xcodeproj` in **Xcode 15+**
2. Select an iPhone simulator target (iPhone 15 recommended)
3. Press **⌘R** to build and run
4. The app launches into cinematic onboarding → tap through 3 scenes
5. Explore the Dashboard, Composer, and Settings tabs

## 📱 Screens

| Screen | Description |
|--------|-------------|
| **Onboarding** | 3-scene cinematic story with parallax, glow effects, floating particles |
| **Dashboard** | Glassmorphism stat cards, animated tone trends chart, insight feed |
| **Composer** | Floating input, real-time waveform, risk meter, AI intervention |
| **Intervention** | Blur overlay modal with risk score, original vs calmer rephrase |
| **Settings** | Privacy trust badges, analysis sensitivity, data management |

## 🛠 Technical Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- No external dependencies

## 📐 Design System

- **Colors**: Deep navy background, electric indigo accent, risk spectrum (green → red)
- **Typography**: SF Pro Display/Rounded system fonts
- **Components**: GlassCard, PulseAnimation, WaveformView, RiskMeter, GlowButton
- **Animations**: Spring transitions, breathing pulse, waveform, chart draw, success glow
