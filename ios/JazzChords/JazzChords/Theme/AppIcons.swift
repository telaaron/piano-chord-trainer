// AppIcons — maps plan / course / celebration identifiers to SF Symbols, so the
// app never renders emoji as UI (the tell of a non-native app). Symbols render
// monochrome/hierarchical in the brand amber.

import SwiftUI
import MusicEngine

enum AppIcons {

    /// SF Symbol for a practice plan id.
    static func plan(_ id: String) -> String {
        switch id {
        case "warmup": return "sun.max.fill"
        case "speed": return "bolt.fill"
        case "deepdive": return "scope"
        case "turnaround": return "arrow.triangle.2.circlepath"
        case "challenge": return "trophy.fill"
        case "quartenzirkel": return "circle.hexagongrid.fill"
        case "voicing-drill": return "hand.raised.fingers.spread.fill"
        case "left-hand-comping": return "hand.point.up.left.fill"
        case "inversions-drill": return "arrow.up.arrow.down"
        case "in-time-comping": return "metronome.fill"
        case "ear-check": return "ear.fill"
        case "adaptive-drill": return "brain.head.profile"
        case "voice-leading-flow": return "link"
        case "weak-drill": return "target"
        default: return "pianokeys"
        }
    }

    /// SF Symbol for a course id.
    static func course(_ id: String) -> String {
        switch id {
        case "intervals": return "ruler.fill"
        case "shell-voicings": return "pianokeys"
        case "scale-degrees": return "number.square.fill"
        case "ultimate-plan": return "graduationcap.fill"
        default: return "book.fill"
        }
    }

    /// SF Symbol for a celebration type.
    static func celebration(_ type: CelebrationType) -> String {
        switch type {
        case .levelUp: return "arrow.up.circle.fill"
        case .goalComplete: return "checkmark.seal.fill"
        case .streakMilestone: return "flame.fill"
        case .personalBest: return "bolt.fill"
        case .xpGain: return "star.fill"
        }
    }
}
