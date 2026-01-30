import SwiftUI
import UIKit

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
    
    /// Parse rgba color string (e.g., "rgba(156, 163, 175, 0.8)")
    static func fromRgba(_ rgbaString: String) -> Color? {
        let pattern = #"rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let nsString = rgbaString as NSString
        let range = NSRange(location: 0, length: nsString.length)
        guard let match = regex.firstMatch(in: rgbaString, range: range) else {
            return nil
        }
        
        guard let r = Double(nsString.substring(with: match.range(at: 1))),
              let g = Double(nsString.substring(with: match.range(at: 2))),
              let b = Double(nsString.substring(with: match.range(at: 3))),
              let a = Double(nsString.substring(with: match.range(at: 4))) else {
            return nil
        }
        
        return Color(
            .sRGB,
            red: r / 255.0,
            green: g / 255.0,
            blue: b / 255.0,
            opacity: a
        )
    }
    
    /// Resolve subtitle color with proper handling of hex/rgba and opacity
    static func resolveSubtitleColor(
        subtitleColor: String?,
        subtitleOpacity: Double?,
        themeTextSecondary: String
    ) -> Color {
        guard let colorString = subtitleColor else {
            // Fallback to theme's textSecondary
            return Color(hex: themeTextSecondary)
        }
        
        // If rgba, parse it directly (ignore subtitleOpacity)
        if colorString.hasPrefix("rgba") {
            return Color.fromRgba(colorString) ?? Color(hex: themeTextSecondary)
        }
        
        // If hex with opacity < 100, convert to rgba
        if colorString.hasPrefix("#"), let opacity = subtitleOpacity, opacity < 100 {
            let color = Color(hex: colorString)
            return color.opacity(opacity / 100.0)
        }
        
        // Otherwise, use hex directly
        return Color(hex: colorString)
    }
}

// MARK: - Text with Letter Spacing (iOS 15 Compatible)

struct TextWithLetterSpacing: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor
    let letterSpacing: CGFloat
    let textAlignment: NSTextAlignment
    
    init(text: String, font: UIFont, color: UIColor, letterSpacing: CGFloat, textAlignment: NSTextAlignment = .left) {
        self.text = text
        self.font = font
        self.color = color
        self.letterSpacing = letterSpacing
        self.textAlignment = textAlignment
    }
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply font
        attributedString.addAttribute(
            .font,
            value: font,
            range: NSRange(location: 0, length: text.count)
        )
        
        // Apply color
        attributedString.addAttribute(
            .foregroundColor,
            value: color,
            range: NSRange(location: 0, length: text.count)
        )
        
        // Apply letter spacing
        if letterSpacing != 0 {
            attributedString.addAttribute(
                .kern,
                value: letterSpacing,
                range: NSRange(location: 0, length: text.count)
            )
        }
        
        // Create paragraph style for text alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: text.count)
        )
        
        uiView.attributedText = attributedString
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

