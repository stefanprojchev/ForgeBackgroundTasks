# ForgeBackgroundTasks

Background task scheduling and dispatch for iOS.

![Swift 6.3+](https://img.shields.io/badge/Swift-6.3+-orange.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
[![Release](https://img.shields.io/github/v/release/stefanprojchev/ForgeBackgroundTasks)](https://github.com/stefanprojchev/ForgeBackgroundTasks/releases)

---

ForgeBackgroundTasks wraps `BGTaskScheduler` in a registry-based API. Define your tasks, register them once at launch, and ForgeBackgroundTasks handles system registration, scheduling, the expiration/completion race, and automatic rescheduling.

## Features

- **`BackgroundTaskRegistry`** — handles `BGTaskScheduler.register`, request building, dispatch, and the expiration/completion race with atomic state tracking
- **`BackgroundTask`** protocol — identifier, `requiresNetwork`, `requiresProtectedData`, schedule config, and `execute(context:)` for the actual work
- **Connectivity and protected-data pre-checks** — skip tasks cleanly when the device is locked or offline
- **Automatic rescheduling** — tasks reschedule themselves on completion or expiration
- **Refresh and processing variants** — `BGAppRefreshTaskRequest` and `BGProcessingTaskRequest` via a single `BackgroundTaskSchedule` enum
- **Dependency-injected observers** — takes `ConnectivityObserving` and `ProtectedDataObserving` from [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) or your own

## Requirements

- **iOS** 18+
- **Swift** 6.3+ (Xcode 26 or later)
- Task identifiers declared in `BGTaskSchedulerPermittedIdentifiers` in Info.plist
- `processing` background mode for `.processing` schedule variants

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/stefanprojchev/ForgeBackgroundTasks.git`
3. Set rule to **Up to Next Major** from `1.0.0`

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeBackgroundTasks.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ForgeBackgroundTasks"]
    )
]
```

## Quick Start

### 1. Define a task

```swift
import ForgeBackgroundTasks

struct SyncTask: BackgroundTask {
    let identifier = "com.yourapp.sync"
    let requiresNetwork = true
    let requiresProtectedData = false
    let schedule: BackgroundTaskSchedule = .refresh(interval: 3600)

    func execute(context: BackgroundTaskContext) async {
        guard context.connectivity.isConnected else { return }

        let items = try? await api.fetchPendingUpdates()

        for item in items ?? [] {
            if context.isCancelled() { return }
            try? await process(item)
        }
    }
}
```

### 2. Register at app launch

```swift
import UIKit
import ForgeBackgroundTasks
import ForgeObservers

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let registry = BackgroundTaskRegistry(
        connectivity: ConnectivityObserver(),
        protectedData: ProtectedDataObserver()
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registry.register([
            SyncTask(),
            CleanupTask(),
        ])
        registry.registerWithSystem()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        registry.scheduleAll()
    }
}
```

### 3. Info.plist

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourapp.sync</string>
    <string>com.yourapp.cleanup</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

## Schedule variants

```swift
// Short refresh (~30s window)
.refresh(interval: 3600)

// Long-running processing task
.processing(
    requiresNetwork: true,
    requiresCharging: true,
    interval: 7200
)
```

## The Forge Family

ForgeBackgroundTasks is part of the **Forge** family of Swift packages for iOS.

| Package | Description |
|---|---|
| [ForgeCore](https://github.com/stefanprojchev/ForgeCore) | Thread-safe primitives for iOS Swift packages. |
| [ForgeInject](https://github.com/stefanprojchev/ForgeInject) | Dependency injection with constructor and property wrapper support. |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers — connectivity, lifecycle, keyboard, and more. |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe key-value, file, and Keychain storage. |
| [ForgeDB](https://github.com/stefanprojchev/ForgeDB) | Type-safe repository pattern and GRDB-backed SQLite persistence. |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Orchestrate app flows — startup gates, data pipelines, and continuous monitors. |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, and routing. |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location triggers — geofencing, significant changes, and visits. |
| **ForgeBackgroundTasks** | Background task scheduling and dispatch. |

## License

ForgeBackgroundTasks is released under the MIT License. See [LICENSE](LICENSE).
