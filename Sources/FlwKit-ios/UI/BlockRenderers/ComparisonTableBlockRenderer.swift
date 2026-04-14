import SwiftUI

struct ComparisonTableBlockRenderer: BlockRenderer {
    func render(
        block: Block,
        theme: Theme,
        state: FlowState,
        onAnswer: @escaping (String, Any) -> Void,
        onAction: @escaping (String, String?) -> Void
    ) -> AnyView {
        let rows = Array((block.rows ?? []).prefix(4))
        let borderColor = theme.tokens.textSecondaryColor.opacity(0.40)
        let cardBackground = theme.tokens.surfaceColor.opacity(0.88)

        AnyView(
            VStack(spacing: 0) {
                Text(block.headline ?? "See the difference")
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.tokens.textPrimaryColor)
                    .padding(.bottom, 12)

                HStack(spacing: 8) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                    Text(block.leftLabel ?? "Without")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.tokens.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text(block.rightLabel ?? "With")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.tokens.primaryColor)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 4) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 8) {
                            Text(row.feature)
                                .font(.system(size: 12))
                                .foregroundColor(theme.tokens.textPrimaryColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.leftValue)
                                .font(.system(size: 12))
                                .foregroundColor(theme.tokens.textSecondaryColor)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            Text(row.rightValue)
                                .font(.system(size: 12))
                                .foregroundColor(theme.tokens.textPrimaryColor)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(
                            (row.highlighted ?? false)
                                ? theme.tokens.primaryColor.opacity(0.18)
                                : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(16)
            .padding(.horizontal, Spacing.md.value)
        )
    }
}
