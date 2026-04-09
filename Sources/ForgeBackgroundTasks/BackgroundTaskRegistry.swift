import BackgroundTasks
import ForgeCore
import ForgeObservers
import OSLog
import UIKit

/// Manages registration, scheduling, and dispatch of `BGTaskScheduler` background tasks.
///
/// Handles system registration, request building, connectivity/protected data pre-checks,
/// expiration handling, and automatic rescheduling.
///
/// Thread-safe via `LockedState`. Task `execute()` runs on a background `Task`.
public final class BackgroundTaskRegistry: Sendable {

    // MARK: - Properties

    private let logger = Logger(subsystem: "core.background", category: "registry")
    private let tasks = LockedState<[String: any BackgroundTask]>([:])
    private let connectivity: ConnectivityObserving
    private let protectedData: ProtectedDataObserving

    // MARK: - Initialization

    /// - Parameters:
    ///   - connectivity: Observer for network status pre-checks.
    ///   - protectedData: Observer for protected data availability pre-checks.
    public init(
        connectivity: ConnectivityObserving,
        protectedData: ProtectedDataObserving
    ) {
        self.connectivity = connectivity
        self.protectedData = protectedData
    }

    // MARK: - Implementation

    /// Registers a background task. Call before `registerWithSystem()`.
    /// - Parameter task: The task to register. Its `identifier` must match `BGTaskSchedulerPermittedIdentifiers`.
    public func register(_ task: any BackgroundTask) {
        tasks.withLock {
            guard $0[task.identifier] == nil else {
                logger.warning("Duplicate task identifier '\(task.identifier)' — skipping")
                return
            }
            $0[task.identifier] = task
            logger.debug("Registered: \(task.identifier)")
        }
    }

    /// Registers multiple tasks at once.
    public func register(_ tasks: [any BackgroundTask]) {
        for task in tasks {
            register(task)
        }
    }

    /// Registers all tasks with `BGTaskScheduler`. Must be called during app launch.
    public func registerWithSystem() {
        let snapshot = tasks.withLock { $0 }

        for identifier in snapshot.keys {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: identifier,
                using: nil
            ) { [weak self] bgTask in
                self?.handleLaunch(bgTask)
            }
            logger.info("Registered with BGTaskScheduler: \(identifier)")
        }
    }

    /// Schedules a specific task for future execution.
    /// - Parameters:
    ///   - identifier: The task identifier to schedule.
    ///   - earliestBeginDate: Override the earliest begin date. If `nil`, uses the task's schedule interval.
    public func schedule(_ identifier: String, earliestBeginDate: Date? = nil) throws {
        guard let task = tasks.withLock({ $0[identifier] }) else {
            logger.error("Cannot schedule unknown task: \(identifier)")
            return
        }

        let request = buildRequest(for: task, earliestBeginDate: earliestBeginDate)

        try BGTaskScheduler.shared.submit(request)
        logger.info("Scheduled: \(identifier) (earliest: \(request.earliestBeginDate?.description ?? "ASAP"))")
    }

    /// Schedules all registered tasks. Continues if one fails.
    public func scheduleAll() {
        let snapshot = tasks.withLock { $0 }

        for identifier in snapshot.keys {
            do {
                try schedule(identifier)
            } catch {
                logger.error("Failed to schedule \(identifier): \(error.localizedDescription)")
            }
        }
    }

    /// Cancels a scheduled task.
    public func cancel(_ identifier: String) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        logger.info("Cancelled: \(identifier)")
    }

    /// Cancels all scheduled tasks.
    public func cancelAll() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        logger.info("Cancelled all tasks")
    }

    // MARK: - Internal (Test Helpers)

    /// Identifiers of all currently-registered tasks. Used by tests to verify registration state.
    internal var registeredIdentifiers: [String] {
        tasks.withLock { Array($0.keys) }
    }

    /// Whether a task with the given identifier is currently registered.
    internal func isRegistered(_ identifier: String) -> Bool {
        tasks.withLock { $0[identifier] != nil }
    }

    // MARK: - Private

    private func handleLaunch(_ bgTask: BGTask) {
        let identifier = bgTask.identifier

        guard let task = tasks.withLock({ $0[identifier] }) else {
            logger.error("Launched unknown task: \(identifier)")
            bgTask.setTaskCompleted(success: false)
            return
        }

        logger.info("Launched: \(identifier)")

        if task.requiresProtectedData && protectedData.state == .unavailable {
            logger.warning("Skipping \(identifier) — protected data unavailable (device locked)")
            bgTask.setTaskCompleted(success: false)
            reschedule(task)
            return
        }

        let currentConnectivity = connectivity.status
        if task.requiresNetwork && !currentConnectivity.isConnected {
            logger.warning("\(identifier) requires network but device is offline — task will decide whether to proceed")
        }

        let cancelled = LockedState(false)
        let finished = LockedState(false)

        let context = BackgroundTaskContext(
            isCancelled: { cancelled.withLock { $0 } },
            connectivity: currentConnectivity,
            protectedDataAvailable: protectedData.state == .available
        )

        let work = Task {
            await task.execute(context: context)
        }

        nonisolated(unsafe) let bgTaskRef = bgTask

        bgTaskRef.expirationHandler = { [logger] in
            logger.warning("System expired: \(identifier)")
            cancelled.withLock { $0 = true }
            work.cancel()
            let alreadyFinished = finished.withLock { prev -> Bool in
                if prev { return true }
                prev = true
                return false
            }
            if !alreadyFinished {
                bgTaskRef.setTaskCompleted(success: false)
            }
        }

        Task { [logger, weak self] in
            await work.value
            let alreadyFinished = finished.withLock { prev -> Bool in
                if prev { return true }
                prev = true
                return false
            }
            if !alreadyFinished {
                let success = !cancelled.withLock({ $0 })
                bgTaskRef.setTaskCompleted(success: success)
            }
            logger.info("Completed: \(identifier) (success: \(!cancelled.withLock({ $0 })))")
            self?.reschedule(task)
        }
    }

    private func buildRequest(for task: any BackgroundTask, earliestBeginDate: Date? = nil) -> BGTaskRequest {
        switch task.schedule {
        case .refresh(let interval):
            let request = BGAppRefreshTaskRequest(identifier: task.identifier)
            request.earliestBeginDate = earliestBeginDate ?? interval.map { Date(timeIntervalSinceNow: $0) }
            return request

        case .processing(let requiresNetwork, let requiresCharging, let interval):
            let request = BGProcessingTaskRequest(identifier: task.identifier)
            request.requiresNetworkConnectivity = requiresNetwork
            request.requiresExternalPower = requiresCharging
            request.earliestBeginDate = earliestBeginDate ?? interval.map { Date(timeIntervalSinceNow: $0) }
            return request
        }
    }

    private func reschedule(_ task: any BackgroundTask) {
        do {
            try schedule(task.identifier)
        } catch {
            logger.error("Failed to reschedule \(task.identifier): \(error.localizedDescription)")
        }
    }
}
