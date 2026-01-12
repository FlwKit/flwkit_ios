import SwiftUI

// MARK: - Public API

public struct FlwKit {
    private static let apiClient = APIClient.shared
    private static let analytics = Analytics.shared
    
    /// Configure FlwKit with your app credentials.
    /// Call this once during app initialization (in AppDelegate or @main App struct).
    /// - Parameters:
    ///   - appId: Your FlwKit app ID
    ///   - apiKey: Your FlwKit API key
    ///   - userId: Optional user ID for user-specific flows
    ///   - baseURL: Optional custom base URL (defaults to https://api.flwkit.com)
    public static func configure(appId: String, apiKey: String, userId: String? = nil, baseURL: String? = nil) {
        apiClient.configure(baseURL: baseURL, appId: appId, apiKey: apiKey)
        analytics.configure(baseURL: baseURL, appId: appId, apiKey: apiKey, userId: userId)
    }
    
    /// Present a flow programmatically (for UIKit or programmatic SwiftUI)
    /// Note: flowKey is now fetched automatically from the backend based on appId
    /// - Parameters:
    ///   - attributes: Additional attributes to pass to the flow
    ///   - onComplete: Callback when flow completes with final answers
    ///   - onExit: Optional callback when user exits the flow
    ///   - completion: Completion handler with the flow view or error
    public static func present(
        attributes: [String: Any] = [:],
        onComplete: @escaping ([String: Any]) -> Void = { _ in },
        onExit: (() -> Void)? = nil,
        completion: @escaping (Result<AnyView, Error>) -> Void
    ) {
        apiClient.fetchFlow(userId: analytics.currentUserId) { result in
            switch result {
            case .success(let flow):
                let view = AnyView(
                    FlowView(
                    flow: flow,
                    flowKey: flow.flowKey,
                    userId: analytics.currentUserId,
                    attributes: attributes,
                    onComplete: onComplete,
                    onExit: onExit
                    )
                )
                completion(.success(view))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - SwiftUI View

/// SwiftUI view for presenting a FlwKit flow
/// 
/// Simplest usage:
/// ```swift
/// FlwKitFlowView()
/// ```
/// 
/// With completion handler:
/// ```swift
/// FlwKitFlowView { answers in
///     print(answers)
/// }
/// ```
/// 
/// Note: flowKey is now automatically fetched from the backend based on appId
public struct FlwKitFlowView: View {
    @State private var flow: Flow?
    @State private var isLoading: Bool = true
    @State private var error: Error?
    
    let attributes: [String: Any]
    let onComplete: (([String: Any]) -> Void)?
    let onExit: (() -> Void)?
    
    private let apiClient = APIClient.shared
    private let analytics = Analytics.shared
    
    /// Initialize a FlwKit flow view (flow is fetched automatically)
    public init() {
        self.init(attributes: [:], onComplete: nil, onExit: nil)
    }
    
    /// Initialize a FlwKit flow view with completion handler
    /// - Parameters:
    ///   - onComplete: Callback when flow completes with final answers
    public init(onComplete: @escaping ([String: Any]) -> Void) {
        self.init(attributes: [:], onComplete: onComplete, onExit: nil)
    }
    
    /// Initialize a FlwKit flow view (full control)
    /// - Parameters:
    ///   - attributes: Additional attributes to pass to the flow
    ///   - onComplete: Optional callback when flow completes with final answers
    ///   - onExit: Optional callback when user exits the flow
    public init(
        attributes: [String: Any] = [:],
        onComplete: (([String: Any]) -> Void)? = nil,
        onExit: (() -> Void)? = nil
    ) {
        self.attributes = attributes
        self.onComplete = onComplete
        self.onExit = onExit
    }
    
    public var body: some View {
        Group {
            if let error = error {
                ErrorView(error: error) {
                    loadFlow()
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let flow = flow {
                FlowView(
                    flow: flow,
                    flowKey: flow.flowKey,
                    userId: analytics.currentUserId,
                    attributes: attributes,
                    onComplete: onComplete ?? { _ in },
                    onExit: onExit
                )
            }
        }
        .onAppear {
            loadFlow()
        }
    }
    
    private func loadFlow() {
        isLoading = true
        error = nil
        
        apiClient.fetchFlow(userId: analytics.currentUserId) { result in
            isLoading = false
            
            switch result {
            case .success(let fetchedFlow):
                self.flow = fetchedFlow
                // Themes are already included in the flow response and registered
            case .failure(let err):
                self.error = err
            }
        }
    }
}


