import SwiftUI

struct PersonalizationBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let items = block.personalizationItems ?? []
        let blockKey = block.key
        let blockId = block.key ?? "personalization"
        let analytics = Analytics.shared
        let screenId = state.currentScreenId ?? ""

        let onComplete: () -> Void = {
            analytics.track("personalization_complete", properties: [
                "flowKey": state.flowKey,
                "screenId": screenId,
                "blockKey": blockKey ?? "",
                "blockId": blockId
            ])
            onAction("next", nil)
        }

        return AnyView(
            PersonalizationBlockView(
                items: items,
                theme: theme,
                onComplete: onComplete,
                onStart: {
                    analytics.track("personalization_start", properties: [
                        "flowKey": state.flowKey,
                        "screenId": screenId,
                        "blockKey": blockKey ?? "",
                        "blockId": blockId
                    ])
                }
            )
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.lg.value)
        )
    }
}

// MARK: - Personalization Block View (custom design: spinner + dynamic text + step indicator)

private struct PersonalizationBlockView: View {
    let items: [PersonalizationItem]
    let theme: Theme
    let onComplete: () -> Void
    let onStart: () -> Void

    @State private var currentIndex: Int = 0
    @State private var hasFiredStart: Bool = false
    @State private var isActive: Bool = true

    private var currentItem: PersonalizationItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    private let verticalSpacing: CGFloat = 24

    private var textColor: Color {
        theme.tokens.textPrimaryColor
    }

    var body: some View {
        VStack(spacing: verticalSpacing) {
            // Circular spinner – uses theme primary text color (e.g. white on dark gradient)
            ProgressView()
                .scaleEffect(1.2)
                .tint(textColor)

            if let item = currentItem {
                VStack(spacing: 12) {
                    if !item.text.isEmpty {
                        Text(item.text)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Step X of Y
                    if items.count > 1 {
                        Text("Step \(currentIndex + 1) of \(items.count)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg.value)
        .onAppear {
            isActive = true
            if !hasFiredStart {
                onStart()
                hasFiredStart = true
            }
            advanceAfterCurrentItem()
        }
        .onDisappear {
            isActive = false
        }
    }

    private func advanceAfterCurrentItem() {
        guard isActive else { return }
        guard currentIndex < items.count else {
            onComplete()
            return
        }

        let item = items[currentIndex]
        let clampedMs = min(60_000, max(500, item.durationMs))
        let durationSeconds = clampedMs / 1000.0

        DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds) {
            guard isActive else { return }
            currentIndex += 1
            if currentIndex >= items.count {
                onComplete()
            } else {
                advanceAfterCurrentItem()
            }
        }
    }
}
