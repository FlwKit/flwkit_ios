import SwiftUI

class ThemeManager {
    static let shared = ThemeManager()
    
    private var themes: [String: Theme] = [:]
    private let defaultTheme: Theme
    
    private init() {
        // Default fallback theme
        self.defaultTheme = Theme(
            id: "default",
            tokens: ThemeTokens(
                background: "#FFFFFF",
                surface: "#F9FAFB",
                primary: "#3B82F6",
                secondary: "#10B981",
                textPrimary: "#111827",
                textSecondary: "#6B7280",
                radius: "md",
                buttonStyle: "filled",
                font: "system"
            )
        )
        themes["default"] = defaultTheme
    }
    
    func registerTheme(_ theme: Theme) {
        themes[theme.id] = theme
    }
    
    func getTheme(themeId: String?) -> Theme {
        guard let themeId = themeId,
              let theme = themes[themeId] else {
            return defaultTheme
        }
        return theme
    }
    
    func resolveTheme(for screen: Screen, flowDefaultThemeId: String?) -> Theme {
        // Resolution order: screen themeId -> flow default -> SDK fallback
        if let screenThemeId = screen.themeId {
            return getTheme(themeId: screenThemeId)
        }
        if let flowThemeId = flowDefaultThemeId {
            return getTheme(themeId: flowThemeId)
        }
        return defaultTheme
    }
}

// MARK: - Theme to SwiftUI Conversion

extension ThemeTokens {
    var backgroundColor: Color {
        Color(hex: background)
    }
    
    var surfaceColor: Color {
        Color(hex: surface)
    }
    
    var primaryColor: Color {
        Color(hex: primary)
    }
    
    var secondaryColor: Color {
        if let secondary = secondary {
            return Color(hex: secondary)
        }
        return primaryColor
    }
    
    var textPrimaryColor: Color {
        Color(hex: textPrimary)
    }
    
    var textSecondaryColor: Color {
        Color(hex: textSecondary)
    }
    
    var cornerRadius: CGFloat {
        switch radius {
        case "xs": return 4
        case "sm": return 8
        case "md": return 12
        case "lg": return 16
        case "xl": return 24
        default: return 12
        }
    }
    
    var isFilledButton: Bool {
        buttonStyle == "filled"
    }
}

// MARK: - Color Extension

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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Spacing Tokens

enum Spacing {
    case xs, sm, md, lg, xl
    
    var value: CGFloat {
        switch self {
        case .xs: return 4
        case .sm: return 8
        case .md: return 16
        case .lg: return 24
        case .xl: return 32
        }
    }
    
    init?(from string: String) {
        switch string.lowercased() {
        case "xs": self = .xs
        case "sm": self = .sm
        case "md": self = .md
        case "lg": self = .lg
        case "xl": self = .xl
        default: return nil
        }
    }
}

