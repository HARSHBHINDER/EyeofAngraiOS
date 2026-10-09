import SwiftUI

/// EyeofAngra's design system: one obsidian ground, one gold accent, one alarm red.
/// Every colour, type, motion and metric decision lives here, so five screens read
/// as one instrument rather than five apps.
enum Angra {

    // MARK: - Palette

    /// Near-black with a warm bias — a pure neutral reads as unconsidered, and the
    /// warmth ties the ground to the gold.
    static let background = Color(hex: 0x08080A)
    static let surface = Color(hex: 0x131318)
    static let surfaceAlt = Color(hex: 0x1C1C22)

    static let gold = Color(hex: 0xD4AF37)
    static let goldBright = Color(hex: 0xF0D178)
    static let goldDeep = Color(hex: 0xA98928)

    /// Reserved for active capture. Never ordinary emphasis.
    static let record = Color(hex: 0xE0342E)

    static let textPrimary = Color(hex: 0xF7F4EE)
    static let textSecondary = Color(hex: 0x9E9A92)
    static let textTertiary = Color(hex: 0x6A6760)

    // MARK: - Materials

    /// Brushed gold. Carried by the few elements that *are* the brand — never a fill
    /// for ordinary controls.
    static let goldGradient = LinearGradient(
        colors: [goldBright, gold, goldDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Cards lift very slightly toward the top, so surfaces read as lit from above.
    static let cardGradient = LinearGradient(
        colors: [Color(hex: 0x1A1A20), Color(hex: 0x121217)],
        startPoint: .top, endPoint: .bottom
    )

    /// Edge light along a card's border — the highlight a real material catches.
    static let edgeLight = LinearGradient(
        colors: [gold.opacity(0.34), gold.opacity(0.06), .clear],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Metrics

    static let radiusCard: CGFloat = 20
    static let radiusTile: CGFloat = 16
    static let hairline: CGFloat = 0.75

    // MARK: - Motion
    //
    // Apple's two parameters, not the physics triplet. Damping 1.0 settles without
    // overshoot and suits anything that simply appears; bounce is reserved for
    // motion a gesture already carried.

    static let spring = Animation.spring(response: 0.34, dampingFraction: 1.0)
    static let springMomentum = Animation.spring(response: 0.38, dampingFraction: 0.78)
    static let press = Animation.spring(response: 0.2, dampingFraction: 0.9)

    // MARK: - Type
    //
    // Tracking is size-specific: large text reads too loose without negative
    // tracking, small caps too tight without positive.

    static func display(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func wordmark(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    /// Monospaced digits stop the elapsed counter jittering as it counts.
    static func timer(_ size: CGFloat = 56) -> Font {
        .system(size: size, weight: .regular, design: .serif).monospacedDigit()
    }
}

// MARK: - Brand

/// The gold-and-bone wordmark, one identity across the app.
struct BrandWordmark: View {
    var size: CGFloat = 20

    var body: some View {
        HStack(spacing: 0) {
            Text("Eyeof").foregroundStyle(Angra.textPrimary)
            Text("Angra").foregroundStyle(Angra.goldGradient)
        }
        .font(Angra.wordmark(size))
        .tracking(size > 28 ? -0.4 : 0.2)
    }
}

/// Small gold label that opens a section. Uppercase and tracked wide, so it reads
/// as structure rather than content.
struct Eyebrow: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.6)
            .foregroundStyle(Angra.gold)
    }
}

// MARK: - Components

/// Card surface: lifted gradient, gold hairline, and an edge-light. Used for every
/// grouped row so the app has one material vocabulary.
struct PremiumCard: ViewModifier {
    var radius: CGFloat = Angra.radiusCard

    func body(content: Content) -> some View {
        content
            .background(Angra.cardGradient, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Angra.edgeLight, lineWidth: Angra.hairline)
            )
    }
}

extension View {
    func premiumCard(radius: CGFloat = Angra.radiusCard) -> some View {
        modifier(PremiumCard(radius: radius))
    }
}

/// Press feedback on touch-down, not release — the moment the user is watching.
/// The scale is deliberately small; anything larger reads as a toy.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Angra.press, value: configuration.isPressed)
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
