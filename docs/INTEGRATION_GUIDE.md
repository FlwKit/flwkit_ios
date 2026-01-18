# FlwKit iOS SDK - Integration Guide

This guide explains how to integrate the FlwKit iOS SDK into your existing iOS application.

## Quick Start (2-3 Lines!)

**1. Configure in your App initialization:**
```swift
import FlwKit_ios

@main
struct MyApp: App {
    init() {
        FlwKit.configure(appId: "your-app-id", apiKey: "your-api-key")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**2. Use in your SwiftUI view:**
```swift
FlwKitFlowView("onboarding")
```

That's it! Everything else (loading, state, analytics, error handling) is handled automatically by the package via your backend.

---

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Installation

### Using Swift Package Manager (SPM)

1. **In Xcode:**
   - Open your project in Xcode
   - Go to **File** → **Add Package Dependencies...**
   - Enter the package URL (or local path if using a local package)
   - Select the version or branch you want to use
   - Add the package to your target

2. **Using Package.swift (for SPM projects):**
   ```swift
   dependencies: [
       .package(url: "YOUR_PACKAGE_URL", from: "1.0.0")
   ]
   ```

3. **For local development:**
   - In Xcode: **File** → **Add Package Dependencies...**
   - Choose **Add Local...**
   - Select the FlwKit-ios directory

### Import the Package

In any file where you want to use FlwKit, add:

```swift
import FlwKit_ios
```

## Configuration

Configure FlwKit once during app initialization. Similar to Superwall, this must be done in code.

### SwiftUI App Configuration

```swift
import SwiftUI
import FlwKit_ios

