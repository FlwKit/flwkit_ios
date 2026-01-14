import SwiftUI
import UIKit // Required for UIFont

struct BenefitsListBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let items = block.items ?? []
        
        // Get icon color (default: theme primary)
        let iconColor: Color = {
            if let iconColorHex = block.iconColor {
                return Color(hex: iconColorHex)
            }
            return tokens.primaryColor
        }()
        
        // Get icon size (default: 16, clamped between 8-64)
        let iconSize: CGFloat = {
            if let size = block.iconSize {
                return CGFloat(max(8, min(64, size)))
            }
            return 16
        }()
        
        // Get text color with opacity (default: theme textPrimary)
        let textColor: Color = {
            let baseColor = block.color ?? tokens.textPrimary
            let opacity = block.opacity != nil ? block.opacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get font weight (default: normal)
        let fontWeight: Font.Weight = {
            switch block.fontWeight?.lowercased() {
            case "bold": return .bold
            default: return .regular // Default to normal
            }
        }()
        
        // Get font style (default: normal)
        let isItalic = block.fontStyle?.lowercased() == "italic"
        
        // Get font size (default: 16)
        let fontSize = block.fontSize ?? 16.0
        
        // Create font with italic support for iOS 15
        let itemFont: Font = {
            if isItalic {
                let uiFontWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()
        
        // Get letter spacing (default: nil = no custom spacing)
        let letterSpacing: CGFloat? = block.spacing.map { CGFloat($0) }
        
        // Get alignment (default: left)
        let alignment: HorizontalAlignment = {
            switch block.align?.lowercased() {
            case "center": return .center
            case "right": return .trailing
            default: return .leading // Default to left
            }
        }()
        
        // Convert HorizontalAlignment to Alignment for frame modifier
        let frameAlignment: Alignment = {
            switch alignment {
            case .leading: return .leading
            case .center: return .center
            case .trailing: return .trailing
            default: return .leading
            }
        }()
        
        return AnyView(
            VStack(alignment: alignment, spacing: 0) {
                // Title if present
                if let title = block.title {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(tokens.textPrimaryColor)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                        .padding(.bottom, Spacing.md.value)
                }
                
                // Benefits list items
                VStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .center, spacing: 8) {
                            // Spacer for center/right alignment
                            if alignment == .center || alignment == .trailing {
                                Spacer()
                            }
                            
                            // Icon
                            IconView(
                                iconName: block.icon,
                                color: iconColor,
                                size: iconSize
                            )
                            
                            // Text
                            Text(item)
                                .font(itemFont)
                                .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                                .multilineTextAlignment(alignment.toTextAlignment())
                                .foregroundColor(textColor)
                            
                            // Spacer for left/center alignment
                            if alignment == .leading || alignment == .center {
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md.value)
        )
    }
}

// Extension to convert HorizontalAlignment to TextAlignment
extension HorizontalAlignment {
    func toTextAlignment() -> TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
}
