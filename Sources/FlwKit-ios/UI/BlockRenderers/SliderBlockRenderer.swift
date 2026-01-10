import SwiftUI

struct SliderBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let blockKey = block.key ?? ""
        let minValue = block.min ?? 0
        let maxValue = block.max ?? 100
        let defaultValue = block.defaultValue ?? minValue
        
        // Initialize or restore from state
        var initialValue: Double = defaultValue
        if let currentAnswer = state.answers[blockKey]?.value as? Double {
            initialValue = currentAnswer
        } else if let currentAnswer = state.answers[blockKey]?.value as? Int {
            initialValue = Double(currentAnswer)
        }
        
        return AnyView(
            SliderBlockView(
                block: block,
                theme: theme,
                initialValue: initialValue,
                onAnswer: onAnswer
            )
        )
    }
}

struct SliderBlockView: View {
    let block: Block
    let theme: Theme
    let initialValue: Double
    let onAnswer: (String, Any) -> Void
    
    @State private var value: Double
    
    init(block: Block, theme: Theme, initialValue: Double, onAnswer: @escaping (String, Any) -> Void) {
        self.block = block
        self.theme = theme
        self.initialValue = initialValue
        self.onAnswer = onAnswer
        _value = State(initialValue: initialValue)
    }
    
    var body: some View {
        let tokens = theme.tokens
        let blockKey = block.key ?? ""
        let minValue = block.min ?? 0
        let maxValue = block.max ?? 100
        let stepValue = block.step ?? 1
        
        return VStack(spacing: Spacing.md.value) {
            HStack {
                Text("\(Int(value))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tokens.textPrimaryColor)
                Spacer()
            }
            
            Slider(value: $value, in: minValue...maxValue, step: stepValue)
                .accentColor(tokens.primaryColor)
                .onChange(of: value) { newValue in
                    onAnswer(blockKey, newValue)
                }
            
            HStack {
                Text("\(Int(minValue))")
                    .font(.caption)
                    .foregroundColor(tokens.textSecondaryColor)
                Spacer()
                Text("\(Int(maxValue))")
                    .font(.caption)
                    .foregroundColor(tokens.textSecondaryColor)
            }
        }
        .padding(.horizontal, Spacing.md.value)
    }
}

