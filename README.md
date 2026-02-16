# FlwKit iOS SDK

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
3. Select version `1.0.0` or later
4. Add to your target

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/FlwKit/flwkit_ios.git", from: "1.0.0")
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

### With Attributes

Pass additional attributes to the flow:

```swift
FlwKitFlowView(
    attributes: [
        "userId": "12345",
        "source": "app_launch",
        "campaign": "summer_2024",
        "platform": "ios"
    ],
    onComplete: { result in
        // Handle completion with full result
        processAnswers(result.answers)
    }
)
```

### With Exit Handler

Handle when a user exits the flow:

```swift
FlwKitFlowView(
    onComplete: { result in
        // Flow completed successfully
        handleCompletion(result)
    },
    onExit: {
        // User exited the flow (e.g., tapped back button)
        handleExit()
    }
)
```

### Full Control

Combine all options:

```swift
FlwKitFlowView(
    attributes: [
        "userId": currentUser.id,
        "source": "onboarding"
    ],
    onComplete: { result in
        // Process completion
        saveAnswers(result.answers)
        navigateToHome()
    },
    onExit: {
        // Handle exit
        trackExit()
    }
)
```

### UIKit Integration

For UIKit apps, use the programmatic API:

```swift
import UIKit
import FlwKit_ios
import SwiftUI

class ViewController: UIViewController {
    @IBAction func showOnboarding() {
        FlwKit.present(
            attributes: [
                "userId": "12345",
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
                // Handle error (show alert, etc.)
            }
        }
    }
}
```

## Configuration Options

### Basic Configuration

```swift
FlwKit.configure(apiKey: "your-api-key")
```

### With User ID

Set a user ID for user-specific flows and analytics:

```swift
FlwKit.configure(
    apiKey: "your-api-key",
    userId: "user-123"
)
```

**Note:** You can also pass `userId` via attributes when presenting a flow, which will override the configured user ID for that specific flow.

### With Custom Base URL

Use a custom API endpoint:

```swift
FlwKit.configure(
    apiKey: "your-api-key",
    userId: "user-123",
    baseURL: "https://custom-api.example.com"
)
```

**Default Base URL:** `https://api.flwkit.com`

## How It Works

1. **Configure** - Set your API key once (app ID is extracted automatically from the API key)
2. **Display** - Add `FlwKitFlowView` (active flow is fetched automatically)
3. **Automatic** - The package:
   - Fetches the active flow from `/sdk/v1/flow` endpoint
   - Checks for A/B tests using the flow's `flowKey` at `/sdk/v1/ab-tests/:flowKey`
   - Uses A/B test variant if available (variant assignment is cached for consistency)
   - Renders screens natively with SwiftUI
   - Saves user progress automatically to `UserDefaults`
   - Tracks analytics events (flow_start, screen_view, answer, flow_complete, flow_abandoned)
   - Handles errors gracefully with fallback to cached flows
   - Returns completion results with all answers mapped to their labels/content

## Flow Structure

Flows are defined in your backend and consist of:
- **Screens** - Individual steps in the flow (ordered array)
- **Blocks** - UI components (header, choice, text input, etc.)
- **Themes** - Styling tokens for consistent design
- **Entry Screen** - The starting screen of the flow

All flows are fetched dynamically - no app updates needed!

## Supported Block Types

- `header` - Title and subtitle with customizable styling
- `media` - Images and videos
- `choice` - Single or multiple choice options
- `text_input` - Text fields with validation
- `slider` - Range inputs
- `benefits_list` - Feature lists
- `testimonial` - User testimonials
- `cta` - Call-to-action buttons (primary and secondary)
- `spacer` - Spacing blocks
- `footer` - Footer content
- `progress_bar` - Progress indicator

## Analytics

FlwKit automatically tracks the following events:

### Event Types

- `flow_start` - When a flow begins (includes flowId, flowVersionId, experimentId, variantId, sessionId, userId)
- `screen_view` - Each screen viewed (includes screenId, screenName, screenIndex, totalScreens)
- `answer` - User responses to questions (includes screenId, key, value)
- `flow_complete` - Flow completion (includes all answers and metadata)
- `flow_abandoned` - User exits flow before completion (includes lastScreenId, screensCompleted, timeSpent)

