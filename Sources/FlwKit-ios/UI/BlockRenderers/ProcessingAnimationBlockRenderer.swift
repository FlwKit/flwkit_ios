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

    @State private var visibleItems: [String] = []
    @State private var hasScheduled = false

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)

            Text(block.headline ?? "Building your experience...")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.tokens.textPrimaryColor)

            Text(block.subHeadline ?? "This takes just a moment")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.tokens.textSecondaryColor)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(visibleItems, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.tokens.primaryColor)
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(theme.tokens.textPrimaryColor)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        }
        .padding(.horizontal, Spacing.md.value)
        .onAppear {
            scheduleAnimationIfNeeded()
        }
    }

    private func scheduleAnimationIfNeeded() {
        guard !hasScheduled else { return }
        hasScheduled = true

        let items = block.processingItems ?? []
        let duration = max(1.0, block.durationSeconds ?? 3.0)
        let interval = duration / Double(max(1, items.count + 1))

        for (index, item) in items.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(index + 1)) {
                withAnimation(.easeIn(duration: 0.25)) {
                    visibleItems.append(item)
                }
            }
        }

        if block.autoAdvance ?? true {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                onComplete()
            }
        }
    }
}
