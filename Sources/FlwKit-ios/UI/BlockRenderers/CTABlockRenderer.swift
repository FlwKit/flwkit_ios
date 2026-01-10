import SwiftUI

struct CTABlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        
        return AnyView(
            VStack(spacing: Spacing.sm.value) {
                if let primary = block.primary {
                    Button(action: {
                        onAction(primary.action, primary.target)
                    }) {
                        Text(primary.label)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(tokens.isFilledButton ? .white : tokens.primaryColor)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md.value)
                            .background(tokens.isFilledButton ? tokens.primaryColor : Color.clear)
                            .overlay(
                                !tokens.isFilledButton ?
                                RoundedRectangle(cornerRadius: tokens.cornerRadius)
                                    .stroke(tokens.primaryColor, lineWidth: 2)
                                : nil
                            )
                            .cornerRadius(tokens.cornerRadius)
                    }
                }
                
                if let secondary = block.secondary {
                    Button(action: {
                        onAction(secondary.action, secondary.target)
                    }) {
                        Text(secondary.label)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(tokens.textSecondaryColor)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md.value)
                    }
                }
            }
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.md.value)
        )
    }
}

