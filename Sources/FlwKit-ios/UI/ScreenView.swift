import SwiftUI

struct ScreenView: View {
    let screen: Screen
    let theme: Theme
    @Binding var state: FlowState
    let onAnswer: (String, Any) -> Void
    let onAction: (String, String?) -> Void
    
    var body: some View {
        // Resolve background configuration (screen override → theme default)
        let backgroundConfig = BackgroundResolver.resolveBackground(screen: screen, theme: theme)
        
        ZStack {
            // Background layer
            BackgroundView(config: backgroundConfig)
                .ignoresSafeArea()
            
            // Content layer
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(screen.blocks.enumerated()), id: \.offset) { index, block in
                        let isLast = index == screen.blocks.count - 1
                        let spacing = screen.spacing ?? 16.0 // Default to 16px
                        let bottomSpacing = isLast ? 0.0 : spacing
                        
                        BlockRendererRegistry.shared.render(
                            block: block,
                            theme: theme,
                            state: state,
                            onAnswer: { key, value in
                                handleAnswer(key: key, value: value)
                            },
                            onAction: { action, target in
                                handleAction(action: action, target: target)
                            }
                        )
                        .padding(.bottom, bottomSpacing)
                    }
                }
            }
        }
    }
    
    private func handleAnswer(key: String, value: Any) {
        state.answers[key] = AnyCodable(value)
        onAnswer(key, value)
    }
    
    private func handleAction(action: String, target: String?) {
        onAction(action, target)
    }
}