@main
struct MyApp: App {
    init() {
        FlwKit.configure(
            appId: "your-app-id",
            apiKey: "your-api-key"
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### UIKit App Configuration

```swift
import UIKit
import FlwKit_ios

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FlwKit.configure(
            appId: "your-app-id",
            apiKey: "your-api-key"
        )
        
        return true
    }
}
```

### With User ID (for user-specific flows)

```swift
FlwKit.configure(
    appId: "your-app-id",
    apiKey: "your-api-key",
    userId: "user-123" // Optional: for user-specific flows
)
```

### With Custom Base URL

```swift
FlwKit.configure(
    appId: "your-app-id",
    apiKey: "your-api-key",
    userId: "user-123",
    baseURL: "https://custom-api.example.com" // Optional: defaults to https://api.flwkit.com
)
```

**Note:** Configuration must be called before using any FlwKit views or methods.

## Usage

### Simplest Usage (2-3 Lines)

FlwKit is designed to be extremely simple. Just add the view with a flow key:

```swift
import SwiftUI
import FlwKit_ios

struct OnboardingView: View {
    var body: some View {
        FlwKitFlowView("welcome-onboarding")
    }
}
```

With completion handler (3 lines):

```swift
struct OnboardingView: View {
    var body: some View {
        FlwKitFlowView("welcome-onboarding") { answers in
            print("Completed: \(answers)")
        }
    }
}
```

That's it! Everything else (loading, error handling, state management, analytics) is handled automatically by the package via the backend.

### Advanced Usage

For more control, you can use the full initializer:

```swift
FlwKitFlowView(
    flowKey: "welcome-onboarding",
    attributes: ["source": "app_launch"],
    onComplete: { answers in
        print("Flow completed with answers: \(answers)")
    },
    onExit: {
        print("User exited the flow")
    }
)
```

### Programmatic Presentation (SwiftUI)

For more control, use `FlwKit.present()`:

```swift
import SwiftUI
import FlwKit_ios

struct ContentView: View {
    @State private var showFlow = false
    @State private var flowView: AnyView?
    
    var body: some View {
        VStack {
            Button("Start Onboarding") {
                presentFlow()
            }
            
            if let flowView = flowView {
                flowView
            }
        }
    }
    
    private func presentFlow() {
        FlwKit.present(
            flowKey: "welcome-onboarding",
            attributes: ["source": "button_tap"],
            onComplete: { answers in
                print("Completed: \(answers)")
                self.flowView = nil
            },
            onExit: {
                print("Exited")
                self.flowView = nil
            }
        ) { result in
            switch result {
            case .success(let view):
                self.flowView = view
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
```

### UIKit Integration

To use FlwKit in a UIKit app, you can wrap the SwiftUI view in a `UIHostingController`:

```swift
import UIKit
import FlwKit_ios
import SwiftUI

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFlwKitButton()
    }
    
    func setupFlwKitButton() {
        let button = UIButton(type: .system)
        button.setTitle("Start Onboarding", for: .normal)
        button.addTarget(self, action: #selector(presentFlow), for: .touchUpInside)
        // Add button to your view hierarchy
    }
    
    @objc func presentFlow() {
        FlwKit.present(
            flowKey: "welcome-onboarding",
            attributes: ["source": "button_tap"],
            onComplete: { [weak self] answers in
                print("Flow completed: \(answers)")
                self?.dismiss(animated: true)
            },
            onExit: { [weak self] in
                print("Flow exited")
                self?.dismiss(animated: true)
            }
        ) { [weak self] result in
            switch result {
            case .success(let view):
                let hostingController = UIHostingController(rootView: view)
                hostingController.modalPresentationStyle = .fullScreen
                self?.present(hostingController, animated: true)
            case .failure(let error):
                print("Error presenting flow: \(error)")
                // Show error alert
            }
        }
    }
}
```

### Navigation Integration

#### SwiftUI Navigation

```swift
import SwiftUI
import FlwKit_ios

struct MainView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Start Onboarding") {
                    showOnboarding = true
                }
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showOnboarding) {
                FlwKitFlowView(
                    flowKey: "welcome-onboarding",
                    onComplete: { answers in
                        showOnboarding = false
                        // Process answers
                    }
                )
            }
        }
    }
}
```

#### UIKit Navigation

```swift
@objc func presentFlow() {
    FlwKit.present(
        flowKey: "welcome-onboarding",
        onComplete: { [weak self] answers in
            self?.navigationController?.popViewController(animated: true)
        }
    ) { [weak self] result in
        guard let self = self else { return }
        switch result {
        case .success(let view):
            let hostingController = UIHostingController(rootView: view)
            self.navigationController?.pushViewController(hostingController, animated: true)
        case .failure(let error):
            // Handle error
            break
        }
    }
}
```

## Passing Attributes

Attributes allow you to pass dynamic data to your flows:

```swift
FlwKitFlowView(
    flowKey: "onboarding",
    attributes: [
        "userId": "12345",
        "subscriptionTier": "premium",
        "source": "app_launch",
        "campaign": "summer_2024"
    ],
    onComplete: { answers in
        // answers will contain all user responses
    }
)
```

## Handling Flow Completion

The `onComplete` callback receives a dictionary of all answers collected during the flow:

```swift
FlwKitFlowView(
    flowKey: "onboarding",
    onComplete: { answers in
        // Example: Save answers to your backend
        if let name = answers["name"] as? String {
            UserDefaults.standard.set(name, forKey: "userName")
        }
        
        if let email = answers["email"] as? String {
            // Send to your API
            saveUserEmail(email)
        }
        
        // Navigate to next screen
        navigateToMainScreen()
    }
)
```

## Error Handling

The SDK handles errors gracefully:

- **Network errors**: Falls back to cached flow data if available
- **Invalid schema**: Displays error message with retry option
- **Configuration errors**: Returns error in completion handler

Always handle errors in your completion handlers:

```swift
FlwKit.present(
    flowKey: "onboarding",
    onComplete: { _ in },
    onExit: nil
) { result in
    switch result {
    case .success(let view):
        // Present view
        break
    case .failure(let error):
        // Handle error
        print("Error: \(error.localizedDescription)")
        // Show user-friendly error message
    }
}
```

## State Persistence

FlwKit automatically persists flow state to `UserDefaults`. If a user exits the app mid-flow, their progress will be restored when they return.

- State is keyed by `flowKey` and `userId`
- State is cleared when flow completes
- State persists across app launches

## Best Practices

1. **Configure early**: Call `FlwKit.configure()` as early as possible in your app lifecycle
2. **Handle completion**: Always implement `onComplete` to process user responses
3. **Update user ID**: If your app supports user switching, reconfigure with the new `userId`:
   ```swift
   FlwKit.configure(appId: appId, apiKey: apiKey, userId: newUserId)
   ```
4. **Test offline**: The SDK caches flows, so test offline behavior
5. **Monitor analytics**: FlwKit automatically tracks analytics events (flow_start, screen_view, answer, flow_complete, flow_exit)

## Example: Complete Integration

Here's a complete example showing how simple FlwKit integration is:

```swift
import SwiftUI
import FlwKit_ios

@main
struct MyApp: App {
    init() {
        // 1. Configure FlwKit (one line)
        FlwKit.configure(appId: "your-app-id", apiKey: "your-api-key")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            // 2. Use FlwKit (one line)
            FlwKitFlowView("first-time-onboarding") { answers in
                hasCompletedOnboarding = true
            }
        } else {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house") }
            }
        }
    }
}
```

**That's it! Just 2 lines of code:**
1. `FlwKit.configure(...)` in your App init
2. `FlwKitFlowView("flow-key")` where you need it

The package handles everything else automatically:
- ✅ Flow loading from backend
- ✅ State persistence
- ✅ Error handling with retry
- ✅ Analytics tracking
- ✅ Theme loading
- ✅ Caching

## Troubleshooting

### Package Not Found
- Ensure you've added the package to your target's dependencies
- Clean build folder (Cmd+Shift+K) and rebuild

### Configuration Errors
- Verify your `appId` and `apiKey` are correct
- Check network connectivity
- Ensure the flow key exists in your FlwKit dashboard

### View Not Appearing
- Check that you've configured FlwKit before presenting flows
- Verify the flow key is correct
- Check console for error messages

## Support

For additional support, refer to the main SDK documentation or contact your FlwKit support team.
