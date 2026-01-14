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
        
        // Convert Font.Weight to UIFont.Weight for UIFont usage
        let uiFontWeight: UIFont.Weight = {
            switch fontWeight {
            case .bold:
                return .bold
            case .semibold:
                return .semibold
            case .medium:
                return .medium
            case .regular:
                return .regular
            default:
                return .regular
            }
        }()
        
        // Get font style (default: normal)
        let isItalic = block.fontStyle?.lowercased() == "italic"
        
        // Get font size (default: 16)
        let fontSize = block.fontSize ?? 16.0
        
        // Create font with italic support for iOS 15
        let inputFont: Font = {
            if isItalic {
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
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
        
        // Get placeholder color (use text color with reduced opacity, or theme's textSecondary)
        let placeholderColor: Color = {
            // Use text color with reduced opacity for placeholder, or fallback to theme's textSecondary
            let baseColor = block.color ?? tokens.textSecondary
            let opacity = 0.6 // Placeholder typically has reduced opacity
            let color = Color(hex: baseColor)
            return color.opacity(opacity)
        }()
        
        return VStack(alignment: .leading, spacing: Spacing.sm.value) {
            if let label = block.title { // Using title as label
                HStack {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(textColor) // Use the same color as input text
                    if isRequired {
                        Text("*")
                            .font(.system(size: 14))
                            .foregroundColor(tokens.textSecondaryColor)
                    }
                }
            }
            
            CustomTextField(
                placeholder: placeholder,
                text: $text,
                font: inputFont,
                textColor: textColor,
                placeholderColor: placeholderColor,
                textAlignment: textAlignment,
                keyboardType: inputType == "email" ? .emailAddress : inputType == "number" ? .numberPad : .default,
                autocapitalization: inputType == "email" ? .none : .sentences,
                width: width,
                height: height,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: CGFloat(borderWidth),
                borderRadius: CGFloat(borderRadius),
                onTextChange: { newValue in
                    onAnswer(blockKey, newValue)
                }
            )
            .frame(width: width, height: height)
        }
        .padding(.horizontal, Spacing.md.value)
    }
}

// Custom TextField with placeholder color support for iOS 15
struct CustomTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let font: Font
    let textColor: Color
    let placeholderColor: Color
    let textAlignment: TextAlignment
    let keyboardType: UIKeyboardType
    let autocapitalization: UITextAutocapitalizationType
    let width: CGFloat?
    let height: CGFloat?
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let borderRadius: CGFloat
    let onTextChange: (String) -> Void
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = autocapitalization
        textField.returnKeyType = .done
        
        // Set placeholder color
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(placeholderColor),
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
        
        // Set text alignment
        switch textAlignment {
        case .leading:
            textField.textAlignment = .left
        case .center:
            textField.textAlignment = .center
        case .trailing:
            textField.textAlignment = .right
        }
        
        // Set padding
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        
        // Set background and border
        textField.backgroundColor = UIColor(backgroundColor)
        textField.layer.borderColor = UIColor(borderColor).cgColor
        textField.layer.borderWidth = borderWidth
        textField.layer.cornerRadius = borderRadius
        
        // Set frame constraints and store them in coordinator
        if let width = width {
            let widthConstraint = textField.widthAnchor.constraint(equalToConstant: width)
            widthConstraint.priority = UILayoutPriority(1000)
            widthConstraint.isActive = true
            context.coordinator.widthConstraint = widthConstraint
        }
        if let height = height {
            let heightConstraint = textField.heightAnchor.constraint(equalToConstant: height)
            heightConstraint.priority = UILayoutPriority(1000) // High priority to override intrinsic content size
            heightConstraint.isActive = true
            context.coordinator.heightConstraint = heightConstraint
        }
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        
        // Update width constraint if needed
        if let width = width, let widthConstraint = context.coordinator.widthConstraint {
            widthConstraint.constant = width
        }
        
        // Update height constraint if needed
        if let height = height {
            if let heightConstraint = context.coordinator.heightConstraint {
                heightConstraint.constant = height
            } else {
                // Create height constraint if it doesn't exist
                let heightConstraint = uiView.heightAnchor.constraint(equalToConstant: height)
                heightConstraint.priority = UILayoutPriority(1000) // High priority to override intrinsic content size
                heightConstraint.isActive = true
                context.coordinator.heightConstraint = heightConstraint
            }
        } else {
            // Remove height constraint if height is nil
            if let heightConstraint = context.coordinator.heightConstraint {
                heightConstraint.isActive = false
                context.coordinator.heightConstraint = nil
            }
        }
        
        // Update text color
        uiView.textColor = UIColor(textColor)
        
        // Update font
        if let swiftUIFont = font as? Font {
            // Convert Font to UIFont
            let uiFont = UIFont.systemFont(ofSize: 16) // Default, will be updated below
            uiView.font = uiFont
        }
        
        // Update placeholder color
        uiView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(placeholderColor),
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
        
        // Update background and border
        uiView.backgroundColor = UIColor(backgroundColor)
        uiView.layer.borderColor = UIColor(borderColor).cgColor
        uiView.layer.borderWidth = borderWidth
        uiView.layer.cornerRadius = borderRadius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: CustomTextField
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.onTextChange(textField.text ?? "")
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Focus handling is done internally by UITextField
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            // Focus handling is done internally by UITextField
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

