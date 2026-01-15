import SwiftUI

protocol BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView
}

class BlockRendererRegistry {
    static let shared = BlockRendererRegistry()
    
    private var renderers: [String: BlockRenderer] = [:]
    
    private init() {
        registerDefaultRenderers()
    }
    
    func register(_ type: String, renderer: BlockRenderer) {
        renderers[type] = renderer
    }
    
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        guard let renderer = renderers[block.type] else {
            return AnyView(UnsupportedBlockView(blockType: block.type))
        }
        return renderer.render(block: block, theme: theme, state: state, onAnswer: onAnswer, onAction: onAction)
    }
    
    private func registerDefaultRenderers() {
        register("header", renderer: HeaderBlockRenderer())
        register("media", renderer: MediaBlockRenderer())
        register("choice", renderer: ChoiceBlockRenderer())
        register("text_input", renderer: TextInputBlockRenderer())
        register("slider", renderer: SliderBlockRenderer())
        register("cta", renderer: CTABlockRenderer())
        register("spacer", renderer: SpacerBlockRenderer())
        register("benefits_list", renderer: BenefitsListBlockRenderer())
        register("testimonial", renderer: TestimonialBlockRenderer())
        register("footer", renderer: FooterBlockRenderer())
        register("progress_bar", renderer: ProgressBarBlockRenderer())
    }
}

// MARK: - Unsupported Block View

struct UnsupportedBlockView: View {
    let blockType: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text("Unsupported block type: \(blockType)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

