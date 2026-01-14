import SwiftUI
import UIKit // Required for UIFont

struct BenefitsListBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        let tokens = theme.tokens
        let items = block.items ?? []
        
        // Map Lucide icon names to SF Symbols
        let iconName = mapIconToSFSymbol(block.icon ?? "Check")
        
        // Get icon color (default: theme primary)
        let iconColor: Color = {
            if let iconColorHex = block.iconColor {
                return Color(hex: iconColorHex)
            }
            return tokens.primaryColor
        }()
        
        // Get icon size (default: 16)
        let iconSize: CGFloat = {
            if let size = block.iconSize {
                // Clamp between 8-64
                return CGFloat(max(8, min(64, size)))
            }
            return 16
        }()
        
        // Get text color with opacity (default: theme textPrimary)
        let textColor: Color = {
            let baseColor = block.color ?? tokens.textPrimary
            let opacity = block.opacity != nil ? block.opacity! / 100.0 : 1.0
            let color = Color(hex: baseColor)
            return opacity < 1.0 ? color.opacity(opacity) : color
        }()
        
        // Get font weight (default: normal)
        let fontWeight: Font.Weight = {
            switch block.fontWeight?.lowercased() {
            case "bold": return .bold
            default: return .regular // Default to normal
            }
        }()
        
        // Get font style (default: normal)
        let isItalic = block.fontStyle?.lowercased() == "italic"
        
        // Get font size (default: 16)
        let fontSize = block.fontSize ?? 16.0
        
        // Create font with italic support for iOS 15
        let itemFont: Font = {
            if isItalic {
                let uiFontWeight: UIFont.Weight = fontWeight == .bold ? .bold : .regular
                let descriptor = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: uiFontWeight).fontDescriptor.withSymbolicTraits(.traitItalic)
                if let descriptor = descriptor {
                    return Font(UIFont(descriptor: descriptor, size: CGFloat(fontSize)))
                }
            }
            return .system(size: CGFloat(fontSize), weight: fontWeight)
        }()
        
        // Get letter spacing (default: nil = no custom spacing)
        let letterSpacing: CGFloat? = block.spacing.map { CGFloat($0) }
        
        // Get alignment (default: left)
        let alignment: HorizontalAlignment = {
            switch block.align?.lowercased() {
            case "center": return .center
            case "right": return .trailing
            default: return .leading // Default to left
            }
        }()
        
        return AnyView(
            VStack(alignment: alignment, spacing: 0) {
                // Title if present
                if let title = block.title {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(tokens.textPrimaryColor)
                        .frame(maxWidth: .infinity, alignment: alignment.toTextAlignment())
                        .padding(.bottom, Spacing.md.value)
                }
                
                // Benefits list items
                VStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .center, spacing: 8) {
                            // Spacer for center/right alignment
                            if alignment == .center || alignment == .trailing {
                                Spacer()
                            }
                            
                            // Icon
                            Image(systemName: iconName)
                                .foregroundColor(iconColor)
                                .font(.system(size: iconSize))
                                .frame(width: iconSize, height: iconSize)
                            
                            // Text
                            Text(item)
                                .font(itemFont)
                                .kerning(letterSpacing ?? 0) // Use kerning for iOS 15 compatibility
                                .multilineTextAlignment(alignment.toTextAlignment())
                                .foregroundColor(textColor)
                            
                            // Spacer for left/center alignment
                            if alignment == .leading || alignment == .center {
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md.value)
        )
    }
    
    // Map Lucide icon names to SF Symbols
    private func mapIconToSFSymbol(_ iconName: String) -> String {
        let iconMap: [String: String] = [
            "Check": "checkmark",
            "CheckCircle2": "checkmark.circle.fill",
            "CircleCheck": "checkmark.circle",
            "Star": "star.fill",
            "Heart": "heart.fill",
            "Zap": "bolt.fill",
            "Shield": "shield.fill",
            "Award": "award.fill",
            "Sparkles": "sparkles",
            "ThumbsUp": "hand.thumbsup.fill",
            "ArrowRight": "arrow.right",
            "Bell": "bell.fill",
            "Bookmark": "bookmark.fill",
            "Calendar": "calendar",
            "Camera": "camera.fill",
            "Clock": "clock.fill",
            "Code": "code",
            "Coffee": "cup.and.saucer.fill",
            "Command": "command",
            "Compass": "compass.fill",
            "CreditCard": "creditcard.fill",
            "Crown": "crown.fill",
            "Download": "arrow.down.circle.fill",
            "Eye": "eye.fill",
            "File": "doc.fill",
            "Filter": "line.3.horizontal.decrease.circle.fill",
            "Flag": "flag.fill",
            "Folder": "folder.fill",
            "Gift": "gift.fill",
            "Globe": "globe",
            "Home": "house.fill",
            "Info": "info.circle.fill",
            "Key": "key.fill",
            "Link": "link",
            "Lock": "lock.fill",
            "Mail": "envelope.fill",
            "Map": "map.fill",
            "MessageSquare": "message.fill",
            "Music": "music.note",
            "Package": "shippingbox.fill",
            "Phone": "phone.fill",
            "Play": "play.fill",
            "Search": "magnifyingglass",
            "Settings": "gearshape.fill",
            "ShoppingCart": "cart.fill",
            "Tag": "tag.fill",
            "Target": "target",
            "TrendingUp": "arrow.trending.up",
            "Trophy": "trophy.fill",
            "Umbrella": "umbrella.fill",
            "User": "person.fill",
            "Video": "video.fill",
            "Wifi": "wifi",
            "XCircle": "xmark.circle.fill"
        ]
        
        return iconMap[iconName] ?? "checkmark" // Fallback to checkmark
    }
}

// Extension to convert HorizontalAlignment to TextAlignment
extension HorizontalAlignment {
    func toTextAlignment() -> TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
}

