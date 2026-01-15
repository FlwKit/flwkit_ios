import SwiftUI
import UIKit // Required for UIFont

struct TestimonialBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let quote = block.quote ?? ""
        let author = block.author
        let meta = block.meta
        
        // Get text color with opacity (default: theme's textPrimary)
        let textColor: Color = {
            let baseColor = block.color ?? tokens.textPrimary
            let opacity = block.opacity != nil ? block.opacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get background color with opacity (default: theme's surface)
        let backgroundColor: Color = {
            let baseColor = block.backgroundColor ?? tokens.surface
            let opacity = block.backgroundOpacity != nil ? block.backgroundOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get border color with opacity (default: theme's textSecondary)
        let borderColor: Color = {
            let baseColor = block.borderColor ?? tokens.textSecondary
            let opacity = block.borderOpacity != nil ? block.borderOpacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get font weight (default: normal)
        let fontWeight: Font.Weight = {
            switch block.fontWeight?.lowercased() {
            case "bold":
                return .bold
            default:
                return .regular // Default to normal
            }
        }()
        
        // Get font style (default: normal)
        let isItalic = block.fontStyle?.lowercased() == "italic"
        
        // Get font size (default: 16)
        let fontSize = block.fontSize ?? 16.0
        
        // Get letter spacing (default: nil = no custom spacing)
        let letterSpacing: CGFloat? = block.spacing.map { CGFloat($0) }
        
        // Create font with italic support for iOS 15
        let baseFont: Font = {
            if isItalic {
                let uiFontWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()
        
        // Quote font (default to italic for quotes)
        let quoteFont: Font = {
            let shouldBeItalic = block.fontStyle?.lowercased() == "italic" || block.fontStyle == nil
            if shouldBeItalic {
                let uiFontWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()
        
        // Get alignment (default: left)
        let alignment: HorizontalAlignment = {
            switch block.align?.lowercased() {
            case "center":
                return .center
            case "right":
                return .trailing
            default:
                return .leading // Default to left
            }
        }()
        
        // Convert HorizontalAlignment to TextAlignment
        let textAlignment: TextAlignment = {
            switch alignment {
            case .leading:
                return .leading
            case .center:
                return .center
            case .trailing:
                return .trailing
            default:
                return .leading
            }
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
        
        // Get height (default: auto/undefined)
        let height: CGFloat? = block.height.map { CGFloat($0) }
        
        // Get border width (default: 0 = no border)
        let borderWidth: CGFloat = {
            if let width = block.borderWidth, width > 0 {
                return CGFloat(width)
            }
            return 0
        }()
        
        // Get border radius (default: 0)
        let borderRadius: CGFloat = block.borderRadius.map { CGFloat($0) } ?? 0
        
        // Build the testimonial content
        let testimonialContent = VStack(alignment: alignment, spacing: 0) {
            // Quote
            Text("\"\(quote)\"")
                .font(quoteFont)
                .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                .multilineTextAlignment(textAlignment)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
                .padding(.bottom, (author != nil || meta != nil) ? 12 : 0)
            
            // Author
            if let author = author, !author.isEmpty {
                // Author font - semibold weight, but respect fontStyle
                let authorFont: Font = {
                    if isItalic {
                        let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: .semibold).fontDescriptor.withSymbolicTraits(.traitItalic)
                        if let descriptor = descriptor {
                            return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                        }
                    }
                    return .system(size: CGFloat(fontSize), weight: .semibold) // Slightly bolder (600)
                }()
                
                Text(author)
                    .font(authorFont)
                    .kerning(letterSpacing ?? 0)
                    .multilineTextAlignment(textAlignment)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
                    .padding(.top, 8)
                    .padding(.bottom, meta != nil ? 4 : 0)
            }
            
            // Meta
            if let meta = meta, !meta.isEmpty {
                // Meta font - 75% of base size, respect fontStyle
                let metaFont: Font = {
                    let metaSize = CGFloat(fontSize * 0.75)
                    if isItalic {
                        let uiFontWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
                        let descriptor = UIFont.systemFont(ofSize: metaSize, weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                        if let descriptor = descriptor {
                            return Font(UIFont(descriptor: descriptor, size: metaSize))
                        }
                    }
                    return .system(size: metaSize, weight: fontWeight)
                }()
                
                Text(meta)
                    .font(metaFont)
                    .kerning(letterSpacing ?? 0)
                    .multilineTextAlignment(textAlignment)
                    .foregroundColor(textColor.opacity(0.8)) // Slightly transparent
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
                    .padding(.top, 4)
            }
        }
        .padding(16) // Default padding
        .frame(height: height) // Height if specified
        .background(backgroundColor)
        .overlay(
            Group {
                if borderWidth > 0 {
                    RoundedRectangle(cornerRadius: borderRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                }
            }
        )
        .cornerRadius(borderRadius)
        
        // Apply width based on widthMode
        switch widthMode {
        case .fullWidth:
            // Full width (100%) - default
            return AnyView(
                testimonialContent
                    .frame(maxWidth: .infinity)
            )
        case .fixed(let width):
            // Fixed pixel width
            return AnyView(
                testimonialContent
                    .frame(width: width)
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
            )
        case .percentage(let percentage):
            // Percentage width - use GeometryReader
            return AnyView(
                GeometryReader { geometry in
                    testimonialContent
                        .frame(width: geometry.size.width * percentage)
                        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
                }
                .frame(height: height) // Preserve height
            )
        case .auto:
            // Auto width - size to content
            return AnyView(
                testimonialContent
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .center ? .center : .trailing))
            )
        }
    }
}
