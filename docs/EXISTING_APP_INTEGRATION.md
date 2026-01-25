# Integrating FlwKit SDK into an Existing iOS App

This guide walks you through integrating FlwKit into an existing iOS application, whether you're using SwiftUI, UIKit, or a hybrid approach.

## Table of Contents

1. [Pre-Integration Checklist](#pre-integration-checklist)
2. [Step-by-Step Integration](#step-by-step-integration)
3. [SwiftUI Apps](#swiftui-apps)
4. [UIKit Apps](#uikit-apps)
5. [Hybrid Apps](#hybrid-apps)
6. [Replacing Existing Onboarding](#replacing-existing-onboarding)
7. [Adding to Existing Navigation](#adding-to-existing-navigation)
8. [Migration Strategies](#migration-strategies)
9. [Common Integration Patterns](#common-integration-patterns)
10. [Testing Your Integration](#testing-your-integration)
11. [Troubleshooting](#troubleshooting)

---

## Pre-Integration Checklist

Before starting, ensure you have:

- [ ] **API Key**: Your FlwKit API key from the dashboard
- [ ] **Active Flow**: At least one flow marked as active in your FlwKit dashboard
- [ ] **iOS 15.0+**: Your app targets iOS 15.0 or later
- [ ] **Xcode 14.0+**: Latest Xcode version
- [ ] **Network Access**: Backend API is accessible from your app
- [ ] **Test Environment**: A way to test the integration without affecting production users

---

## Step-by-Step Integration

### Step 1: Add FlwKit Package

#### Via Xcode

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/FlwKit/flwkit_ios.git
   ```
4. Select the version (e.g., `1.0.0` or later)
5. Add `FlwKit_ios` to your app target

#### Via Package.swift

If your project uses `Package.swift`, add:

```swift
dependencies: [
    .package(url: "https://github.com/FlwKit/flwkit_ios.git", from: "1.0.0")
]
```

### Step 2: Configure FlwKit

Add configuration in your app's initialization code.

**For SwiftUI Apps:**

Find your `@main App` struct and add configuration:

```swift
import SwiftUI
import FlwKit_ios

@main
struct YourApp: App {
    init() {
        // Add FlwKit configuration
        FlwKit.configure(apiKey: "your-api-key")
        
        // Your existing initialization code
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupApp() {
        // Your existing setup code
    }
}
```

**For UIKit Apps:**

Find your `AppDelegate` and add configuration:

```swift
import UIKit
import FlwKit_ios

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Add FlwKit configuration
        FlwKit.configure(apiKey: "your-api-key")
        
        // Your existing initialization code
        setupApp()
        
        return true
    }
    
    private func setupApp() {
        // Your existing setup code
    }
}
```

**With User ID (if you have user authentication):**

```swift
// After user logs in
FlwKit.configure(
    apiKey: "your-api-key",
    userId: currentUser.id
)

// When user logs out
FlwKit.configure(apiKey: "your-api-key", userId: nil)
```

### Step 3: Add FlwKit View

Choose the integration approach that fits your app architecture (see sections below).

---

## SwiftUI Apps

### Integration Pattern 1: Conditional Display

Replace or supplement existing onboarding with FlwKit:

```swift
import SwiftUI
import FlwKit_ios

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Show FlwKit onboarding
                FlwKitFlowView { result in
                    hasCompletedOnboarding = true
                    processOnboardingResult(result)
                }
            } else if !authManager.isAuthenticated {
                // Your existing login view
                LoginView()
            } else {
                // Your existing main app
                MainTabView()
            }
        }
    }
    
    private func processOnboardingResult(_ result: FlwKitCompletionResult) {
        // Save onboarding data
        if let email = result.answers["email"] as? String {
            UserDefaults.standard.set(email, forKey: "onboardingEmail")
        }
    }
}
```

### Integration Pattern 2: Sheet/Modal Presentation

Present FlwKit as a modal over your existing app:

```swift
struct ContentView: View {
    @State private var showOnboarding = false
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        ZStack {
            // Your existing app content
            MainTabView()
            
            // FlwKit onboarding overlay
            if showOnboarding {
                FlwKitFlowView(
                    attributes: [
                        "userId": userManager.currentUserId ?? "anonymous",
                        "source": "app_launch"
                    ],
                    onComplete: { result in
                        showOnboarding = false
                        handleOnboardingComplete(result)
                    }
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onAppear {
            checkIfOnboardingNeeded()
        }
    }
    
    private func checkIfOnboardingNeeded() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            showOnboarding = true
        }
    }
    
    private func handleOnboardingComplete(_ result: FlwKitCompletionResult) {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        // Process results
    }
}
```

### Integration Pattern 3: Navigation Integration

Integrate FlwKit into your existing navigation flow:

```swift
import SwiftUI
import FlwKit_ios

enum AppRoute: Hashable {
    case home
    case onboarding
    case settings
}

struct AppView: View {
    @StateObject private var router = AppRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .onboarding:
                        FlwKitFlowView { result in
                            router.navigate(to: .home)
                            processOnboardingResult(result)
                        }
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}
```

---

## UIKit Apps

### Integration Pattern 1: UIViewController Wrapper

Create a wrapper view controller for FlwKit:

```swift
import UIKit
import FlwKit_ios
import SwiftUI

class OnboardingViewController: UIViewController {
    
    private var hostingController: UIHostingController<FlwKitFlowView>?
    var onComplete: ((FlwKitCompletionResult) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFlwKitView()
    }
    
    private func setupFlwKitView() {
        let flowView = FlwKitFlowView(
            attributes: [
                "source": "app_launch",
                "userId": getCurrentUserId()
            ],
            onComplete: { [weak self] result in
                self?.onComplete?(result)
                self?.dismiss(animated: true)
            },
            onExit: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        
        let hostingController = UIHostingController(rootView: flowView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
        
        self.hostingController = hostingController
    }
    
    private func getCurrentUserId() -> String? {
        // Your existing user ID retrieval logic
        return UserDefaults.standard.string(forKey: "userId")
    }
}
```

**Usage in existing UIKit code:**

```swift
class ViewController: UIViewController {
    
    @IBAction func showOnboarding() {
        let onboardingVC = OnboardingViewController()
        onboardingVC.onComplete = { [weak self] result in
            // Handle completion
            self?.handleOnboardingComplete(result)
        }
        onboardingVC.modalPresentationStyle = .fullScreen
        present(onboardingVC, animated: true)
    }
    
    private func handleOnboardingComplete(_ result: FlwKitCompletionResult) {
        // Process results
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        // Navigate to main app
    }
}
```

### Integration Pattern 2: Programmatic Presentation

Use `FlwKit.present()` for more control:

```swift
class MainViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            presentFlwKitOnboarding()
        }
    }
    
    private func presentFlwKitOnboarding() {
        FlwKit.present(
            attributes: [
                "userId": getCurrentUserId() ?? "anonymous",
                "source": "app_launch"
            ],
            onComplete: { [weak self] result in
                self?.handleOnboardingComplete(result)
            },
            onExit: { [weak self] in
                // User exited - maybe show a message
            }
        ) { [weak self] result in
            switch result {
            case .success(let view):
                let hostingController = UIHostingController(rootView: view)
                hostingController.modalPresentationStyle = .fullScreen
                self?.present(hostingController, animated: true)
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                // Fallback to your existing onboarding
                self?.showExistingOnboarding()
            }
        }
    }
    
    private func handleOnboardingComplete(_ result: FlwKitCompletionResult) {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss(animated: true) {
            // Navigate to main app
        }
    }
    
    private func showExistingOnboarding() {
        // Fallback to your existing onboarding implementation
    }
}
```

### Integration Pattern 3: UINavigationController Integration

Push FlwKit onto your existing navigation stack:

```swift
class NavigationController: UINavigationController {
    
    func showOnboarding() {
        FlwKit.present(
            onComplete: { [weak self] result in
                self?.handleOnboardingComplete(result)
            }
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let view):
                let hostingController = UIHostingController(rootView: view)
                self.pushViewController(hostingController, animated: true)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func handleOnboardingComplete(_ result: FlwKitCompletionResult) {
        // Process results
        popViewController(animated: true)
    }
}
```

---

## Hybrid Apps

If your app uses both SwiftUI and UIKit:

### Pattern 1: SwiftUI View in UIKit

```swift
// In your UIKit view controller
class HybridViewController: UIViewController {
    
    func showFlwKitOnboarding() {
        let flowView = FlwKitFlowView { [weak self] result in
            self?.handleCompletion(result)
        }
        
        let hostingController = UIHostingController(rootView: flowView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}
```

### Pattern 2: UIKit from SwiftUI

```swift
// In your SwiftUI view
struct HybridView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        VStack {
            // Your SwiftUI content
        }
        .sheet(isPresented: $showOnboarding) {
            FlwKitFlowView { result in
                showOnboarding = false
            }
        }
    }
}
```

---

## Replacing Existing Onboarding

### Strategy 1: Gradual Migration

Keep both systems temporarily with a feature flag:

```swift
struct OnboardingCoordinator: View {
    @AppStorage("useFlwKitOnboarding") private var useFlwKit = false
    
    var body: some View {
        Group {
            if useFlwKit {
                // New FlwKit onboarding
                FlwKitFlowView { result in
                    handleCompletion(result)
                }
            } else {
                // Existing onboarding
                LegacyOnboardingView()
            }
        }
    }
    
    private func handleCompletion(_ result: FlwKitCompletionResult) {
        // Migrate user data from FlwKit to your existing system
        migrateOnboardingData(result.answers)
    }
}
```

### Strategy 2: Complete Replacement

Replace your existing onboarding view directly:

**Before:**
```swift
struct OnboardingView: View {
    var body: some View {
        VStack {
            Text("Welcome")
            // ... your existing onboarding UI
        }
    }
}
```

**After:**
```swift
import FlwKit_ios

struct OnboardingView: View {
    var body: some View {
        FlwKitFlowView { result in
            handleCompletion(result)
        }
    }
    
    private func handleCompletion(_ result: FlwKitCompletionResult) {
        // Your existing completion logic
    }
}
```

### Strategy 3: A/B Testing

Test FlwKit with a subset of users:

```swift
struct OnboardingView: View {
    @AppStorage("userId") private var userId: String = ""
    
    var body: some View {
        Group {
            if shouldUseFlwKit() {
                FlwKitFlowView { result in
                    handleCompletion(result)
                }
            } else {
                LegacyOnboardingView()
            }
        }
    }
    
    private func shouldUseFlwKit() -> Bool {
        // A/B test logic - e.g., 10% of users
        let hash = userId.hashValue
        return abs(hash % 100) < 10
    }
}
```

---

## Adding to Existing Navigation

### SwiftUI NavigationStack

```swift
import SwiftUI
import FlwKit_ios

struct AppView: View {
    @StateObject private var navigation = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navigation.path) {
            HomeView()
                .navigationDestination(for: Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .home:
            HomeView()
        case .onboarding:
            FlwKitFlowView { result in
                navigation.popToRoot()
                handleOnboardingComplete(result)
            }
        case .settings:
            SettingsView()
        }
    }
}
```

### UIKit UINavigationController

```swift
extension UINavigationController {
    func showFlwKitOnboarding() {
        FlwKit.present(
            onComplete: { [weak self] result in
                self?.handleOnboardingComplete(result)
            }
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let view):
                let vc = UIHostingController(rootView: view)
                self.pushViewController(vc, animated: true)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func handleOnboardingComplete(_ result: FlwKitCompletionResult) {
        popViewController(animated: true)
    }
}
```

---

## Migration Strategies

### Migrating User Data

If you have existing onboarding data, migrate it:

```swift
struct OnboardingMigration {
    static func migrateFromLegacy() {
        // Check if user completed legacy onboarding
        if UserDefaults.standard.bool(forKey: "legacyOnboardingCompleted") {
            // Mark as completed in FlwKit context
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            
            // Optionally, sync data to backend
            syncLegacyDataToBackend()
        }
    }
    
    private static func syncLegacyDataToBackend() {
        // Sync existing user data
        if let email = UserDefaults.standard.string(forKey: "legacyEmail") {
            // Send to your backend
        }
    }
}
```

### Phased Rollout

Roll out FlwKit gradually:

```swift
struct OnboardingManager {
    static func shouldUseFlwKit() -> Bool {
        // Phase 1: Internal testing (1%)
        // Phase 2: Beta users (10%)
        // Phase 3: Gradual rollout (50%)
        // Phase 4: Full rollout (100%)
        
        let rolloutPercentage = getRolloutPercentage()
        let userId = getUserId()
        let hash = userId.hashValue
        
        return abs(hash % 100) < rolloutPercentage
    }
    
    private static func getRolloutPercentage() -> Int {
        // Fetch from your backend or feature flag service
        return 10 // 10% rollout
    }
}
```

---

## Common Integration Patterns

### Pattern 1: First Launch Only

```swift
struct AppRootView: View {
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    var body: some View {
        Group {
            if isFirstLaunch {
                FlwKitFlowView { result in
                    isFirstLaunch = false
                    processOnboardingResult(result)
                }
            } else {
                MainAppView()
            }
        }
    }
}
```

### Pattern 2: User-Specific Onboarding

```swift
struct OnboardingView: View {
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        FlwKitFlowView(
            attributes: [
                "userId": userManager.currentUserId ?? "anonymous",
                "userTier": userManager.subscriptionTier,
                "isNewUser": userManager.isNewUser
            ],
            onComplete: { result in
                userManager.markOnboardingComplete()
            }
        )
    }
}
```

### Pattern 3: Conditional Onboarding

```swift
struct ConditionalOnboardingView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.needsOnboarding {
                FlwKitFlowView(
                    attributes: [
                        "userId": authManager.userId,
                        "source": "post_login"
                    ],
                    onComplete: { result in
                        authManager.completeOnboarding()
                    }
                )
            } else {
                MainAppView()
            }
        }
    }
}
```

### Pattern 4: Deep Link Integration

```swift
struct DeepLinkHandler {
    static func handleOnboardingDeepLink() {
        // When user taps a deep link to onboarding
        NotificationCenter.default.post(
            name: .showOnboarding,
            object: nil
        )
    }
}

struct ContentView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        MainAppView()
            .onReceive(NotificationCenter.default.publisher(for: .showOnboarding)) { _ in
                showOnboarding = true
            }
            .sheet(isPresented: $showOnboarding) {
                FlwKitFlowView { result in
                    showOnboarding = false
                }
            }
    }
}
```

---

## Testing Your Integration

### 1. Test Configuration

```swift
#if DEBUG
extension FlwKit {
    static func configureForTesting() {
        FlwKit.configure(
            apiKey: "test-api-key",
            baseURL: "https://staging-api.example.com"
        )
    }
}
#endif
```

### 2. Test Completion Flow

```swift
struct OnboardingTests {
    func testOnboardingCompletion() {
        var completionResult: FlwKitCompletionResult?
        
        let expectation = XCTestExpectation(description: "Onboarding completes")
        
        // Present FlwKit
        FlwKit.present(
            onComplete: { result in
                completionResult = result
                expectation.fulfill()
            }
        ) { result in
            // Handle presentation
        }
        
        wait(for: [expectation], timeout: 30.0)
        
        XCTAssertNotNil(completionResult)
        XCTAssertNotNil(completionResult?.flowId)
    }
}
```

### 3. Test Offline Behavior

```swift
// Disable network and test cached flow
func testOfflineFlow() {
    // Configure network to be offline
    // FlwKit should use cached flow
    let flowView = FlwKitFlowView()
    // Verify flow still renders
}
```

---

## Troubleshooting

### Issue: Flow Not Appearing

**Symptoms:** Blank screen or loading indicator never disappears

**Solutions:**
1. Verify API key is correct
2. Check network connectivity
3. Ensure a flow is marked as active in dashboard
4. Check console for error messages
5. Verify FlwKit.configure() was called before presenting

```swift
// Add debug logging
FlwKit.configure(apiKey: "your-key") {
    print("FlwKit configured successfully")
}
```

### Issue: Completion Callback Not Firing

**Symptoms:** `onComplete` never executes

**Solutions:**
1. Verify flow actually completes (not just exited)
2. Check that completion action is configured in flow
3. Ensure callback is not nil
4. Check for errors in console

```swift
FlwKitFlowView { result in
    print("Completion fired: \(result.flowId)")
    // Your completion logic
}
```

### Issue: State Not Persisting

**Symptoms:** Progress lost on app restart

**Solutions:**
1. Check UserDefaults permissions
2. Verify flow key is consistent
3. Ensure state isn't being cleared prematurely

### Issue: Conflicts with Existing Code

**Symptoms:** Build errors or runtime conflicts

**Solutions:**
1. Check for naming conflicts (unlikely but possible)
2. Verify iOS version compatibility
3. Ensure proper import statements
4. Check for conflicting dependencies

### Issue: Analytics Not Working

**Symptoms:** Events not appearing in dashboard

**Solutions:**
1. Verify API key has analytics permissions
2. Check network requests in debugger
3. Ensure user ID is set if required
4. Check backend analytics endpoint

---

## Best Practices for Existing Apps

1. **Start Small**: Integrate FlwKit for one flow first (e.g., onboarding)
2. **Feature Flags**: Use feature flags to control rollout
3. **A/B Testing**: Test FlwKit against existing onboarding
4. **Data Migration**: Plan how to migrate existing user data
5. **Error Handling**: Always provide fallback to existing flows
6. **User Experience**: Ensure smooth transition between old and new
7. **Analytics**: Compare metrics between old and new implementations
8. **Testing**: Test thoroughly in staging before production

---

## Example: Complete Integration

Here's a complete example of integrating FlwKit into an existing app:

```swift
import SwiftUI
import FlwKit_ios

