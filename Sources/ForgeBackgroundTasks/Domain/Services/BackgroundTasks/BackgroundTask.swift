import Foundation

/// A unit of work executed in the background via `BGTaskScheduler`.
///
/// Each task's `identifier` must match an entry in `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
/// Task type (refresh ~30s vs processing minutes) is determined by `schedule`.
public protocol BackgroundTask: Sendable {
    /// Unique identifier matching `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
    var identifier: String { get }

    /// Whether this task needs network connectivity to do useful work.
    var requiresNetwork: Bool { get }

    /// Whether this task accesses protected data (Keychain, CoreData, encrypted files).
    /// If `true` and the device is locked, the task is skipped.
    var requiresProtectedData: Bool { get }

    /// Scheduling configuration. Determines task type and interval.
    var schedule: BackgroundTaskSchedule { get }

    /// Performs the background work. Check `context.isCancelled()` periodically.
    func execute(context: BackgroundTaskContext) async
}
