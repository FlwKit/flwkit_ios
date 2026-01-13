import SwiftUI

struct MediaBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        guard let urlString = block.url, let url = URL(string: urlString) else {
            // Missing URL - show placeholder
            return AnyView(errorPlaceholder(borderRadius: block.borderRadius))
        }
        
        return AnyView(
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: block.mediaHeight.map { CGFloat($0) } ?? 200)
                case .success(let image):
                    buildImageView(image: image, block: block)
                case .failure:
                    errorPlaceholder(borderRadius: block.borderRadius)
                @unknown default:
                    EmptyView()
                }
            }
        )
    }
    
    private func buildImageView(image: Image, block: Block) -> AnyView {
        var baseView: AnyView = AnyView(
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        
        // Width handling
        if let width = block.width {
            switch width {
            case .auto:
                // Auto width - maintain aspect ratio, no width constraint
                break
            case .fixed(let value):
                baseView = AnyView(baseView.frame(width: CGFloat(value)))
            }
        } else {
            // Default to 100% width
            baseView = AnyView(baseView.frame(maxWidth: .infinity))
        }
        
        // Height handling
        if let height = block.mediaHeight {
            baseView = AnyView(baseView.frame(height: CGFloat(height)))
        }
        
        // Aspect ratio (only if width and height are not specified)
        if block.width == nil && block.mediaHeight == nil {
            if let aspect = block.aspect {
                let aspectRatio: CGFloat?
                switch aspect {
                case "square":
                    aspectRatio = 1.0
                case "wide":
                    aspectRatio = 16.0 / 9.0
                case "tall":
                    aspectRatio = 9.0 / 16.0
                default:
                    aspectRatio = nil
                }
                if let ratio = aspectRatio {
                    baseView = AnyView(baseView.aspectRatio(ratio, contentMode: .fit))
                }
            }
        }
        
        // Clip to bounds for proper corner radius
        baseView = AnyView(baseView.clipped())
        
        // Border radius
        if let borderRadius = block.borderRadius {
            baseView = AnyView(baseView.cornerRadius(CGFloat(borderRadius)))
        }
        
        // Padding
        if let padding = block.padding {
            let vertical = CGFloat(padding.vertical ?? 0)
            let horizontal = CGFloat(padding.horizontal ?? 0)
            if vertical > 0 || horizontal > 0 {
                baseView = AnyView(baseView
                    .padding(.vertical, vertical)
                    .padding(.horizontal, horizontal))
            }
        }
        
        // Margin (using padding since SwiftUI doesn't have direct margin)
        if let margin = block.margin {
            let top = CGFloat(margin.top ?? 0)
            let bottom = CGFloat(margin.bottom ?? 0)
            let leading = CGFloat(margin.left ?? 0)
            let trailing = CGFloat(margin.right ?? 0)
            
            if top != 0 || bottom != 0 || leading != 0 || trailing != 0 {
                baseView = AnyView(baseView
                    .padding(.top, top)
                    .padding(.bottom, bottom)
                    .padding(.leading, leading)
                    .padding(.trailing, trailing))
            }
        }
        
        return baseView
    }
    
    @ViewBuilder
    private func errorPlaceholder(borderRadius: Int?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .foregroundColor(.gray)
                .font(.system(size: 32))
            Text("Image failed to load")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(borderRadius.map { CGFloat($0) } ?? 0)
    }
}

