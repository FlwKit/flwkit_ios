import SwiftUI

struct SwipeCardsBlockRenderer: BlockRenderer {
    func render(
        block: Block,
        theme: Theme,
        state: FlowState,
        onAnswer: @escaping (String, Any) -> Void,
        onAction: @escaping (String, String?) -> Void
    ) -> AnyView {
        AnyView(
            SwipeCardsBlockView(block: block, theme: theme) { selectedCardIDs in
                if let key = block.key, !key.isEmpty {
                    onAnswer(key, selectedCardIDs)
                }
                if (block.onComplete ?? "next_screen") == "complete_flow" {
                    onAction("complete", nil)
                } else {
                    onAction("next", nil)
                }
            }
        )
    }
}

private struct SwipeCardsBlockView: View {
    let block: Block
    let theme: Theme
    let onComplete: ([String]) -> Void

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var agreedCardIDs: [String] = []

    var cards: [SwipeCard] { block.cards ?? [] }

    var body: some View {
        VStack(spacing: 20) {
            Text(block.headline ?? "Do any of these sound familiar?")
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.tokens.textPrimaryColor)

            ZStack {
                ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { index, card in
                    if index >= currentIndex {
                        cardView(card: card)
                            .offset(index == currentIndex ? dragOffset : .zero)
                            .scaleEffect(index == currentIndex ? 1.0 : 0.94)
                            .rotationEffect(.degrees(index == currentIndex ? Double(dragOffset.width / 24) : 0))
                            .zIndex(Double(cards.count - index))
                            .gesture(index == currentIndex ? dragGesture : nil)
                    }
                }
            }
            .frame(height: 210)

            HStack(spacing: 24) {
                Button("Not me") {
                    swipe(agreed: false)
                }
                .foregroundColor(theme.tokens.textSecondaryColor)

                Button("That's me →") {
                    swipe(agreed: true)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.tokens.textPrimaryColor)
            }
        }
        .padding(.horizontal, Spacing.md.value)
    }

    private func cardView(card: SwipeCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.emoji ?? "🙂")
                .font(.system(size: 30))
            Text(card.text)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.tokens.textPrimaryColor)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(20)
        .background(theme.tokens.surfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.tokens.textSecondaryColor.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func swipe(agreed: Bool) {
        guard currentIndex < cards.count else { return }
        let card = cards[currentIndex]
        if agreed {
            agreedCardIDs.append(card.id)
        }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.85)) {
            dragOffset = CGSize(width: agreed ? 420 : -420, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            currentIndex += 1
            dragOffset = .zero
            if currentIndex >= cards.count {
                onComplete(agreedCardIDs)
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if abs(value.translation.width) > 90 {
                    swipe(agreed: value.translation.width > 0)
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
    }
}