@main
struct ExistingApp: App {
    @StateObject private var appState = AppState.shared
    
    init() {
        // Configure FlwKit
        FlwKit.configure(
            apiKey: "your-api-key",
            userId: appState.currentUserId
        )
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isAuthenticated {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .onChange(of: appState.currentUserId) { newUserId in
            // Update FlwKit when user changes
            FlwKit.configure(
                apiKey: "your-api-key",
                userId: newUserId
            )
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        FlwKitFlowView(
            attributes: [
                "userId": appState.currentUserId ?? "anonymous",
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "platform": "iOS"
            ],
            onComplete: { result in
                hasCompletedOnboarding = true
                processOnboardingResult(result)
            },
            onExit: {
                // Handle exit if needed
            }
        )
        .ignoresSafeArea()
    }
    
    private func processOnboardingResult(_ result: FlwKitCompletionResult) {
        // Save onboarding data
        if let email = result.answers["email"] as? String {
            appState.setUserEmail(email)
        }
        
        // Track completion
        Analytics.track("onboarding_completed", properties: [
            "flow_id": result.flowId,
            "variant_id": result.variantId ?? "none"
        ])
        
        // Sync to backend
        API.saveOnboardingData(result.answers) { success in
            if success {
                print("Onboarding data saved")
            }
        }
    }
}
```

---

## Next Steps

After integration:

1. **Test Thoroughly**: Test all flows and edge cases
2. **Monitor Analytics**: Track completion rates and user behavior
3. **Gather Feedback**: Collect user feedback on the new onboarding
4. **Iterate**: Use FlwKit dashboard to improve flows based on data
5. **Expand**: Add more flows as needed (feature announcements, surveys, etc.)

---

## Support

For additional help:
- See [Implementation Guide](IMPLEMENTATION_GUIDE.md) for detailed API reference
- Check [Troubleshooting](#troubleshooting) section above
- Contact FlwKit support team

---

## Summary

Integrating FlwKit into an existing app is straightforward:

1. ✅ Add package dependency
2. ✅ Configure in app initialization
3. ✅ Replace or add FlwKit view where needed
4. ✅ Handle completion callbacks
5. ✅ Test and deploy

The SDK is designed to work alongside your existing code with minimal disruption.
