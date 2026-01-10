import SwiftUI

struct TestimonialBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let quote = block.quote ?? ""
        let author = block.author ?? ""
        
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                Text("\"\(quote)\"")
                    .font(.system(size: 16, style: .italic))
                    .foregroundColor(tokens.textPrimaryColor)
                
                if !author.isEmpty {
                    Text("— \(author)")
                        .font(.system(size: 14))
                        .foregroundColor(tokens.textSecondaryColor)
                }
            }
            .padding(Spacing.md.value)
            .background(tokens.surfaceColor)
            .cornerRadius(tokens.cornerRadius)
            .padding(.horizontal, Spacing.md.value)
        )
    }
}

