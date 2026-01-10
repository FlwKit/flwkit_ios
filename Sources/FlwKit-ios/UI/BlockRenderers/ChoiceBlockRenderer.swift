import SwiftUI

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
        
        return AnyView(
            ChoiceBlockView(
                block: block,
                theme: theme,
                initialValues: initialValues,
                onAnswer: onAnswer
            )
        )
    }
}

struct ChoiceBlockView: View {
    let block: Block
    let theme: Theme
    let initialValues: Set<String>
    let onAnswer: (String, Any) -> Void
    
    @State private var selectedValues: Set<String>
    
    init(block: Block, theme: Theme, initialValues: Set<String>, onAnswer: @escaping (String, Any) -> Void) {
        self.block = block
        self.theme = theme
        self.initialValues = initialValues
        self.onAnswer = onAnswer
        _selectedValues = State(initialValue: initialValues)
    }
    
    var body: some View {
        let tokens = theme.tokens
        let isMultiple = block.multiple ?? false
        let options = block.options ?? []
        let blockKey = block.key ?? ""
        
        return VStack(spacing: Spacing.sm.value) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                ChoiceOptionView(
                    option: option,
                    isSelected: selectedValues.contains(option.value),
                    isMultiple: isMultiple,
                    theme: theme,
                    style: block.style ?? "list"
                ) {
                    if isMultiple {
                        if selectedValues.contains(option.value) {
                            selectedValues.remove(option.value)
                        } else {
                            selectedValues.insert(option.value)
                        }
                        onAnswer(blockKey, Array(selectedValues))
                    } else {
                        selectedValues = [option.value]
                        onAnswer(blockKey, option.value)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md.value)
    }
}

struct ChoiceOptionView: View {
    let option: ChoiceOption
    let isSelected: Bool
    let isMultiple: Bool
    let theme: Theme
    let style: String
    let onTap: () -> Void
    
    var body: some View {
        let tokens = theme.tokens
        
        Button(action: onTap) {
            HStack {
                if isMultiple {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? tokens.primaryColor : tokens.textSecondaryColor)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? tokens.primaryColor : tokens.textSecondaryColor)
                }
                
                Text(option.label)
                    .font(.system(size: 16))
                    .foregroundColor(tokens.textPrimaryColor)
                
                Spacer()
            }
            .padding(Spacing.md.value)
            .background(
                style == "cards" ? tokens.surfaceColor : Color.clear
            )
            .overlay(
                style == "cards" && isSelected ?
                RoundedRectangle(cornerRadius: tokens.cornerRadius)
                    .stroke(tokens.primaryColor, lineWidth: 2)
                : nil
            )
            .cornerRadius(style == "cards" ? tokens.cornerRadius : 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

