# FlwKit iOS SDK - Implementation Guide

A comprehensive guide for integrating and using the FlwKit iOS SDK in your application.

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Basic Usage](#basic-usage)
4. [Completion Callbacks](#completion-callbacks)
5. [Attributes & User Context](#attributes--user-context)
6. [UIKit Integration](#uikit-integration)
7. [Advanced Features](#advanced-features)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)

---

## Installation

### Swift Package Manager

#### Via Xcode

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/FlwKit/flwkit_ios.git
   ```
3. Select the version (e.g., `1.0.0` or later)
4. Add to your target

#### Via Package.swift

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/FlwKit/flwkit_ios.git", from: "1.0.0")
]
```

### Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+

---

## Configuration

### Basic Setup

Configure FlwKit once during app initialization. The app ID is automatically extracted from your API key by the backend.

**In SwiftUI App:**

```swift
import FlwKit_ios

@main
struct MyApp: App {
    init() {
        FlwKit.configure(apiKey: "your-api-key")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**In UIKit AppDelegate:**

```swift
import FlwKit_ios

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FlwKit.configure(apiKey: "your-api-key")
        return true
    }
}
```

### Configuration Options

#### With User ID

For user-specific flows and analytics:

```swift
FlwKit.configure(
    apiKey: "your-api-key",
    userId: "user-123"
)
```

#### With Custom Base URL

For custom backend deployments:

```swift
FlwKit.configure(
    apiKey: "your-api-key",
    userId: "user-123",
    baseURL: "https://custom-api.example.com"
)
```

#### Updating User ID

You can update the user ID at any time:

```swift
FlwKit.configure(
    apiKey: "your-api-key",
    userId: newUserId
)
```

**Note:** The SDK automatically fetches the active flow for your app. Only one flow can be active at a time, and it's determined by your API key.

---

## Basic Usage

### SwiftUI - Simplest Form

The simplest way to use FlwKit is to add `FlwKitFlowView` to your SwiftUI view:

```swift
import FlwKit_ios
import SwiftUI

struct OnboardingView: View {
    var body: some View {
        FlwKitFlowView()
    }
}
```

That's it! The SDK will:
- Automatically fetch the active flow from your backend
- Render all screens natively
- Save user progress automatically
- Track analytics events
- Handle errors gracefully

### Full Screen Presentation

For onboarding flows, you typically want full-screen presentation:

```swift
struct OnboardingView: View {
    @State private var showOnboarding = true
    
    var body: some View {
        if showOnboarding {
            FlwKitFlowView { result in
                showOnboarding = false
                // Handle completion
            }
            .ignoresSafeArea()
        } else {
            MainContentView()
        }
    }
}
```

---

## Completion Callbacks

### Understanding Completion Results

When a flow completes, you receive a `FlwKitCompletionResult` object containing:

- **`flowId`**: The flow identifier (flowKey)
- **`variantId`**: Variant ID if user was in an A/B test, `nil` otherwise
- **`completedAt`**: Timestamp when the flow was completed
- **`answers`**: Dictionary of all answers collected from each screen

### Basic Completion Handler

```swift
FlwKitFlowView { result in
    print("Flow completed: \(result.flowId)")
    print("Completed at: \(result.completedAt)")
    print("Answers: \(result.answers)")
}
```

### Navigation After Completion

```swift
struct ContentView: View {
    @State private var isOnboardingComplete = false
    
    var body: some View {
        if isOnboardingComplete {
            HomeView()
        } else {
            FlwKitFlowView { result in
                isOnboardingComplete = true
                // Navigate to home or process answers
                processOnboardingAnswers(result.answers)
            }
        }
    }
    
    private func processOnboardingAnswers(_ answers: [String: Any]) {
        // Process user answers
        if let name = answers["name"] as? String {
            UserDefaults.standard.set(name, forKey: "userName")
        }
    }
}
```

### Using Router/Navigation

```swift
import FlwKit_ios

struct AppView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            FlwKitFlowView { result in
                router.navigate(to: .home)
            }
            .navigationDestination(for: Route.self) { route in
                router.view(for: route)
            }
        }
    }
}
```

### A/B Test Variant Information

```swift
FlwKitFlowView { result in
    if let variantId = result.variantId {
        print("User was in A/B test variant: \(variantId)")
        // Track which variant completed
        Analytics.track("onboarding_completed", properties: [
            "variant_id": variantId,
            "flow_id": result.flowId
        ])
    }
    
    // Navigate based on variant or answers
    navigateAfterOnboarding(result)
}
```

### Accessing Answers

Answers are stored as `[String: Any]` where keys are block identifiers and values are the user's responses:

```swift
FlwKitFlowView { result in
    // Text input answers
    if let email = result.answers["email"] as? String {
        saveUserEmail(email)
    }
    
    // Choice answers (single select)
    if let plan = result.answers["plan_selection"] as? String {
        setUserPlan(plan)
    }
    
    // Choice answers (multi-select)
    if let interests = result.answers["interests"] as? [String] {
        saveUserInterests(interests)
    }
    
    // Slider values
    if let budget = result.answers["budget"] as? Double {
        setUserBudget(budget)
    }
}
```

### Exit Handler

Handle when users exit the flow without completing:

```swift
FlwKitFlowView(
    onComplete: { result in
        // Handle completion
    },
    onExit: {
        // User exited the flow
        print("User exited onboarding")
        // Maybe show a message or save partial progress
    }
)
```

---

## Attributes & User Context

### Passing Attributes

Attributes are key-value pairs that can be used in your flow logic and analytics:

```swift
FlwKitFlowView(
    attributes: [
        "userId": "user-123",
        "source": "app_launch",
        "campaign": "summer_2024",
        "referralCode": "FRIEND2024",
        "deviceType": "iPhone 15 Pro"
    ],
    onComplete: { result in
        // Handle completion
    }
)
```

### Dynamic Attributes

You can pass dynamic attributes based on app state:

```swift
struct OnboardingView: View {
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        FlwKitFlowView(
            attributes: [
                "userId": userManager.currentUserId ?? "anonymous",
                "isPremium": userManager.isPremium,
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "platform": "iOS",
                "osVersion": UIDevice.current.systemVersion
            ],
            onComplete: { result in
                handleCompletion(result)
            }
        )
    }
}
```

### Using Attributes in Flows

Attributes are available in your flow logic on the backend. They can be used for:
- Conditional screen display
- Personalization
- Analytics segmentation
- A/B test targeting

---

## UIKit Integration

### Programmatic Presentation

For UIKit apps, use `FlwKit.present()`:

```swift
import UIKit
import FlwKit_ios
import SwiftUI

