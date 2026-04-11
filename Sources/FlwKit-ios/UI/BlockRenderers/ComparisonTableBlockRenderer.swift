import SwiftUI

struct ComparisonTableBlockRenderer: BlockRenderer {
    func render(
        block: Block,
        theme: Theme,
        state: FlowState,
        onAnswer: @escaping (String, Any) -> Void,
        onAction: @escaping (String, String?) -> Void
    ) -> AnyView {
        AnyView(
            VStack(spacing: 14) {
                Text(block.headline ?? "See the difference")
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.tokens.textPrimaryColor)

                HStack {
                    Spacer()
                    Text(block.leftLabel ?? "Without")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.tokens.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                    Text(block.rightLabel ?? "With")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.tokens.primaryColor)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array((block.rows ?? []).enumerated()), id: \.offset) { _, row in
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Text(row.feature)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.tokens.textPrimaryColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.leftValue)
                                .font(.system(size: 13))
                                .foregroundColor(theme.tokens.textSecondaryColor)
                                .frame(maxWidth: .infinity)
                            Text(row.rightValue)
                                .font(.system(size: 13))
                                .foregroundColor(theme.tokens.textPrimaryColor)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            (row.highlighted ?? false) ? theme.tokens.primaryColor.opacity(0.12) : Color.clear
                        )
                        Divider()
                    }
                }
            }
            .padding(.horizontal, Spacing.md.value)
        )
    }
}
