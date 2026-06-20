// Typography — the brand display face (Space Grotesk) for the chord symbol and
// large titles, alongside SF for body/UI. Bundled via UIAppFonts; the real
// registered family name is "Space Grotesk". Display sizes scale with Dynamic
// Type via .custom(_, size:relativeTo:).

import SwiftUI

enum Display {
    static let family = "Space Grotesk"

    /// Huge chord symbol on the trainer.
    static func chord(_ size: CGFloat = 60) -> Font {
        .custom(family, size: size, relativeTo: .largeTitle).weight(.bold)
    }

    /// Large screen titles ("Good morning", "Nice work").
    static func title(_ size: CGFloat = 30) -> Font {
        .custom(family, size: size, relativeTo: .largeTitle).weight(.bold)
    }

    /// Section / card headline.
    static func headline(_ size: CGFloat = 18) -> Font {
        .custom(family, size: size, relativeTo: .headline).weight(.medium)
    }
}

extension Text {
    /// Apply the display face quickly.
    func display(_ size: CGFloat) -> Text {
        self.font(.custom(Display.family, size: size))
    }
}
