import Foundation

/// Scheduling configuration for a background task.
///
/// Determines the task type (`BGAppRefreshTaskRequest` vs `BGProcessingTaskRequest`)
/// and scheduling interval. The `interval` is a minimum — the system decides actual timing.
public enum BackgroundTaskSchedule: Sendable {

    // MARK: - Cases

    /// Short-lived app refresh task (~30 seconds).
    /// - Parameter interval: Minimum seconds between executions. `nil` means ASAP.
    case refresh(interval: TimeInterval? = nil)

    /// Long-running processing task (minutes). Requires power.
    /// - Parameters:
    ///   - requiresNetwork: Whether the task needs connectivity.
    ///   - requiresCharging: Whether the device must be charging.
    ///   - interval: Minimum seconds between executions. `nil` means ASAP.
    case processing(
        requiresNetwork: Bool = false,
        requiresCharging: Bool = false,
        interval: TimeInterval? = nil
    )

    // MARK: - Implementation

    /// The minimum interval between executions, if set.
    public var interval: TimeInterval? {
        switch self {
        case .refresh(let interval): interval
        case .processing(_, _, let interval): interval
        }
    }
}
