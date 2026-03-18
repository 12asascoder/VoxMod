// ToxicityLayer.swift
// VOXMOD — Layer 1: Keyword Toxicity Detection Engine

import Foundation
import NaturalLanguage

/// Standalone toxicity pre-filter.
/// Runs before any AI/ML scoring to ensure profanity and aggressive
/// phrasing can never be silently collapsed into a Calm result.
final class ToxicityLayer {

    static let shared = ToxicityLayer()
    private init() {}

    // MARK: - Lexicons

    /// Hard profanity and heavy insults — each hit applies maximum aggression penalty.
    private let profanityLexicon: Set<String> = [
        "motherfucker", "motherfuckers", "mf", "fucker", "fuckers",
        "fuck", "fucking", "fucked", "fck",
        "shit", "shitty", "bullshit", "piece of shit", "pos",
        "asshole", "assholes", "ass",
        "bitch", "bitches",
        "bastard", "bastards",
        "cunt", "cunts",
        "dick", "dicks", "dickhead",
        "damn you", "go to hell", "screw you", "piss off",
        "wtf", "wth", "what the hell", "what the fuck",
        "idiot", "idiots",
        "moron", "morons",
        "imbecile",
        "retard", "retarded",
        "loser", "losers",
        "dumbass", "dumb ass"
    ]

    /// Strong-negative slang that signals aggression even without hard profanity.
    private let slangLexicon: Set<String> = [
        "stupid", "dumb", "pathetic", "useless", "worthless",
        "disgusting", "terrible", "horrible", "trash", "garbage",
        "shut up", "shut it", "back off", "get lost", "get out",
        "hate you", "i hate", "hate this",
        "ridiculous", "absurd", "nonsense", "unacceptable",
        "piece of idiot", "piece of crap",
        "what is wrong with you", "are you serious",
        "such a joke"
    ]

    /// Accusatory / confrontational substrings — indicate confrontational intent.
    private let accusatoryPhrases: [String] = [
        "why didn't you",
        "why don't you",
        "why haven't you",
        "why are you",
        "you never",
        "you always",
        "this is your fault",
        "you failed",
        "you made this",
        "because of you",
        "you're the reason",
        "your problem",
        "fix your",
        "what's wrong with you",
        "what is wrong with you",
        "how could you"
    ]

    /// Urgency-pressure phrases adding to confrontational score.
    private let urgencyPhrases: [String] = [
        "immediately", "right now", "asap", "as soon as possible",
        "i'm waiting", "i have been waiting", "still waiting",
        "deadline", "overdue", "late again", "why is this taking",
        "how long does it", "hurry up"
    ]

    // MARK: - Public API

    /// Score from 0–100 indicating how toxic/aggressive the text is.
    /// Higher = more toxic. Combines profanity + slang + accusatory checks.
    func toxicityScore(for text: String) -> Double {
        let lowered = text.lowercased()
        let words = Set(
            lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)
                   .filter { !$0.isEmpty }
        )

        var score: Double = 0

        // Layer A: Profanity — strongest signal (+40 per hit, max 100)
        let profanityHits = profanityLexicon.filter { lexEntry in
            // Check whole-word match OR substring for multi-word entries
            lexEntry.contains(" ") ? lowered.contains(lexEntry) : words.contains(lexEntry)
        }
        score += Double(profanityHits.count) * 40

        // Layer B: Slang — strong signal (+25 per hit)
        let slangHits = slangLexicon.filter { lexEntry in
            lexEntry.contains(" ") ? lowered.contains(lexEntry) : words.contains(lexEntry)
        }
        score += Double(slangHits.count) * 25

        // Layer C: Accusatory phrases (+20 per match)
        let accusatoryHits = accusatoryPhrases.filter { lowered.contains($0) }
        score += Double(accusatoryHits.count) * 20

        // Layer D: Urgency combo (+10 per match — low alone, but combines)
        let urgencyHits = urgencyPhrases.filter { lowered.contains($0) }
        score += Double(urgencyHits.count) * 10

        return min(100, score)
    }

    /// Quick boolean: does the text contain ANY profanity or hard insult?
    func hasProfanity(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let words = Set(
            lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)
                   .filter { !$0.isEmpty }
        )
        return profanityLexicon.contains { entry in
            entry.contains(" ") ? lowered.contains(entry) : words.contains(entry)
        }
    }

    /// Returns true if the text has any slang-level negativity (but not hard profanity).
    func hasSlang(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let words = Set(
            lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)
                   .filter { !$0.isEmpty }
        )
        return slangLexicon.contains { entry in
            entry.contains(" ") ? lowered.contains(entry) : words.contains(entry)
        }
    }

    /// Returns true if the text has accusatory or confrontational framing.
    func isAccusatory(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return accusatoryPhrases.contains { lowered.contains($0) }
    }

    /// Urgency score 0–1 (normalized) based on pressure phrases.
    func urgencyScore(for text: String) -> Double {
        let lowered = text.lowercased()
        let hits = urgencyPhrases.filter { lowered.contains($0) }
        return min(1.0, Double(hits.count) * 0.35)
    }

    /// **Calm Gate**: Returns true ONLY when message is safe to be labelled Calm.
    ///
    /// Rules:
    /// - toxicityScore must be < 10
    /// - NL sentiment must be > -0.10 (not negative)
    /// - urgency score must be < 0.3
    /// - No accusatory phrasing
    func calmIsAllowed(toxicity: Double, sentiment: Double, urgency: Double, text: String) -> Bool {
        return toxicity < 10
            && sentiment > -0.10
            && urgency < 0.30
            && !isAccusatory(text)
    }

    // MARK: - Sentiment Helper (Apple NL)

    /// Raw Apple NL sentiment polarity: -1.0 (very negative) to +1.0 (very positive)
    func sentimentPolarity(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(tag?.rawValue ?? "0") ?? 0
    }
}
