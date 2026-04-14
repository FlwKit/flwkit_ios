import SwiftUI

struct ProcessingAnimationBlockRenderer: BlockRenderer {
    func render(
        block: Block,
        theme: Theme,
        state: FlowState,
        onAnswer: @escaping (String, Any) -> Void,
        onAction: @escaping (String, String?) -> Void
    ) -> AnyView {
        AnyView(ProcessingAnimationBlockView(block: block, theme: theme) {
            onAction("next", nil)
        })
    }
}

private struct ProcessingAnimationBlockView: View {
    let block: Block
    let theme: Theme
    let onComplete: () -> Void

    @State private var hasScheduled = false
    @State private var isSpinning = false

    var body: some View {
        let items = Array((block.processingItems ?? []).prefix(3))
        let borderColor = theme.tokens.textSecondaryColor.opacity(0.40)
        let cardBackground = theme.tokens.surfaceColor.opacity(0.88)

        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SpinnerRing(color: theme.tokens.primaryColor, isSpinning: isSpinning)
                    .frame(width: 32, height: 32)
                    .padding(.bottom, 12)

                Text(block.headline ?? "Building your experience...")
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.tokens.textPrimaryColor)
                    .padding(.bottom, 4)

                Text(block.subHeadline ?? "This takes just a moment")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.tokens.textSecondaryColor)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        let itemOpacity = 0.7 + (Double(index) * 0.15)
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.tokens.primaryColor.opacity(0.6 + (Double(index) * 0.15)))
                            Text(item)
                                .font(.system(size: 14))
                                .foregroundColor(theme.tokens.textPrimaryColor.opacity(itemOpacity))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .padding(.horizontal, Spacing.md.value)
        .onAppear {
            isSpinning = true
            scheduleAnimationIfNeeded()
        }
    }

    private func scheduleAnimationIfNeeded() {
        guard !hasScheduled else { return }
        hasScheduled = true

        let duration = max(1.0, block.durationSeconds ?? 3.0)

        if block.autoAdvance ?? true {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                onComplete()
            }
        }
    }
}

private struct SpinnerRing: View {
    let color: Color
    let isSpinning: Bool

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(
                color.opacity(0.4),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .overlay(
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            )
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(
                .linear(duration: 0.9).repeatForever(autoreverses: false),
                value: isSpinning
            )
    }
}
