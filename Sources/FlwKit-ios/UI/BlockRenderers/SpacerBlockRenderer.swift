import SwiftUI

struct SpacerBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        // Height takes precedence over size
        let finalHeight: CGFloat
        
        if let height = block.height {
            // Use custom height in pixels
            finalHeight = CGFloat(height)
        } else if let sizeString = block.size,
                  let spacing = Spacing(from: sizeString) {
            // Use token-based size
            finalHeight = spacing.value
        } else {
            // Default fallback (shouldn't happen if backend validates, but handle gracefully)
            finalHeight = Spacing.md.value
        }
        
        return AnyView(
            Spacer()
                .frame(height: finalHeight)
        )
    }
}

