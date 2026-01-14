import SwiftUI
import UIKit

struct CTABlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        
        // Get text color with opacity (default: white "#FFFFFF")
        let textColor: Color = {
            let baseColor = block.color ?? "#FFFFFF" // Default to white for CTA
            let opacity = block.opacity != nil ? block.opacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get background color with opacity (default: theme's primary)
        let backgroundColor: Color = {
            let baseColor = block.backgroundColor ?? tokens.primary
            let opacity = block.backgroundOpacity != nil ? block.backgroundOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get border color with opacity (default: theme's primary)
        let borderColor: Color = {
            let baseColor = block.borderColor ?? tokens.primary
            let opacity = block.borderOpacity != nil ? block.borderOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get font weight (default: normal)
        let fontWeight: Font.Weight = {
            switch block.fontWeight?.lowercased() {
            case "bold":
                return .bold
            default:
                return .regular // Default to normal
            }
        }()
        
        // Get font style (default: normal)
        let isItalic = block.fontStyle?.lowercased() == "italic"
        
        // Get font size (default: 16)
        let fontSize = block.fontSize ?? 16.0
        
        // Create font with italic support for iOS 15
        let buttonFont: Font = {
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
        
        // Get text alignment (default: center for CTA)
        let textAlignment: TextAlignment = {
            switch block.align?.lowercased() {
            case "left":
                return .leading
            case "right":
                return .trailing
            default:
                return .center // Default to center for CTA
            }
        }()
        
        // Get width
        let width: CGFloat? = {
            if let mediaWidth = block.width {
                switch mediaWidth {
                case .auto:
                    return nil // Auto width
                case .fixed(let value):
                    return CGFloat(value)
                }
            }
            return nil // Default to full width (100%)
        }()
        
        // Get height (default: nil = auto height)
        let height: CGFloat? = block.ctaHeight.map { CGFloat($0) }
        
        // Get border width
        // Primary: defaults to 0, Secondary: defaults to 1
        let primaryBorderWidth = block.borderWidth ?? 0.0
        let secondaryBorderWidth = block.borderWidth ?? 1.0
        
        // Get border radius (default: 8)
        let borderRadius = block.borderRadius ?? 8.0
        
        // Get sticky (default: true)
        let isSticky = block.sticky ?? true
        
        return AnyView(
            VStack(spacing: 12) {
                if let primary = block.primary {
                    Button(action: {
                        onAction(primary.action, primary.target)
                    }) {
                        Text(primary.label)
                            .font(buttonFont)
                            .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                            .multilineTextAlignment(textAlignment)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .frame(width: width, height: height)
                            .frame(maxWidth: width == nil ? .infinity : nil)
                            .background(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(borderRadius))
                                    .stroke(borderColor, lineWidth: CGFloat(primaryBorderWidth))
                            )
                            .cornerRadius(CGFloat(borderRadius))
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
                
                if let secondary = block.secondary {
                    Button(action: {
                        onAction(secondary.action, secondary.target)
                    }) {
                        Text(secondary.label)
                            .font(buttonFont)
                            .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                            .multilineTextAlignment(textAlignment)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .frame(width: width, height: height)
                            .frame(maxWidth: width == nil ? .infinity : nil)
                            .background(Color.clear) // Transparent background for secondary
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(borderRadius))
                                    .stroke(borderColor, lineWidth: CGFloat(secondaryBorderWidth))
                            )
                            .cornerRadius(CGFloat(borderRadius))
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
            }
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.md.value)
            .frame(maxWidth: .infinity)
            .background(isSticky ? tokens.surfaceColor : Color.clear)
        )
    }
}
