import SwiftUI

struct BenefitsListBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let items = block.items ?? []
        
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: Spacing.sm.value) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(tokens.primaryColor)
                            .font(.system(size: 20))
                        
                        Text(item)
                            .font(.system(size: 16))
                            .foregroundColor(tokens.textPrimaryColor)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Spacing.md.value)
        )
    }
}

