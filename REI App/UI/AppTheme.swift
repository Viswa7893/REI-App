import SwiftUI

struct AppTheme {
    // Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // Font sizes
    struct FontSize {
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 15
        static let body: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title1: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }
    
    // Corner radii
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // Shadow presets
    struct ShadowStyle {
        static let small = ShadowConfig(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = ShadowConfig(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = ShadowConfig(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // Shadow configuration
    struct ShadowConfig {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // Animation presets
    struct AnimationStyle {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

// Helper view modifiers
extension View {
    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.s)
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: AppColors.primary.opacity(0.3),
                    radius: 5, x: 0, y: 3)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.s)
            .background(AppColors.secondaryBackground)
            .foregroundColor(AppColors.primary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppColors.primary, lineWidth: 1)
            )
    }
    
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.m)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05),
                    radius: 5, x: 0, y: 2)
    }
    
    // Shadow helper
    func withShadow(_ shadowConfig: AppTheme.ShadowConfig) -> some View {
        self.shadow(
            color: shadowConfig.color,
            radius: shadowConfig.radius,
            x: shadowConfig.x,
            y: shadowConfig.y
        )
    }
}

// Color theme
struct AppColors {
    // Main theme colors
    static let primary = Color(hex: "F97B22") // Orange theme for Rupee
    static let secondary = Color(hex: "FEE8B0") // Light gold
    static let accent = Color(hex: "9CA777") // Green accent
    static let background = Color.white
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // Money colors
    static let expense = Color(hex: "F45050") // Red for expenses
    static let income = Color(hex: "39A7FF") // Blue for income
    static let saving = Color(hex: "2E8A99") // Teal for savings
    static let investment = Color(hex: "65B741") // Green for investments
}

// Extension to initialize Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 