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

// MARK: - Personalization Block View

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

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            if let item = currentItem, !item.text.isEmpty {
                Text(item.text)
                    .font(.body)
                    .foregroundColor(theme.tokens.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
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
