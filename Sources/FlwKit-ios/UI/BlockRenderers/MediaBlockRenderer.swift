import SwiftUI

struct MediaBlockRenderer: BlockRenderer {
    func render(block: Block, theme: Theme, state: FlowState, onAnswer: @escaping (String, Any) -> Void, onAction: @escaping (String, String?) -> Void) -> AnyView {
        return AnyView(
            VStack {
                if let imageUrl = block.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(theme.tokens.cornerRadius)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(theme.tokens.cornerRadius)
                }
            }
            .padding(.horizontal, Spacing.md.value)
        )
    }
}

