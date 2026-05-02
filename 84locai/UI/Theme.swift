import SwiftUI

// MARK: - Color Palette
extension Color {
    static let appBackground    = Color(hex: "#0A0E1A")
    static let appSurface       = Color(hex: "#111827")
    static let appCard          = Color(hex: "#1A2236")
    static let appBorder        = Color(hex: "#1E2D45")
    static let appPrimary       = Color(hex: "#7C3AED")   // violet
    static let appPrimaryLight  = Color(hex: "#A78BFA")
    static let appAccent        = Color(hex: "#06B6D4")   // cyan
    static let appAccentLight   = Color(hex: "#67E8F9")
    static let appSuccess       = Color(hex: "#10B981")
    static let appWarning       = Color(hex: "#F59E0B")
    static let appError         = Color(hex: "#EF4444")
    static let appTextPrimary   = Color(hex: "#F1F5F9")
    static let appTextSecondary = Color(hex: "#94A3B8")
    static let appTextMuted     = Color(hex: "#475569")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [.appPrimary, .appAccent],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let surfaceGradient = LinearGradient(
        colors: [Color(hex: "#111827"), Color(hex: "#0D1525")],
        startPoint: .top, endPoint: .bottom
    )
    static let userBubble = LinearGradient(
        colors: [Color(hex: "#7C3AED"), Color(hex: "#5B21B6")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Typography
extension Font {
    static let appTitle      = Font.system(size: 28, weight: .bold, design: .rounded)
    static let appHeadline   = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let appBody       = Font.system(size: 15, weight: .regular)
    static let appCaption    = Font.system(size: 12, weight: .medium)
    static let appCode       = Font.system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum Radius {
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
    static let full: CGFloat = 999
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Radius.lg

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appCard.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Radius.lg) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func appBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.full)
                    .fill(LinearGradient.primaryGradient)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
