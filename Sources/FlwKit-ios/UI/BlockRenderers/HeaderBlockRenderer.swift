import SwiftUI

struct HeaderBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                if let title = block.title {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(tokens.textPrimaryColor)
                }
                if let subtitle = block.subtitle {
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(tokens.textSecondaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.lg.value)
        )
    }
}

