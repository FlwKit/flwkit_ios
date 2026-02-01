import SwiftUI
import UIKit

struct ChoiceBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let blockKey = block.key ?? ""
        
        // Restore selection from state
        var initialValues: Set<String> = []
        if let currentAnswer = state.answers[blockKey]?.value {
            if let singleValue = currentAnswer as? String {
                initialValues = [singleValue]
            } else if let arrayValue = currentAnswer as? [String] {
                initialValues = Set(arrayValue)
            }
        }
        
        let screenId = state.currentScreenId ?? ""
        return AnyView(
            ChoiceBlockView(
                block: block,
                theme: theme,
                initialValues: initialValues,
                onAnswer: onAnswer,
                onAction: onAction,
                screenId: screenId
            )
        )
    }
}

struct ChoiceBlockView: View {
    let block: Block
    let theme: Theme
    let initialValues: Set<String>
    let onAnswer: (String, Any) -> Void
    let onAction: (String, String?) -> Void
    let screenId: String
    
    @State private var selectedValues: Set<String>
    
    private let analytics = Analytics.shared
    
    init(block: Block, theme: Theme, initialValues: Set<String>, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void, screenId: String) {
        self.block = block
        self.theme = theme
        self.initialValues = initialValues
        self.onAnswer = onAnswer
        self.onAction = onAction
        self.screenId = screenId
        _selectedValues = State(initialValue: initialValues)
    }
    
    var body: some View {
        let tokens = theme.tokens
        let isMultiple = block.multiple ?? false
        let options = block.options ?? []
        let blockKey = block.key ?? ""
        
        // Get text color with opacity (default: theme's textPrimary)
        let textColor: Color = {
            let baseColor = block.color ?? tokens.textPrimary
            let opacity = block.opacity != nil ? block.opacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get background color with opacity (default: theme's surface) - for unselected state
        let backgroundColor: Color = {
            let baseColor = block.backgroundColor ?? tokens.surface
            let opacity = block.backgroundOpacity != nil ? block.backgroundOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get active background color with opacity (default: theme's primary) - for selected state
        let activeBackgroundColor: Color = {
            let baseColor = block.activeBackgroundColor ?? tokens.primary
            let opacity = block.activeBackgroundOpacity != nil ? block.activeBackgroundOpacity! / 100.0 : 1.0
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
        let optionFont: Font = {
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
                case .percentage:
                    // For choice blocks, percentage width is treated as full width
                    return nil // Will be handled by frame(maxWidth: .infinity)
                }
            }
            return nil // Default to full width (100%)
        }()
        
        // Get height (default: nil = auto height)
        let height: CGFloat? = block.choiceHeight.map { CGFloat($0) }
        
        // Get border width (default: 1)
        let borderWidth = block.borderWidth ?? 1.0
        
        // Get border radius (default: 8)
        let borderRadius = block.borderRadius ?? 8.0
        
        return VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = selectedValues.contains(option.value)
                let optionBackgroundColor = isSelected ? activeBackgroundColor : backgroundColor
                
                Button(action: {
                    let wasSelected = selectedValues.contains(option.value)
                    var willBeSelected = false
                    
                    if isMultiple {
                        // Multi mode: toggle selection
                        if wasSelected {
                            selectedValues.remove(option.value)
                            willBeSelected = false
                        } else {
                            selectedValues.insert(option.value)
                            willBeSelected = true
                        }
                        onAnswer(blockKey, Array(selectedValues))
                    } else {
                        // Single mode: only one option can be selected
                        if wasSelected {
                            selectedValues.removeAll()
                            willBeSelected = false
                    } else {
                        selectedValues = [option.value]
                            willBeSelected = true
                        }
                        onAnswer(blockKey, option.value)
                    }
                    
                    // Track choice selection
                    if !wasSelected && willBeSelected {
                        analytics.trackChoiceSelected(
                            choiceBlockId: blockKey,
                            optionValue: option.value,
                            optionLabel: option.label,
                            screenId: screenId,
                            isMultiSelect: isMultiple
                        )
                    }
                    
                    // Trigger action when option becomes selected (not when deselected)
                    // Map action names to match CTA action handling
                    if !wasSelected && willBeSelected {
                        let action = option.action ?? "next"
                        // Map "close" to "exit" and "submit" to "complete" to match CTA action handling
                        let mappedAction: String = {
                            switch action {
                            case "close":
                                return "exit"
                            case "submit":
                                return "complete"
                            default:
                                return action
                            }
                        }()
                        onAction(mappedAction, nil)
                    }
                }) {
                    HStack(spacing: 8) {
                        // Emoji or icon
                        if let emoji = option.emoji ?? option.icon {
                            Text(emoji)
                                .font(optionFont)
                        }
                        
                        Text(option.label)
                            .font(optionFont)
                            .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                            .multilineTextAlignment(textAlignment)
                            .foregroundColor(textColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: width, height: height)
                    .frame(maxWidth: width == nil ? .infinity : nil)
                    .background(optionBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(borderRadius))
                            .stroke(borderColor, lineWidth: CGFloat(borderWidth))
                    )
                    .cornerRadius(CGFloat(borderRadius))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.md.value)
    }
}
