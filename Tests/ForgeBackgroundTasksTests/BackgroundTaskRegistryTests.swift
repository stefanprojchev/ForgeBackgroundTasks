import Testing
import Foundation
import ForgeObservers
@testable import ForgeBackgroundTasks

/// Tests `BackgroundTaskRegistry.register(_:)` logic in isolation.
///
/// Note: `registerWithSystem`, `schedule`, and `handleLaunch` can't be tested in a unit
/// environment because they require a real `BGTaskScheduler` with entitlements and Info.plist
/// entries. We test the registry-level logic (task storage, duplicate handling, snapshots)
/// via the internal `registeredIdentifiers` test helper.
@Suite("BackgroundTaskRegistry")
struct BackgroundTaskRegistryTests {

    // MARK: - Registration

    @Test("Registering a task adds it to the registry")
    func registersTask() {
        let registry = BackgroundTaskRegistry(
            connectivity: StubConnectivity(),
            protectedData: StubProtectedData()
        )
        registry.register(MockBackgroundTask(identifier: "com.app.refresh"))

        #expect(registry.isRegistered("com.app.refresh"))
        #expect(registry.registeredIdentifiers.count == 1)
    }

    @Test("Registering the same identifier twice keeps the first task")
    func duplicateRegistrationIsIgnored() {
        let registry = BackgroundTaskRegistry(
            connectivity: StubConnectivity(),
            protectedData: StubProtectedData()
        )
        registry.register(MockBackgroundTask(identifier: "com.app.refresh", requiresNetwork: false))
        registry.register(MockBackgroundTask(identifier: "com.app.refresh", requiresNetwork: true))

        #expect(registry.registeredIdentifiers.count == 1)
    }

    @Test("Registering an array registers each task")
    func registerArray() {
        let registry = BackgroundTaskRegistry(
            connectivity: StubConnectivity(),
            protectedData: StubProtectedData()
        )
        registry.register([
            MockBackgroundTask(identifier: "com.app.refresh"),
            MockBackgroundTask(identifier: "com.app.processing"),
            MockBackgroundTask(identifier: "com.app.cleanup"),
        ])

        #expect(registry.registeredIdentifiers.count == 3)
        #expect(registry.isRegistered("com.app.refresh"))
        #expect(registry.isRegistered("com.app.processing"))
        #expect(registry.isRegistered("com.app.cleanup"))
    }

    @Test("Registering an array with duplicates deduplicates by identifier")
    func registerArrayDedupes() {
        let registry = BackgroundTaskRegistry(
            connectivity: StubConnectivity(),
            protectedData: StubProtectedData()
        )
        registry.register([
            MockBackgroundTask(identifier: "com.app.refresh"),
            MockBackgroundTask(identifier: "com.app.refresh"),
            MockBackgroundTask(identifier: "com.app.refresh"),
        ])

        #expect(registry.registeredIdentifiers.count == 1)
    }

    // MARK: - Concurrency

    @Test("Concurrent registrations do not crash and preserve unique identifiers")
    func concurrentRegistrations() async {
        let registry = BackgroundTaskRegistry(
            connectivity: StubConnectivity(),
            protectedData: StubProtectedData()
        )

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    registry.register(MockBackgroundTask(identifier: "com.app.task.\(i)"))
                }
            }
        }

        #expect(registry.registeredIdentifiers.count == 100)
    }

    @Test("Concurrent duplicate registrations result in a single entry")
    func concurrentDuplicates() async {
        let registry = BackgroundTaskRegistry(
            connectivity: StubConnectivity(),
            protectedData: StubProtectedData()
        )

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    registry.register(MockBackgroundTask(identifier: "com.app.shared"))
                }
            }
        }

        #expect(registry.registeredIdentifiers.count == 1)
    }
}

// MARK: - Mocks

private struct MockBackgroundTask: BackgroundTask {
    let identifier: String
    let requiresNetwork: Bool
    let requiresProtectedData: Bool
    let schedule: BackgroundTaskSchedule

    init(
        identifier: String,
        requiresNetwork: Bool = false,
        requiresProtectedData: Bool = false,
        schedule: BackgroundTaskSchedule = .refresh()
    ) {
        self.identifier = identifier
        self.requiresNetwork = requiresNetwork
        self.requiresProtectedData = requiresProtectedData
        self.schedule = schedule
    }

    func execute(context: BackgroundTaskContext) async {
        // No-op for tests — the system never calls this in unit tests.
    }
}

private struct StubConnectivity: ConnectivityObserving {
    var status: ConnectivityStatus {
        ConnectivityStatus(isConnected: true, interface: .wifi, isExpensive: false, isConstrained: false)
    }
    var statusStream: AsyncStream<ConnectivityStatus> {
        AsyncStream { continuation in continuation.finish() }
    }
}

private struct StubProtectedData: ProtectedDataObserving {
    var state: ProtectedDataState { .available }
    var stateStream: AsyncStream<ProtectedDataState> {
        AsyncStream { continuation in continuation.finish() }
    }
    func waitUntilAvailable() async {}
}
