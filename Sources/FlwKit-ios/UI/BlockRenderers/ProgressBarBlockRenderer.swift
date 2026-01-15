import SwiftUI

struct ProgressBarBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        
        // Calculate progress
        let progress: Double = {
            guard let totalScreens = state.totalScreens, totalScreens > 0 else {
                return 0 // No screens, no progress
            }
            
            // Get current screen index (0-based)
            let currentIndex: Int = {
                if let index = state.currentScreenIndex, index >= 0 {
                    return index
                }
                // Fallback: if index not available, default to 0 (first screen)
                return 0
            }()
            
            // Calculate progress: (currentIndex + 1) / totalScreens * 100
            let progressValue = ((Double(currentIndex) + 1.0) / Double(totalScreens)) * 100.0
            
            // Cap at 100%
            return min(progressValue, 100.0)
        }()
        
        // Get background color with opacity (track - unfilled portion)
        let backgroundColor: Color = {
            let baseColor = block.backgroundColor ?? tokens.surface
            let opacity = block.backgroundOpacity != nil ? block.backgroundOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get fill color with opacity (filled portion showing progress)
        let fillColor: Color = {
            let baseColor = block.fillColor ?? tokens.primary
            let opacity = block.fillOpacity != nil ? block.fillOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get border color with opacity
        let borderColor: Color = {
            let baseColor = block.borderColor ?? tokens.textSecondary
            let opacity = block.borderOpacity != nil ? block.borderOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Handle width (default: 100%)
        enum WidthMode {
            case fullWidth // 100% or undefined
            case fixed(CGFloat) // Fixed pixel width
            case percentage(CGFloat) // Percentage width (0.0 to 1.0)
            case auto // Auto width
        }
        
        let widthMode: WidthMode = {
            if let width = block.width {
                switch width {
                case .auto:
                    return .auto
                case .fixed(let value):
                    return .fixed(CGFloat(value))
                case .percentage(let percentageString):
                    // Parse percentage string like "100%", "50%"
                    if let percentage = Double(percentageString.replacingOccurrences(of: "%", with: "")) {
                        return .percentage(CGFloat(percentage / 100.0))
                    }
                    return .fullWidth // Fallback to full width if parsing fails
                }
            }
            return .fullWidth // Default to full width (100%)
        }()
        
        // Get height (default: 8px, minimum 4px)
        let height: CGFloat = {
            if let h = block.height, h >= 4 {
                return CGFloat(h)
            }
            return 8 // Default to 8px
        }()
        
        // Get border width (default: 0 = no border)
        let borderWidth: CGFloat = {
            if let width = block.borderWidth, width > 0 {
                return CGFloat(width)
            }
            return 0
        }()
        
        // Get border radius (default: 4px)
        let borderRadius: CGFloat = block.borderRadius.map { CGFloat($0) } ?? 4
        
        // Build progress bar content
        let progressPercentage = max(0, min(100, progress)) / 100.0
        
        let progressBarContent = ZStack(alignment: .leading) {
            // Track (background - unfilled portion)
            RoundedRectangle(cornerRadius: borderRadius)
                .fill(backgroundColor)
                .frame(height: height)
            
            // Fill (progress - filled portion)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: borderRadius)
                    .fill(fillColor)
                    .frame(width: geometry.size.width * progressPercentage, height: height)
            }
        }
        .frame(height: height)
        .overlay(
            Group {
                if borderWidth > 0 {
                    RoundedRectangle(cornerRadius: borderRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                }
            }
        )
        .clipped() // Ensure fill doesn't overflow rounded corners
        
        // Apply width based on widthMode
        switch widthMode {
        case .fullWidth:
            // Full width (100%) - default
            return AnyView(
                progressBarContent
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.md.value)
            )
        case .fixed(let width):
            // Fixed pixel width
            return AnyView(
                progressBarContent
                    .frame(width: width)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md.value)
            )
        case .percentage(let percentage):
            // Percentage width - use GeometryReader
            return AnyView(
                GeometryReader { geometry in
                    progressBarContent
                        .frame(width: geometry.size.width * percentage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: height)
                .padding(.horizontal, Spacing.md.value)
            )
        case .auto:
            // Auto width - size to content
            return AnyView(
                progressBarContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md.value)
            )
        }
    }
}
