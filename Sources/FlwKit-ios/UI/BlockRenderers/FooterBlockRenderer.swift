import SwiftUI

struct FooterBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let text = block.text ?? ""
        
        return AnyView(
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(tokens.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md.value)
                .padding(.vertical, Spacing.sm.value)
        )
    }
}

