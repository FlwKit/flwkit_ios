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
    var activeCard: SwipeCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    var nextCard: SwipeCard? {
        let index = currentIndex + 1
        guard index < cards.count else { return nil }
        return cards[index]
    }

    var body: some View {
        let borderColor = theme.tokens.textSecondaryColor.opacity(0.40)
        let cardBackground = theme.tokens.surfaceColor.opacity(0.88)

        VStack(spacing: 0) {
            Text(block.headline ?? "Do any of these sound familiar?")
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.tokens.textPrimaryColor)
                .padding(.bottom, 16)

            ZStack(alignment: .top) {
                if let nextCard {
                    SwipeStackCardView(
                        text: cardText(nextCard),
                        textColor: theme.tokens.textSecondaryColor,
                        backgroundColor: theme.tokens.backgroundColor,
                        borderColor: borderColor,
                        horizontalPadding: 16,
                        verticalPadding: 16,
                        font: .system(size: 14),
                        cornerRadius: 16
                    )
                    .opacity(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.horizontal, 10)
                }

                SwipeStackCardView(
                    text: cardText(activeCard),
                    textColor: theme.tokens.textPrimaryColor,
                    backgroundColor: theme.tokens.backgroundColor,
                    borderColor: theme.tokens.textSecondaryColor.opacity(0.50),
                    horizontalPadding: 20,
                    verticalPadding: 20,
                    font: .system(size: 16, weight: .medium),
                    cornerRadius: 16
                )
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 3)
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width / 24)))
                .gesture(dragGesture)
            }
            .frame(height: 176)

            HStack {
                Button(action: { swipe(agreed: false) }) {
                    Text("← Not me")
                        .font(.system(size: 12))
                        .foregroundColor(theme.tokens.textSecondaryColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { swipe(agreed: true) }) {
                    Text("That's me →")
                        .font(.system(size: 12))
                        .foregroundColor(theme.tokens.textSecondaryColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
        }
        .padding(16)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.horizontal, Spacing.md.value)
    }

    private func cardText(_ card: SwipeCard?) -> String {
        if let card {
            let text = "\(card.emoji ?? "") \(card.text)".trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? "Card text" : text
        }
        return "😩 I never have time to stay consistent"
    }

    private func swipe(agreed: Bool) {
        guard currentIndex < cards.count else {
            onComplete(agreedCardIDs)
            return
        }

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

private struct SwipeStackCardView: View {
    let text: String
    let textColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let font: Font
    let cornerRadius: CGFloat

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(textColor)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
    }
}
