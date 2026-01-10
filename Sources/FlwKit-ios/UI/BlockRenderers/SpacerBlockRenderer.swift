import SwiftUI

struct SpacerBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let heightString = block.height ?? "md"
        let spacing = Spacing(from: heightString) ?? .md
        
        return AnyView(
            Spacer()
                .frame(height: spacing.value)
        )
    }
}

