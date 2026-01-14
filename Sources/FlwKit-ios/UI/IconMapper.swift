import SwiftUI

// MARK: - Icon Mapper
// Maps Lucide icon names to SF Symbols for iOS

enum IconMapper {
    /// Maps a Lucide icon name to an SF Symbol name
    /// - Parameter iconName: The Lucide icon name (e.g., "Check", "Star", "Heart")
    /// - Returns: The SF Symbol name, or "checkmark" as fallback
    static func mapToSFSymbol(_ iconName: String?) -> String {
        guard let iconName = iconName else {
            return "checkmark" // Default fallback
        }
        
        let iconMap: [String: String] = [
            // Check variants
            "Check": "checkmark",
            "CheckCircle2": "checkmark.circle.fill",
            "CircleCheck": "checkmark.circle",
            
            // Common icons
            "Star": "star.fill",
            "Heart": "heart.fill",
            "Zap": "bolt.fill",
            "Shield": "shield.fill",
            "Award": "award.fill",
            "Sparkles": "sparkles",
            "ThumbsUp": "hand.thumbsup.fill",
            "ArrowRight": "arrow.right",
            
            // Communication
            "Bell": "bell.fill",
            "Mail": "envelope.fill",
            "MessageSquare": "message.fill",
            "Phone": "phone.fill",
            
            // Navigation & UI
            "Bookmark": "bookmark.fill",
            "Home": "house.fill",
            "Settings": "gearshape.fill",
            "Search": "magnifyingglass",
            "Filter": "line.3.horizontal.decrease.circle.fill",
            
            // Time & Date
            "Calendar": "calendar",
            "Clock": "clock.fill",
            
            // Media
            "Camera": "camera.fill",
            "Video": "video.fill",
            "Music": "music.note",
            "Play": "play.fill",
            
            // Files & Data
            "File": "doc.fill",
            "Folder": "folder.fill",
            "Download": "arrow.down.circle.fill",
            "Package": "shippingbox.fill",
            
            // Code & Tech
            "Code": "code",
            "Command": "command",
            "Wifi": "wifi",
            "Link": "link",
            
            // Business & Finance
            "CreditCard": "creditcard.fill",
            "ShoppingCart": "cart.fill",
            "Tag": "tag.fill",
            "TrendingUp": "arrow.trending.up",
            
            // Lifestyle
            "Coffee": "cup.and.saucer.fill",
            "Gift": "gift.fill",
            "Trophy": "trophy.fill",
            "Crown": "crown.fill",
            
            // Location & Travel
            "Map": "map.fill",
            "Compass": "compass.fill",
            "Globe": "globe",
            
            // User & Profile
            "User": "person.fill",
            "Key": "key.fill",
            "Lock": "lock.fill",
            "Eye": "eye.fill",
            
            // Status & Actions
            "Info": "info.circle.fill",
            "Target": "target",
            "Umbrella": "umbrella.fill",
            "XCircle": "xmark.circle.fill"
        ]
        
        return iconMap[iconName] ?? "checkmark" // Fallback to checkmark
    }
    
    /// List of all supported icon names
    static var supportedIcons: [String] {
        return [
            "Check", "CheckCircle2", "CircleCheck",
            "Star", "Heart", "Zap", "Shield", "Award",
            "Sparkles", "ThumbsUp", "ArrowRight",
            "Bell", "Mail", "MessageSquare", "Phone",
            "Bookmark", "Home", "Settings", "Search", "Filter",
            "Calendar", "Clock",
            "Camera", "Video", "Music", "Play",
            "File", "Folder", "Download", "Package",
            "Code", "Command", "Wifi", "Link",
            "CreditCard", "ShoppingCart", "Tag", "TrendingUp",
            "Coffee", "Gift", "Trophy", "Crown",
            "Map", "Compass", "Globe",
            "User", "Key", "Lock", "Eye",
            "Info", "Target", "Umbrella", "XCircle"
        ]
    }
}

// MARK: - Icon View
// Reusable SwiftUI view for rendering icons with styling

struct IconView: View {
    let iconName: String?
    let color: Color
    let size: CGFloat
    
    init(iconName: String?, color: Color, size: CGFloat) {
        self.iconName = iconName
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Image(systemName: IconMapper.mapToSFSymbol(iconName))
            .foregroundColor(color)
            .font(.system(size: size))
            .frame(width: size, height: size)
    }
}

// MARK: - Icon View with Custom Frame
// Allows custom frame dimensions while maintaining icon size

struct IconViewWithFrame: View {
    let iconName: String?
    let color: Color
    let iconSize: CGFloat
    let frameWidth: CGFloat?
    let frameHeight: CGFloat?
    
    init(
        iconName: String?,
        color: Color,
        iconSize: CGFloat,
        frameWidth: CGFloat? = nil,
        frameHeight: CGFloat? = nil
    ) {
        self.iconName = iconName
        self.color = color
        self.iconSize = iconSize
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
    }
    
    var body: some View {
        Image(systemName: IconMapper.mapToSFSymbol(iconName))
            .foregroundColor(color)
            .font(.system(size: iconSize))
            .frame(width: frameWidth ?? iconSize, height: frameHeight ?? iconSize)
    }
}
