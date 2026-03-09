import SwiftUI
import UIKit

struct DescriptionBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let text = block.text ?? ""

        let textColor = Color.resolveDescriptionColor(
            color: block.color,
            opacity: block.opacity,
            themeTextSecondary: tokens.textSecondary
        )

        let fontWeight: Font.Weight = {
            switch block.fontWeight?.lowercased() {
            case "bold":
                return .bold
            default:
                return .regular
            }
        }()

        let uiFontWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
        let isItalic = block.fontStyle?.lowercased() == "italic"
        let fontSize = block.fontSize ?? 16.0
        let letterSpacing = CGFloat(block.spacing ?? 0)

        let descriptionFont: Font = {
            if isItalic {
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()

        let textAlignment: TextAlignment = {
            switch block.align?.lowercased() {
            case "center":
                return .center
            case "right":
                return .trailing
            default:
                return .leading
            }
        }()

        let frameAlignment: Alignment = {
            switch textAlignment {
            case .center:
                return .center
            case .trailing:
                return .trailing
            default:
                return .leading
            }
        }()

        return AnyView(
            Group {
                if #available(iOS 16.0, *) {
                    Text(text)
                        .font(descriptionFont)
                        .foregroundColor(textColor)
                        .kerning(letterSpacing)
                        .multilineTextAlignment(textAlignment)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    let nsTextAlignment: NSTextAlignment = {
                        switch textAlignment {
                        case .center:
                            return .center
                        case .trailing:
                            return .right
                        default:
                            return .left
                        }
                    }()

                    let uiFont: UIFont = {
                        if isItalic {
                            let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                            if let descriptor = descriptor {
                                return UIFont(descriptor: descriptor, size: CGFloat(fontSize))
                            }
                        }
                        return UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight)
                    }()

                    TextWithLetterSpacing(
                        text: text,
                        font: uiFont,
                        color: UIColor(textColor),
                        letterSpacing: letterSpacing,
                        textAlignment: nsTextAlignment
                    )
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.md.value)
        )
    }
}
