# ForgeBackgroundTasks

BGTaskScheduler registration, scheduling, and dispatch for iOS.

## Requirements

- iOS 16+
- Swift 6.0+

## Installation

### Swift Package Manager

Add ForgeBackgroundTasks to your project via Xcode:

1. **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select the version rule and add to your target

Or add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeBackgroundTasks.git", from: "1.0.0")
]
```

## Quick Start

```swift
import ForgeBackgroundTasks

// 1. Define a task
struct DataSyncTask: BackgroundTask {
    let identifier = "com.myapp.sync"
    let requiresNetwork = true
    let requiresProtectedData = true
    let schedule: BackgroundTaskSchedule = .processing(
        requiresNetwork: true,
        interval: 3600
    )

    func execute(context: BackgroundTaskContext) async {
        guard !context.isCancelled() else { return }
        await syncData()
    }
}

// 2. Register and schedule
let registry = BackgroundTaskRegistry(
    connectivity: connectivityObserver,
    protectedData: protectedDataObserver
)
registry.register(DataSyncTask())
registry.registerWithSystem() // Call during app launch
try registry.schedule("com.myapp.sync")
```

## BackgroundTask Protocol

Each task provides its identifier, requirements, schedule, and execution logic:

```swift
protocol BackgroundTask: Sendable {
    var identifier: String { get }
    var requiresNetwork: Bool { get }
    var requiresProtectedData: Bool { get }
    var schedule: BackgroundTaskSchedule { get }
    func execute(context: BackgroundTaskContext) async
}
```

The `identifier` must match an entry in `BGTaskSchedulerPermittedIdentifiers` in your Info.plist.

## BackgroundTaskSchedule

Determines the task type and interval:

| Schedule | Task type | Duration | Use case |
|----------|-----------|----------|----------|
| `.refresh(interval:)` | `BGAppRefreshTaskRequest` | ~30 seconds | Token refresh, feed updates |
| `.processing(requiresNetwork:requiresCharging:interval:)` | `BGProcessingTaskRequest` | Minutes | Data sync, cleanup, ML training |

The `interval` is a minimum — the system decides actual timing.

## BackgroundTaskContext

Runtime context provided during execution:

- `isCancelled()` — check periodically; the system can revoke background time at any moment
- `connectivity` — network status at task start
- `protectedDataAvailable` — whether Keychain/encrypted files are accessible

## BackgroundTaskRegistry

The registry handles the full lifecycle:

1. **Register** tasks with `register(_:)` before app finishes launching
2. **Register with system** via `registerWithSystem()` — calls `BGTaskScheduler.shared.register`
3. **Schedule** with `schedule(_:)` or `scheduleAll()`
4. **Dispatch** — the registry handles launch callbacks, pre-checks (network, protected data), expiration, and automatic rescheduling

```swift
registry.register([DataSyncTask(), CacheCleanupTask()])
registry.registerWithSystem()
registry.scheduleAll()

// Cancel specific or all
registry.cancel("com.myapp.sync")
registry.cancelAll()
```

## Thread Safety

`BackgroundTaskRegistry` is `Sendable`. All mutable state is protected with `LockedState`. Task `execute()` runs on a background `Task`.

## Forge Ecosystem

ForgeBackgroundTasks is part of the **Forge** family of Swift packages for iOS:

| Package | Description |
|---------|-------------|
| [ForgeCore](https://github.com/stefanprojchev/ForgeCore) | Thread-safe utilities — `LockedState` and `SendableFileManager` |
| [ForgeInject](https://github.com/stefanprojchev/ForgeInject) | Lightweight dependency injection with property wrapper |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers (connectivity, lifecycle, keyboard, and more) |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe persistence — key-value, file storage, and Keychain |
| **ForgeBackgroundTasks** | BGTaskScheduler registration, scheduling, and dispatch |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location-based triggers — geofencing, significant changes, visits |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, silent and visible routing |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Sequence, pipeline, and monitor orchestrators for iOS app flows |

## License

MIT License. See [LICENSE](LICENSE) for details.
