import SwiftUI
import UIKit

struct ChoiceBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let currentScreenId = state.currentScreenId ?? ""
        let blockKey = block.key ?? ""
        let uniqueViewId = "\(currentScreenId)_\(blockKey)"

        return AnyView(
            ChoiceBlockView(
                block: block,
                theme: theme,
                onAnswer: onAnswer,
                onAction: onAction,
                screenId: currentScreenId
            )
            .id(uniqueViewId)
        )
    }
}

struct ChoiceBlockView: View {
    let block: Block
    let theme: Theme
    let onAnswer: (String, Any) -> Void
    let onAction: (String, String?) -> Void
    let screenId: String

    @State private var selectedValues: Set<String> = []

    private let analytics = Analytics.shared

    // Derive isMultiple from mode string (preferred) or legacy multiple bool
    private var isMultiple: Bool {
        if let mode = block.mode {
            return mode == "multi"
        }
        return block.multiple ?? false
    }

    private var minSelections: Int {
        block.minSelections ?? 1
    }

    var body: some View {
        let tokens = theme.tokens
        let options = block.options ?? []
        let blockKey = block.key ?? ""

        let textColor: Color = {
            let base = block.color ?? tokens.textPrimary
            let opacity = block.opacity.map { $0 / 100.0 } ?? 1.0
            let color = Color(hex: base)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()

        let backgroundColor: Color = {
            let base = block.backgroundColor ?? tokens.surface
            let opacity = block.backgroundOpacity.map { $0 / 100.0 } ?? 1.0
            let color = Color(hex: base)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()

        let activeBackgroundColor: Color = {
            let base = block.activeBackgroundColor ?? tokens.primary
            let opacity = block.activeBackgroundOpacity.map { $0 / 100.0 } ?? 1.0
            let color = Color(hex: base)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()

        let borderColor: Color = {
            let base = block.borderColor ?? tokens.textSecondary
            let opacity = block.borderOpacity.map { $0 / 100.0 } ?? 1.0
            let color = Color(hex: base)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()

        let fontWeight: Font.Weight = block.fontWeight?.lowercased() == "bold" ? .bold : .regular
        let isItalic = block.fontStyle?.lowercased() == "italic"
        let fontSize = block.fontSize ?? 16.0

        let optionFont: Font = {
            if isItalic {
                let uiWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiWeight)
                    .fontDescriptor
                    .withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()

        let letterSpacing: CGFloat? = block.spacing.map { CGFloat($0) }

        let textAlignment: TextAlignment = {
            switch block.align?.lowercased() {
            case "center": return .center
            case "right": return .trailing
            default: return .leading
            }
        }()

        let width: CGFloat? = {
            guard let mw = block.width else { return nil }
            switch mw {
            case .fixed(let v): return CGFloat(v)
            default: return nil
            }
        }()

        let height: CGFloat? = block.choiceHeight.map { CGFloat($0) }
        let borderWidth = CGFloat(block.borderWidth ?? 1.0)
        let borderRadius = CGFloat(block.borderRadius ?? 8.0)

        return VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let isSelected = selectedValues.contains(option.value)
                let rowBackground = isSelected ? activeBackgroundColor : backgroundColor

                Button(action: {
                    handleTap(
                        option: option,
                        blockKey: blockKey,
                        isSelected: isSelected,
                        activeBackgroundColor: activeBackgroundColor
                    )
                }) {
                    HStack(spacing: 8) {
                        if let emoji = option.emoji ?? option.icon {
                            Text(emoji).font(optionFont)
                        }

                        Text(option.label)
                            .font(optionFont)
                            .kerning(letterSpacing ?? 0)
                            .multilineTextAlignment(textAlignment)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: textAlignment == .center ? .center : (textAlignment == .trailing ? .trailing : .leading))

                        SelectionIndicator(
                            isMultiple: isMultiple,
                            isSelected: isSelected,
                            activeColor: activeBackgroundColor,
                            borderColor: borderColor
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: width, height: height)
                    .frame(maxWidth: width == nil ? .infinity : nil)
                    .background(rowBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: borderRadius)
                            .stroke(isSelected ? activeBackgroundColor : borderColor, lineWidth: borderWidth)
                    )
                    .cornerRadius(borderRadius)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.md.value)
        .onAppear {
            selectedValues = []
        }
        .onChange(of: screenId) { _ in
            selectedValues = []
        }
    }

    private func handleTap(option: ChoiceOption, blockKey: String, isSelected: Bool, activeBackgroundColor: Color) {
        let wasSelected = isSelected

        if isMultiple {
            if wasSelected {
                selectedValues.remove(option.value)
            } else {
                selectedValues.insert(option.value)
                analytics.trackChoiceSelected(
                    choiceBlockId: blockKey,
                    optionValue: option.value,
                    optionLabel: option.label,
                    screenId: screenId,
                    isMultiSelect: true
                )
            }
            // Always report current selection array; navigation happens via CTA
            onAnswer(blockKey, Array(selectedValues))
        } else {
            if wasSelected {
                selectedValues.removeAll()
                onAnswer(blockKey, "")
            } else {
                selectedValues = [option.value]
                onAnswer(blockKey, option.value)

                analytics.trackChoiceSelected(
                    choiceBlockId: blockKey,
                    optionValue: option.value,
                    optionLabel: option.label,
                    screenId: screenId,
                    isMultiSelect: false
                )

                // Single mode: trigger per-option action immediately
                let raw = option.action ?? "next"
                let mapped: String = {
                    switch raw {
                    case "close": return "exit"
                    case "submit": return "complete"
                    default: return raw
                    }
                }()
                onAction(mapped, nil)
            }
        }
    }
}

// MARK: - Selection indicator (checkbox for multi, radio for single)

private struct SelectionIndicator: View {
    let isMultiple: Bool
    let isSelected: Bool
    let activeColor: Color
    let borderColor: Color

    var body: some View {
        if isMultiple {
            CheckboxView(isSelected: isSelected, activeColor: activeColor, borderColor: borderColor)
        } else {
            RadioView(isSelected: isSelected, activeColor: activeColor, borderColor: borderColor)
        }
    }
}

private struct CheckboxView: View {
    let isSelected: Bool
    let activeColor: Color
    let borderColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? activeColor : Color.clear)
                .frame(width: 20, height: 20)

            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? activeColor : borderColor, lineWidth: 1.5)
                .frame(width: 20, height: 20)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

private struct RadioView: View {
    let isSelected: Bool
    let activeColor: Color
    let borderColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? activeColor : borderColor, lineWidth: 1.5)
                .frame(width: 20, height: 20)

            if isSelected {
                Circle()
                    .fill(activeColor)
                    .frame(width: 10, height: 10)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
