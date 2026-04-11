# FlwKit iOS SDK

<img src="https://img.shields.io/badge/SwiftPM-Compatible-orange" alt="SwiftPM Compatible">
<img src="https://img.shields.io/badge/pod-compatible-informational" alt="Cocoapods Compatible">
<img src="https://img.shields.io/badge/ios%20version-%3E%3D%2015.0-blueviolet" alt="iOS Versions Supported">
<img src="https://img.shields.io/badge/license-MIT-green/" alt="MIT License">
<img src="https://img.shields.io/badge/community-active-9cf" alt="Community Active">
<img src="https://img.shields.io/github/v/tag/FlwKit/flwkit_ios" alt="Version Number">

A SwiftUI-first package that renders remote onboarding and funnel flows natively. Configure once, and all flows are managed dynamically via FlwKit.

## Features

- 🚀 **2-3 Line Integration** - Get started in minutes
- 🎨 **Dynamic Flows** - All flows loaded from FlwKit backend
- 💾 **State Persistence** - Automatically saves and restores user progress
- 📊 **Built-in Analytics** - Tracks flow events automatically
- 🎯 **Zero Backend Code** - Everything handled by the package
- 🔄 **Offline Support** - Caches flows for offline use
- 🧪 **A/B Testing** - Automatic variant assignment and tracking
- 🔐 **API Key Based** - App ID automatically extracted from API key

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+

## Installation

### Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/FlwKit/flwkit_ios.git
   ```
3. Select version `0.1.0` or later
4. Add to your target

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/FlwKit/flwkit_ios.git", from: "0.1.0")
]
```

## Quick Start

### 1. Configure (One Line)

In your `App` or `AppDelegate`, configure FlwKit:

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

**Important Notes:**
- The app ID is automatically extracted from your API key by the backend
- Only one flow can be active at a time per app
- The active flow is automatically fetched based on your API key
- No `flowKey` parameter is needed - the SDK fetches the active flow automatically

### 2. Use (One Line)

Add the flow view anywhere in your SwiftUI:

```swift
import FlwKit_ios

struct OnboardingView: View {
    var body: some View {
        FlwKitFlowView()
    }
}
```

**That's it!** The active flow is automatically fetched from your backend. Everything else (loading, state, analytics, error handling) is handled automatically.

## Usage Examples

### Basic Flow

The simplest usage - just add the view:

```swift
FlwKitFlowView()
```

### With Completion Handler

Handle flow completion and get all collected answers:

```swift
FlwKitFlowView { result in
    print("Flow completed: \(result.flowId)")
    print("Variant: \(result.variantId ?? "none")")
    print("Completed at: \(result.completedAt)")
    print("Answers: \(result.answers)")
    
    // Navigate to main screen
    router.navigate(to: .home)
}
```

The completion callback receives a `FlwKitCompletionResult` containing:
- `flowId`: The flow identifier (flowKey)
- `variantId`: A/B test variant ID (if user was in an A/B test, `nil` otherwise)
- `completedAt`: Timestamp when the flow was completed
- `answers`: Dictionary of all answers collected from each screen (keys are block keys, values are user answers mapped to their labels/content, not just IDs)

## Permission blocks

If your flow includes permission blocks, add the matching Info.plist keys in your app target:

| Block type | Info.plist key |
|------------|----------------|
| `notification_permission` | No key needed |
| `health_permission` | `NSHealthShareUsageDescription` |
| `tracking_permission` | `NSUserTrackingUsageDescription` |
| `camera_permission` | `NSCameraUsageDescription` |
| `location_permission` | `NSLocationWhenInUseUsageDescription` |
| `microphone_permission` | `NSMicrophoneUsageDescription` |
| `photo_library_permission` | `NSPhotoLibraryUsageDescription` |

Important behavior:
- Permission blocks always advance the user to the next step (or complete flow if configured), even when permission is denied.
- The SDK safely skips requests when required Info.plist keys are missing, to avoid runtime crashes.

Entitlements:
- `health_permission` requires enabling **HealthKit** capability.
- `tracking_permission` requires **App Tracking Transparency** support and proper App Store policy setup.
