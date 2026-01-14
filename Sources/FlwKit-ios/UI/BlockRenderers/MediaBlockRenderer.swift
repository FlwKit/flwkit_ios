import SwiftUI

// Width mode for media blocks
enum WidthMode {
    case auto
    case fixed(CGFloat)
    case fullWidth // Default to 100%
}

struct MediaBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        // Get URL - prefer new 'url' field, fallback to legacy 'imageUrl'
        let imageUrlString = block.url ?? block.imageUrl
        
        // Check if URL string exists and is not empty
        guard let urlString = imageUrlString, !urlString.isEmpty, let url = URL(string: urlString) else {
        return AnyView(
                MediaPlaceholderView(
                    message: "Image not available",
                    borderRadius: block.borderRadius.map { CGFloat($0) },
                    padding: block.padding,
                    margin: block.margin
                )
            )
        }
        
        // Calculate width
        let widthMode: WidthMode = {
            if let widthValue = block.width {
                switch widthValue {
                case .auto:
                    return .auto
                case .fixed(let value):
                    return .fixed(CGFloat(value))
                }
            }
            return .fullWidth // Default to 100%
        }()
        
        // Calculate height
        let height: CGFloat? = block.mediaHeight.map { CGFloat($0) }
        
        // Calculate aspect ratio (only if width and height are not explicitly set)
        let aspectRatio: CGFloat? = {
            // Aspect ratio only applies when both width and height are not set
            let hasExplicitWidth = block.width != nil
            let hasExplicitHeight = block.mediaHeight != nil
            
            if !hasExplicitWidth && !hasExplicitHeight {
                if let aspect = block.aspect {
                    switch aspect {
                    case "square":
                        return 1.0
                    case "wide":
                        return 16.0 / 9.0
                    case "tall":
                        return 9.0 / 16.0
                    default:
                        return nil
                    }
                }
            }
            return nil
        }()
        
        // Calculate padding
        let paddingVertical = block.padding?.vertical.map { CGFloat($0) } ?? 0
        let paddingHorizontal = block.padding?.horizontal.map { CGFloat($0) } ?? 0
        
        // Calculate margin
        let marginTop = block.margin?.top.map { CGFloat($0) } ?? 0
        let marginBottom = block.margin?.bottom.map { CGFloat($0) } ?? 0
        let marginLeft = block.margin?.left.map { CGFloat($0) } ?? 0
        let marginRight = block.margin?.right.map { CGFloat($0) } ?? 0
        
        // Border radius
        let borderRadius = block.borderRadius.map { CGFloat($0) } ?? theme.tokens.cornerRadius
        
        // Calculate alignment (default to center)
        let alignment: HorizontalAlignment = {
            switch block.align?.lowercased() {
            case "left":
                return .leading
            case "right":
                return .trailing
            default:
                return .center // Default to center when align is nil or invalid
            }
        }()
        
        // Image view
        let imageView = AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                    .applyWidth(widthMode)
                    .frame(height: height ?? 200)
                    .applyAspectRatio(aspectRatio)
                        case .success(let image):
                            image
                                .resizable()
                    .applyAspectRatio(aspectRatio)
                    .applyWidth(widthMode)
                    .frame(height: height)
                    .cornerRadius(borderRadius)
                    .clipped()
                        case .failure:
                MediaPlaceholderView(
                    message: "Image failed to load",
                    borderRadius: borderRadius,
                    padding: block.padding,
                    margin: block.margin
                )
                        @unknown default:
                            EmptyView()
                        }
                    }
        .padding(.vertical, paddingVertical)
        .padding(.horizontal, paddingHorizontal)
        .padding(.top, marginTop)
        .padding(.bottom, marginBottom)
        .padding(.leading, marginLeft)
        .padding(.trailing, marginRight)
        
        // Wrap in HStack for alignment (only if width is not fullWidth)
        // If width is fullWidth, alignment has no visible effect
        if case .fullWidth = widthMode {
            // Full width - no need for alignment container
            return AnyView(imageView)
                } else {
            // Use HStack for alignment
            return AnyView(
                HStack(alignment: .center, spacing: 0) {
                    if alignment == .trailing {
                        Spacer()
                    } else if alignment == .center {
                        Spacer()
                    }
                    
                    imageView
                    
                    if alignment == .leading {
                        Spacer()
                    } else if alignment == .center {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            )
        }
    }
}

// Helper extensions
extension View {
    @ViewBuilder
    func applyAspectRatio(_ ratio: CGFloat?) -> some View {
        if let ratio = ratio {
            self.aspectRatio(ratio, contentMode: .fit)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyWidth(_ mode: WidthMode) -> some View {
        switch mode {
        case .auto:
            // Auto width - no constraint, size to content
            self
        case .fixed(let width):
            self.frame(width: width)
        case .fullWidth:
            self.frame(maxWidth: .infinity)
        }
    }
}


// Placeholder view for missing or failed images
struct MediaPlaceholderView: View {
    let message: String
    let borderRadius: CGFloat?
    let padding: MediaPadding?
    let margin: MediaMargin?
    
    var body: some View {
        VStack {
            Image(systemName: "photo")
                .foregroundColor(.gray)
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(minHeight: 100)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(borderRadius ?? 8)
        .padding(.vertical, padding?.vertical.map { CGFloat($0) } ?? 0)
        .padding(.horizontal, padding?.horizontal.map { CGFloat($0) } ?? 0)
        .padding(.top, margin?.top.map { CGFloat($0) } ?? 0)
        .padding(.bottom, margin?.bottom.map { CGFloat($0) } ?? 0)
        .padding(.leading, margin?.left.map { CGFloat($0) } ?? 0)
        .padding(.trailing, margin?.right.map { CGFloat($0) } ?? 0)
    }
}

