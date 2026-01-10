import SwiftUI

struct ScreenView: View {
    let screen: Screen
    let theme: Theme
    @Binding var state: FlowState
    let onAnswer: (String, Any) -> Void
    let onAction: (String, String?) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(screen.blocks.enumerated()), id: \.offset) { index, block in
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
                }
            }
        }
        .background(theme.tokens.backgroundColor)
    }
    
    private func handleAnswer(key: String, value: Any) {
        state.answers[key] = AnyCodable(value)
        onAnswer(key, value)
    }
    
    private func handleAction(action: String, target: String?) {
        onAction(action, target)
    }
}

