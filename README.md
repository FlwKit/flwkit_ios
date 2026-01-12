# FlwKit iOS SDK

A SwiftUI-first package that renders remote onboarding and funnel flows natively. Configure once, and all flows are managed dynamically via FlwKit.

## Features

- 🚀 **2-3 Line Integration** - Get started in minutes
- 🎨 **Dynamic Flows** - All flows loaded from FlwKit
- 💾 **State Persistence** - Automatically saves and restores user progress
- 📊 **Built-in Analytics** - Tracks flow events automatically
- 🎯 **Zero Backend Code** - Everything handled by the package
- 🔄 **Offline Support** - Caches flows for offline use

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
        FlwKit.configure(appId: "your-app-id", apiKey: "your-api-key")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Use (One Line)

Add the flow view anywhere in your SwiftUI:

```swift
import FlwKit_ios

struct OnboardingView: View {
    var body: some View {
        FlwKitFlowView("onboarding")
    }
}
```

**That's it!** Everything else (loading, state, analytics, error handling) is handled automatically.

## Usage Examples

### Basic Flow

```swift
FlwKitFlowView("welcome-onboarding")
```

### With Completion Handler

```swift
FlwKitFlowView("onboarding") { answers in
    print("User completed onboarding!")
    print("Answers: \(answers)")
    // Navigate to main screen
}
```

### With Attributes

```swift
FlwKitFlowView(
    flowKey: "onboarding",
    attributes: [
        "userId": "12345",
        "source": "app_launch",
        "campaign": "summer_2024"
    ],
    onComplete: { answers in
        // Handle completion
    }
)
```

### UIKit Integration

```swift
import UIKit
import FlwKit_ios
import SwiftUI

class ViewController: UIViewController {
    @IBAction func showOnboarding() {
        FlwKit.present(
            flowKey: "onboarding",
            onComplete: { [weak self] answers in
                print("Completed: \(answers)")
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
            }
        }
    }
}
```

## Configuration Options

### Basic Configuration

```swift
FlwKit.configure(appId: "your-app-id", apiKey: "your-api-key")
```

### With User ID

```swift
FlwKit.configure(
    appId: "your-app-id",
    apiKey: "your-api-key",
    userId: "user-123"
)
```

### With Custom Base URL

```swift
FlwKit.configure(
    appId: "your-app-id",
    apiKey: "your-api-key",
    userId: "user-123",
    baseURL: "https://custom-api.example.com"
)
```

## How It Works

1. **Configure** - Set your app credentials once
2. **Display** - Add `FlwKitFlowView` with a flow key
3. **Automatic** - The package:
   - Fetches flow data from your backend
   - Renders screens natively with SwiftUI
   - Saves user progress automatically
   - Tracks analytics events
   - Handles errors gracefully
   - Caches flows for offline use

## Flow Structure

Flows are defined in your backend and consist of:
- **Screens** - Individual steps in the flow
- **Blocks** - UI components (header, choice, text input, etc.)
- **Themes** - Styling tokens for consistent design
- **Transitions** - Navigation logic between screens

All flows are fetched dynamically - no app updates needed!

## Supported Components

- `header` - Title and subtitle
- `media` - Images and videos
- `choice` - Single or multiple choice
- `text_input` - Text fields
- `slider` - Range inputs
- `benefits_list` - Feature lists
- `testimonial` - User testimonials
- `cta` - Call-to-action buttons
- `spacer` - Spacing blocks
- `footer` - Footer content

## Analytics

FlwKit automatically tracks:
- `flow_start` - When a flow begins
- `screen_view` - Each screen viewed
- `answer` - User responses
- `flow_complete` - Flow completion
- `flow_exit` - User exits flow

All events are sent to your backend automatically.

## State Management

- Progress is automatically saved to `UserDefaults`
- If a user exits mid-flow, progress is restored on return
- State is cleared when flow completes
- Supports multiple flows simultaneously

## Error Handling

- Network errors fall back to cached flows
- Invalid schemas fail gracefully with error messages
- Retry mechanisms built-in
- User-friendly error views

## Documentation

- [Integration Guide](INTEGRATION_GUIDE.md) - Detailed integration instructions
- [SPM Setup](SPM_SETUP.md) - Swift Package Manager setup guide
- [SDK Documentation](FlwKit_SDK.md) - Technical documentation

## License

[Add your license here]

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/FlwKit/flwkit_ios/issues)
- Documentation: See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)

## Contributing

[Add contribution guidelines if applicable]
