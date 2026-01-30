import SwiftUI
import UIKit

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
        
        // Create font with italic support for iOS 15
        let titleFont: Font = {
            if isItalic {
                // Use custom font descriptor for italic on iOS 15
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight == .bold ? .bold : .regular).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()
        
        // Resolve subtitle styling
        let subtitleColor: Color = {
            Color.resolveSubtitleColor(
                subtitleColor: block.subtitleColor,
                subtitleOpacity: block.subtitleOpacity,
                themeTextSecondary: tokens.textSecondary
            )
        }()
        
        let subtitleFontSize = block.subtitleFontSize ?? 16.0
        
        // Resolve subtitle alignment (inherits from block.align if not set)
        let subtitleAlignString = block.subtitleAlign ?? block.align ?? "left"
        let subtitleAlignment: TextAlignment = {
            switch subtitleAlignString.lowercased() {
            case "center":
                return .center
            case "right":
                return .trailing
            default:
                return .leading
            }
        }()
        
        // Convert subtitle alignment to Alignment for frame
        let subtitleFrameAlignment: Alignment = {
            switch subtitleAlignString.lowercased() {
            case "center":
                return .center
            case "right":
                return .trailing
            default:
                return .leading
            }
        }()
        
        let subtitleSpacing: CGFloat = CGFloat(block.subtitleSpacing ?? 0)
        
        return AnyView(
            VStack(alignment: alignment, spacing: Spacing.sm.value) {
                if let title = block.title {
                    if #available(iOS 16.0, *) {
                        Text(title)
                            .font(titleFont)
                            .foregroundColor(textColor)
                            .kerning(letterSpacing ?? 0)
                    } else {
                        // iOS 15: Use TextWithLetterSpacing for letter spacing support
                        let uiFont: UIFont = {
                            if isItalic {
                                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight == .bold ? .bold : .regular).fontDescriptor.withSymbolicTraits(.traitItalic)
                                if let descriptor = descriptor {
                                    return UIFont(descriptor: descriptor, size: CGFloat(fontSize))
                                }
                            }
                            return UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight == .bold ? .bold : .regular)
                        }()
                        let titleNSAlignment: NSTextAlignment = {
                            switch block.align?.lowercased() {
                            case "center": return .center
                            case "right": return .right
                            default: return .left
                            }
                        }()
                        TextWithLetterSpacing(
                            text: title,
                            font: uiFont,
                            color: UIColor(textColor),
                            letterSpacing: letterSpacing ?? 0,
                            textAlignment: titleNSAlignment
                        )
                    }
                }
                if let subtitle = block.subtitle {
                    if #available(iOS 16.0, *) {
                        Text(subtitle)
                            .font(.system(size: CGFloat(subtitleFontSize)))
                            .foregroundColor(subtitleColor)
                            .multilineTextAlignment(subtitleAlignment)
                            .kerning(subtitleSpacing)
                            .frame(maxWidth: .infinity, alignment: subtitleFrameAlignment)
                    } else {
                        // iOS 15: Use TextWithLetterSpacing for letter spacing support
                        let subtitleUIFont = UIFont.systemFont(ofSize: CGFloat(subtitleFontSize))
                        let subtitleNSAlignment: NSTextAlignment = {
                            switch subtitleAlignment {
                            case .center: return .center
                            case .trailing: return .right
                            default: return .left
                            }
                        }()
                        TextWithLetterSpacing(
                            text: subtitle,
                            font: subtitleUIFont,
                            color: UIColor(subtitleColor),
                            letterSpacing: subtitleSpacing,
                            textAlignment: subtitleNSAlignment
                        )
                        .frame(maxWidth: .infinity, alignment: subtitleFrameAlignment)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.lg.value)
        )
    }
}

