import ForgeObservers
import Foundation

/// Runtime context provided to a background task during execution.
///
/// Contains cancellation check, connectivity status, and protected data availability.
/// Check `isCancelled()` periodically — the system can revoke background time at any moment.
public struct BackgroundTaskContext: Sendable {

    // MARK: - Properties

    /// Returns `true` when the system has asked the task to stop.
    public let isCancelled: @Sendable () -> Bool

    /// Network connectivity status at the time the task started.
    public let connectivity: ConnectivityStatus

    /// Whether protected data (Keychain, CoreData) is accessible.
    public let protectedDataAvailable: Bool

    // MARK: - Initialization

    /// - Parameters:
    ///   - isCancelled: Closure that returns `true` when the system revokes background time.
    ///   - connectivity: Current network connectivity status.
    ///   - protectedDataAvailable: Whether protected data is accessible.
    public init(
        isCancelled: @Sendable @escaping () -> Bool,
        connectivity: ConnectivityStatus,
        protectedDataAvailable: Bool
    ) {
        self.isCancelled = isCancelled
        self.connectivity = connectivity
        self.protectedDataAvailable = protectedDataAvailable
    }
}
