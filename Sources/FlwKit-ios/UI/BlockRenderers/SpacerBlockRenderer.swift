import SwiftUI

struct SpacerBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        // Height in pixels takes precedence over size token
        let finalHeight: CGFloat
        
        if let heightPixels = block.height {
            // Use custom height in pixels
            finalHeight = CGFloat(heightPixels)
        } else if let sizeToken = block.size {
            // Use size token (xs, sm, md, lg, xl)
            let spacing = Spacing(from: sizeToken) ?? .md
            finalHeight = spacing.value
        } else {
            // Default to medium spacing if neither is provided
            finalHeight = Spacing.md.value
        }
        
        return AnyView(
            Spacer()
                .frame(height: finalHeight)
        )
    }
}

