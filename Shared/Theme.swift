import SwiftUI

/// Every colour and brand type decision lives here. Nothing hard-codes a colour
/// anywhere else.
enum Angra {
    static let background = Color(hex: 0x0A0A0C)
    static let surface = Color(hex: 0x17181C)
    static let surfaceAlt = Color(hex: 0x212228)
    static let gold = Color(hex: 0xD4AF37)
    /// Reserved for active capture. Never used for ordinary emphasis.
    static let record = Color(hex: 0xC62828)
    static let textPrimary = Color(hex: 0xF5F2EC)
    static let textSecondary = Color(hex: 0xA8A39A)
    static let success = Color(hex: 0x42B56A)

    /// Serif is for the wordmark only — never buttons, timers, or legal text.
    static func wordmark(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    /// Monospaced digits stop the elapsed timer jittering as it counts.
    static func timer(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .rounded).monospacedDigit()
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
