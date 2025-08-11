import Foundation

enum Messages {
    static let coreReset: [String] = [
        "🪑 Sit back in your chair, hips all the way back.",
        "🧍 Ears over shoulders, gentle chin tuck.",
        "🎈 Drop your shoulders, let the base of your skull soften."
    ]

    static let extras: [String] = [
        "💨 Two-breath sigh: small inhale, bigger inhale, long exhale.",
        "👀 Look 20+ feet away for 20 seconds.",
        "💆 Roll shoulders forward/back 5 times.",
        "🤲 Interlace fingers, reach tall overhead.",
        "🦢 Imagine a string lifting the crown of your head.",
        "🌊 Close eyes, take 3 slow breaths, unclench your jaw.",
        "🙆 Gentle ear-to-shoulder stretch each side for 5 seconds.",
        "🧘‍♂️ Three tiny chin tucks: glide back, don't look down."
    ]

    static func composed() -> String {
        let core = coreReset.joined(separator: "\n")
        let extra = extras.randomElement() ?? ""
        return "\(core)\n\n✨ Extra: \(extra)"
    }
}