### Analytics Features

- **Session Management** - Automatic session ID generation per flow
- **A/B Test Context** - All events include `experimentId` and `variantId` when applicable
- **Offline Queue** - Events are queued when offline and sent when connection is restored
- **Retry Logic** - Automatic retry for rate-limited (429) and server errors (5xx)
- **Event Sequencing** - Events are sent in the correct order (flow_start before screen_view)

All events are sent to `/sdk/v1/analytics/events` endpoint automatically.

## State Management

- **Progress Persistence** - Progress is automatically saved to `UserDefaults`
- **State Restoration** - If a user exits mid-flow, progress is restored on return
- **State Clearing** - State is cleared when flow completes
- **Multi-Flow Support** - Supports multiple flows simultaneously (state is keyed by flowKey and userId)

## A/B Testing

FlwKit automatically handles A/B testing:

1. When a flow is fetched, the SDK checks for A/B tests using the flow's `flowKey`
2. If an A/B test exists, a variant is assigned using consistent hashing (based on userId or sessionId)
3. The variant assignment is cached to ensure consistency across sessions
4. The variant's `flowData` is used instead of the base flow
5. All analytics events include `experimentId` and `variantId` when in an A/B test

**Note:** A/B test variants take priority over the base flow. If a variant is assigned, its `flowData` is used.

## Error Handling

The SDK handles errors gracefully:

- **Network Errors** - Falls back to cached flows when available
- **401/403 Errors** - Returns error (invalid API key or unauthorized)
- **404 Errors** - Returns `flowNotFound` error (no active flow found)
- **Invalid Schemas** - Fails gracefully with error messages
- **Retry Mechanisms** - Built-in retry for analytics events
- **User-Friendly Views** - Error views with retry options

### Error Types

- `notConfigured` - FlwKit.configure() not called
- `invalidURL` - Invalid API endpoint URL
- `invalidResponse` - Server response couldn't be decoded
- `noData` - No data received from server
- `httpError(Int)` - HTTP error with status code
- `flowNotFound` - No active flow found for the app
- `themeNotFound` - Theme not found in flow

## Answer Mapping

When a flow completes, answers are automatically mapped from IDs to their human-readable labels/content:

- **Choice Options** - Option IDs are mapped to their label text
- **Text Inputs** - Raw text values are returned as-is
- **Other Block Types** - Values are returned in their original format

Example:
```swift
// Before mapping: ["choice_123": "option1"]
// After mapping: ["choice_123": "Yes, I'm interested"]
```

## Background Rendering

The SDK supports both solid colors and linear gradients for backgrounds:

- **Screen-Level Backgrounds** - Individual screens can override theme backgrounds
- **Theme-Level Backgrounds** - Default backgrounds defined in themes
- **Priority** - Screen backgrounds override theme backgrounds
- **Gradient Support** - Linear gradients with customizable colors, opacity, and angles

## Styling

### Header Block Subtitle

Header blocks support independent subtitle styling:

- `subtitleColor` - Custom subtitle color (hex)
- `subtitleOpacity` - Subtitle opacity (0-100)
- `subtitleFontSize` - Subtitle font size in pixels
- `subtitleAlign` - Subtitle alignment (left, center, right)
- `subtitleSpacing` - Letter spacing for subtitle

### Theme Tokens

Themes support comprehensive styling tokens:

- Colors (primary, secondary, background, text, etc.)
- Typography (font families, sizes, weights)
- Spacing (padding, margins, corner radius)
- And more...

## Documentation

- [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md) - Complete user-facing guide with examples and best practices
- [Existing App Integration](docs/EXISTING_APP_INTEGRATION.md) - Step-by-step guide for integrating into existing iOS apps

## License

[Add your license here]

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/FlwKit/flwkit_ios/issues)
- Documentation: See [IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md)

## Contributing

[Add contribution guidelines if applicable]
