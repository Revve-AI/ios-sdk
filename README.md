# RevveAI iOS SDK

A Swift SDK for integrating RevveAI voice assistants into your iOS applications.

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.5+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/revve-ai-ios-sdk.git", from: "1.0.0")
]
```

Or add it through Xcode's package dependency manager.

## Usage

### Initialization

```swift
import RevveAI

let revveAI = RevveAI(apiKey: "your-api-key-here")
revveAI.delegate = self // Optional: Implement RevveAIDelegate
```

### Starting a Call

```swift
revveAI.start(assistantId: "your-assistant-id") { result in
    switch result {
    case .success:
        print("Call started successfully")
    case .failure(let error):
        print("Failed to start call: \(error.localizedDescription)")
    }
}
```

### Stopping a Call

```swift
revveAI.stop { result in
    switch result {
    case .success:
        print("Call ended successfully")
    case .failure(let error):
        print("Failed to end call: \(error.localizedDescription)")
    }
}
```

### Handling Call Events

Implement the `RevveAIDelegate` protocol to receive call events:

```swift
extension YourViewController: RevveAIDelegate {
    func revveAIDidStartCall(_ revveAI: RevveAI) {
        print("Call started")
    }
    
    func revveAIDidEndCall(_ revveAI: RevveAI) {
        print("Call ended")
    }
    
    func revveAI(_ revveAI: RevveAI, didFailWithError error: Error) {
        print("Call failed with error: \(error.localizedDescription)")
    }
}
```

## Error Handling

The SDK provides various error types through the `RevveAIError` enum. Always handle these errors appropriately in your application.

## License

This SDK is proprietary software. All rights reserved.
