import SwiftUI

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
        let placeholder = block.placeholder ?? ""
        let inputType = block.inputType ?? "text"
        
        return VStack(alignment: .leading, spacing: Spacing.sm.value) {
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(Spacing.md.value)
                .background(tokens.surfaceColor)
                .foregroundColor(tokens.textPrimaryColor)
                .cornerRadius(tokens.cornerRadius)
                .keyboardType(inputType == "email" ? .emailAddress : inputType == "number" ? .numberPad : .default)
                .autocapitalization(inputType == "email" ? .none : .sentences)
                .onChange(of: text) { newValue in
                    onAnswer(blockKey, newValue)
                }
        }
        .padding(.horizontal, Spacing.md.value)
    }
}

