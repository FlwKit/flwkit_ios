import SwiftUI

struct HeaderBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        
        // Get alignment (default: left)
        let alignment: HorizontalAlignment = {
            switch block.align?.lowercased() {
            case "center":
                return .center
            case "right":
                return .trailing
            default:
                return .leading // Default to left
            }
        }()
        
        // Get color (default: theme's textPrimary)
        let baseColor = block.color ?? tokens.textPrimary
        
        // Get opacity (default: 100% = 1.0)
        let opacityValue = block.opacity != nil ? block.opacity! / 100.0 : 1.0
        
        // Convert hex color to Color with opacity
        let textColor: Color = {
            let color = Color(hex: baseColor)
            if opacityValue < 1.0 {
                return color.opacity(opacityValue)
            }
            return color
        }()
        
        // Get font weight (default: bold)
        let fontWeight: Font.Weight = {
            switch block.fontWeight?.lowercased() {
            case "normal":
                return .regular
            default:
                return .bold // Default to bold
            }
        }()
        
        // Get font style (default: normal)
        let isItalic = block.fontStyle?.lowercased() == "italic"
        
        // Get font size (default: 24)
        let fontSize = block.fontSize ?? 24.0
        
        // Get letter spacing (default: nil = no custom spacing)
        let letterSpacing: CGFloat? = block.spacing.map { CGFloat($0) }
        
        return AnyView(
            VStack(alignment: alignment, spacing: Spacing.sm.value) {
                if let title = block.title {
                    Text(title)
                        .font(.system(size: CGFloat(fontSize), weight: fontWeight))
                        .italic(isItalic)
                        .foregroundColor(textColor)
                        .tracking(letterSpacing ?? 0)
                }
                if let subtitle = block.subtitle {
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(tokens.textSecondaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.lg.value)
        )
    }
}