class ViewController: UIViewController {
    @IBAction func showOnboarding() {
        FlwKit.present(
            attributes: [
                "source": "button_tap"
            ],
            onComplete: { [weak self] result in
                print("Completed: \(result.flowId)")
                print("Answers: \(result.answers)")
                self?.dismiss(animated: true)
            },
            onExit: { [weak self] in
                self?.dismiss(animated: true)
            }
        ) { [weak self] result in
            switch result {
            case .success(let view):
                let hostingController = UIHostingController(rootView: view)
                hostingController.modalPresentationStyle = .fullScreen
                self?.present(hostingController, animated: true)
            case .failure(let error):
                print("Error: \(error)")
                // Show error alert
                self?.showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Wrapping in UIViewController

You can also wrap the SwiftUI view directly:

```swift
class OnboardingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowView = FlwKitFlowView { [weak self] result in
            self?.handleCompletion(result)
        }
        
        let hostingController = UIHostingController(rootView: flowView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
    
    private func handleCompletion(_ result: FlwKitCompletionResult) {
        // Handle completion
        dismiss(animated: true)
    }
}
```

---

## Advanced Features

### State Persistence

FlwKit automatically saves user progress. If a user exits mid-flow, their progress is restored when they return:

```swift
// Progress is automatically saved
// No additional code needed
FlwKitFlowView { result in
    // State is automatically cleared on completion
}
```

### Offline Support

Flows are cached automatically. If the device is offline, the last fetched flow is used:

```swift
// Works offline automatically
FlwKitFlowView()
```

### Multiple Flows

The SDK supports multiple flows simultaneously. Each flow maintains its own state:

```swift
// Flow 1
FlwKitFlowView { result1 in
    // Handle first flow
}

// Flow 2 (different context)
FlwKitFlowView(
    attributes: ["flowType": "onboarding"],
    onComplete: { result2 in
        // Handle second flow
    }
)
```

### Error Handling

The SDK handles errors gracefully:

```swift
FlwKitFlowView { result in
    // Success case
}
// Errors are shown automatically in the UI
```

For custom error handling, check the error state:

```swift
struct OnboardingView: View {
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let error = error {
                ErrorView(error: error) {
                    // Retry logic
                }
            } else {
                FlwKitFlowView { result in
                    // Handle completion
                }
            }
        }
    }
}
```

---

## Examples

### Complete Onboarding Flow

```swift
import SwiftUI
import FlwKit_ios

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(
                    onComplete: { result in
                        hasCompletedOnboarding = true
                        processOnboardingResult(result)
                    }
                )
            }
        }
    }
    
    private func processOnboardingResult(_ result: FlwKitCompletionResult) {
        // Save user data
        if let name = result.answers["name"] as? String {
            userManager.setName(name)
        }
        
        if let email = result.answers["email"] as? String {
            userManager.setEmail(email)
        }
        
        // Track completion
        Analytics.track("onboarding_completed", properties: [
            "flow_id": result.flowId,
            "variant_id": result.variantId ?? "none",
            "completed_at": result.completedAt
        ])
    }
}

struct OnboardingView: View {
    let onComplete: (FlwKitCompletionResult) -> Void
    
    var body: some View {
        FlwKitFlowView(
            attributes: [
                "userId": UserManager.shared.currentUserId ?? "anonymous",
                "appVersion": appVersion,
                "platform": "iOS"
            ],
            onComplete: onComplete
        )
        .ignoresSafeArea()
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}
```

### Conditional Flow Display

```swift
struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.needsOnboarding {
                    OnboardingView {
                        authManager.completeOnboarding()
                    }
                } else {
                    MainView()
                }
            } else {
                LoginView()
            }
        }
    }
}
```

### A/B Test Tracking

```swift
FlwKitFlowView { result in
    // Track which variant completed
    if let variantId = result.variantId {
        Analytics.track("onboarding_variant_completed", properties: [
            "variant_id": variantId,
            "flow_id": result.flowId,
            "completion_time": result.completedAt.timeIntervalSince1970
        ])
    }
    
    // Navigate based on variant
    if result.variantId == "variant_a" {
        navigateToPlanA()
    } else if result.variantId == "variant_b" {
        navigateToPlanB()
    } else {
        navigateToDefault()
    }
}
```

### Multi-Step Integration

```swift
struct MultiStepOnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    
    enum OnboardingStep {
        case welcome
        case flow
        case final
    }
    
    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                WelcomeView {
                    currentStep = .flow
                }
            case .flow:
                FlwKitFlowView { result in
                    saveOnboardingData(result)
                    currentStep = .final
                }
            case .final:
                FinalStepView()
            }
        }
    }
    
    private func saveOnboardingData(_ result: FlwKitCompletionResult) {
        // Save to backend
        API.saveOnboarding(result.answers) { success in
            if success {
                // Continue to final step
            }
        }
    }
}
```

---

## Troubleshooting

### Flow Not Loading

**Issue:** Flow doesn't appear or shows error

**Solutions:**
1. Verify API key is correct
2. Ensure a flow is marked as active in the dashboard
3. Check network connectivity
4. Verify backend is accessible

### Answers Not Captured

**Issue:** `answers` dictionary is empty

**Solutions:**
1. Ensure blocks have `key` properties set
2. Check that input blocks are properly configured
3. Verify user actually interacted with inputs

### Completion Callback Not Firing

**Issue:** `onComplete` callback never executes

**Solutions:**
1. Ensure flow actually completes (not just exited)
2. Check that completion action is triggered in flow logic
3. Verify no errors in console

### State Not Persisting

**Issue:** Progress lost when app restarts

**Solutions:**
1. Check `UserDefaults` permissions
2. Verify flow key is consistent
3. Ensure state isn't being cleared prematurely

### A/B Test Variant Always Nil

**Issue:** `variantId` is always `nil`

**Solutions:**
1. Verify A/B test is active in dashboard
2. Check that user meets targeting criteria
3. Ensure backend A/B test endpoint is working

---

## API Reference

### FlwKit

#### `configure(apiKey:userId:baseURL:)`

Configure FlwKit with your API key.

```swift
FlwKit.configure(
    apiKey: String,
    userId: String? = nil,
    baseURL: String? = nil
)
```

#### `present(attributes:onComplete:onExit:completion:)`

Present a flow programmatically (UIKit).

```swift
FlwKit.present(
    attributes: [String: Any] = [:],
    onComplete: @escaping (FlwKitCompletionResult) -> Void = { _ in },
    onExit: (() -> Void)? = nil,
    completion: @escaping (Result<AnyView, Error>) -> Void
)
```

### FlwKitFlowView

SwiftUI view for presenting flows.

#### Initializers

```swift
// Simplest
FlwKitFlowView()

// With completion
FlwKitFlowView(onComplete: @escaping (FlwKitCompletionResult) -> Void)

// Full control
FlwKitFlowView(
    attributes: [String: Any] = [:],
    onComplete: ((FlwKitCompletionResult) -> Void)? = nil,
    onExit: (() -> Void)? = nil
)
```

### FlwKitCompletionResult

Result returned when flow completes.

```swift
public struct FlwKitCompletionResult {
    public let flowId: String
    public let variantId: String?
    public let completedAt: Date
    public let answers: [String: Any]
}
```

---

## Best Practices

1. **Configure Early**: Call `FlwKit.configure()` as early as possible in app lifecycle
2. **Handle Completion**: Always provide a completion handler to handle navigation
3. **Use Attributes**: Pass relevant user/app context via attributes
4. **Test Offline**: Verify your app works with cached flows
5. **Monitor Analytics**: Check analytics events are being sent correctly
6. **Error Handling**: Implement proper error handling for production
7. **State Management**: Don't manually clear state - let SDK handle it
8. **User ID**: Set user ID when available for better analytics and personalization

---

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/FlwKit/flwkit_ios/issues)
- Documentation: See other docs in `/docs` folder

---

## License

[Add your license information]
