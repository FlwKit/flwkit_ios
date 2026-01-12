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
    /// - Parameters:
    ///   - flowKey: The key of the flow to present
    ///   - attributes: Additional attributes to pass to the flow
    ///   - onComplete: Callback when flow completes with final answers
    ///   - onExit: Optional callback when user exits the flow
    ///   - completion: Completion handler with the flow view or error
    public static func present(
        flowKey: String,
        attributes: [String: Any] = [:],
        onComplete: @escaping ([String: Any]) -> Void = { _ in },
        onExit: (() -> Void)? = nil,
        completion: @escaping (Result<AnyView, Error>) -> Void
    ) {
        apiClient.fetchFlow(flowKey: flowKey, userId: analytics.currentUserId) { result in
            switch result {
            case .success(let flow):
                let view = AnyView(
                    FlowView(
                    flow: flow,
                    flowKey: flowKey,
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
/// FlwKitFlowView("onboarding")
/// ```
/// 
/// With completion handler:
/// ```swift
/// FlwKitFlowView("onboarding") { answers in
///     print(answers)
/// }
/// ```
public struct FlwKitFlowView: View {
    @State private var flow: Flow?
    @State private var isLoading: Bool = true
    @State private var error: Error?
    
    let flowKey: String
    let attributes: [String: Any]
    let onComplete: (([String: Any]) -> Void)?
    let onExit: (() -> Void)?
    
    private let apiClient = APIClient.shared
    private let analytics = Analytics.shared
    
    /// Initialize a FlwKit flow view with just the flow key
    /// - Parameter flowKey: The key of the flow to display
    public init(_ flowKey: String) {
        self.init(flowKey: flowKey, attributes: [:], onComplete: nil, onExit: nil)
    }
    
    /// Initialize a FlwKit flow view with flow key and completion handler
    /// - Parameters:
    ///   - flowKey: The key of the flow to display
    ///   - onComplete: Callback when flow completes with final answers
    public init(_ flowKey: String, onComplete: @escaping ([String: Any]) -> Void) {
        self.init(flowKey: flowKey, attributes: [:], onComplete: onComplete, onExit: nil)
    }
    
    /// Initialize a FlwKit flow view (full control)
    /// - Parameters:
    ///   - flowKey: The key of the flow to display
    ///   - attributes: Additional attributes to pass to the flow
    ///   - onComplete: Optional callback when flow completes with final answers
    ///   - onExit: Optional callback when user exits the flow
    public init(
        flowKey: String,
        attributes: [String: Any] = [:],
        onComplete: (([String: Any]) -> Void)? = nil,
        onExit: (() -> Void)? = nil
    ) {
        self.flowKey = flowKey
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
                    flowKey: flowKey,
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
        
        apiClient.fetchFlow(flowKey: flowKey, userId: analytics.currentUserId) { result in
            isLoading = false
            
            switch result {
            case .success(let fetchedFlow):
                self.flow = fetchedFlow
                
                // Load themes for the flow
                loadThemes(for: fetchedFlow)
            case .failure(let err):
                self.error = err
            }
        }
    }
    
    private func loadThemes(for flow: Flow) {
        var themeIds = Set<String>()
        
        // Collect theme IDs from screens
        for screen in flow.screens {
            if let themeId = screen.themeId {
                themeIds.insert(themeId)
            }
        }
        
        // Add default theme if present
        if let defaultThemeId = flow.defaultThemeId {
            themeIds.insert(defaultThemeId)
        }
        
        // Load themes
        for themeId in themeIds {
            if ThemeManager.shared.getTheme(themeId: themeId).id == "default" {
                // Only fetch if not already cached
                APIClient.shared.fetchTheme(themeId: themeId) { result in
                    if case .success(let theme) = result {
                        ThemeManager.shared.registerTheme(theme)
                    }
                }
            }
        }
    }
}


