import SwiftUI
import UIKit

struct TextInputBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let blockKey = block.key ?? ""
        let initialText = (state.answers[blockKey]?.value as? String) ?? ""
        
        return AnyView(
            TextInputBlockView(
                block: block,
                theme: theme,
                initialText: initialText,
                onAnswer: onAnswer
            )
        )
    }
}

struct TextInputBlockView: View {
    let block: Block
    let theme: Theme
    let initialText: String
    let onAnswer: (String, Any) -> Void
    
    @State private var text: String
    @FocusState private var isFocused: Bool
    
    init(block: Block, theme: Theme, initialText: String, onAnswer: @escaping (String, Any) -> Void) {
        self.block = block
        self.theme = theme
        self.initialText = initialText
        self.onAnswer = onAnswer
        _text = State(initialValue: initialText)
    }
    
    var body: some View {
        let tokens = theme.tokens
        let blockKey = block.key ?? ""
        let placeholder = block.placeholder ?? "Enter text..."
        let inputType = block.inputType ?? "text"
        
        // Get text color with opacity (default: theme's textPrimary)
        let textColor: Color = {
            let baseColor = block.color ?? tokens.textPrimary
            let opacity = block.opacity != nil ? block.opacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get background color with opacity (default: theme's surface)
        let backgroundColor: Color = {
            let baseColor = block.backgroundColor ?? tokens.surface
            let opacity = block.backgroundOpacity != nil ? block.backgroundOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get border color with opacity (default: theme's textSecondary)
        let borderColor: Color = {
            let baseColor = block.borderColor ?? tokens.textSecondary
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
        let inputFont: Font = {
            if isItalic {
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()
        
        // Get letter spacing (default: nil = no custom spacing)
        let letterSpacing: CGFloat? = block.spacing.map { CGFloat($0) }
        
        // Get text alignment (default: left)
        let textAlignment: TextAlignment = {
            switch block.align?.lowercased() {
            case "center":
                return .center
            case "right":
                return .trailing
            default:
                return .leading // Default to left
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
        let height: CGFloat? = block.inputHeight.map { CGFloat($0) }
        
        // Get border width (default: 1)
        let borderWidth = block.borderWidth ?? 1.0
        
        // Get border radius (default: 8)
        let borderRadius = block.borderRadius ?? 8.0
        
        // Get required (default: true)
        let isRequired = block.required ?? true
        
        return VStack(alignment: .leading, spacing: Spacing.sm.value) {
            if let label = block.title { // Using title as label
                HStack {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(tokens.textPrimaryColor)
                    if isRequired {
                        Text("*")
                            .font(.system(size: 14))
                            .foregroundColor(tokens.textSecondaryColor)
                    }
                }
            }
            
            TextField(placeholder, text: $text)
                .font(inputFont)
                .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                .multilineTextAlignment(textAlignment)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(width: width, height: height)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(borderRadius))
                        .stroke(borderColor, lineWidth: CGFloat(borderWidth))
                )
                .cornerRadius(CGFloat(borderRadius))
                .keyboardType(inputType == "email" ? .emailAddress : inputType == "number" ? .numberPad : .default)
                .autocapitalization(inputType == "email" ? .none : .sentences)
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    onAnswer(blockKey, newValue)
                }
                .onChange(of: isFocused) { focused in
                    // Optional: Change border color on focus
                    // This would require a @State variable for border color
                }
        }
        .padding(.horizontal, Spacing.md.value)
    }
}

