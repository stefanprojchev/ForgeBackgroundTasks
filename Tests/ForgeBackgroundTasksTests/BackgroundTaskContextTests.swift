import Testing
import Foundation
import Synchronization
import ForgeObservers
@testable import ForgeBackgroundTasks

@Suite("BackgroundTaskContext")
struct BackgroundTaskContextTests {

    @Test("Stores constructor values")
    func storesValues() {
        let connected = ConnectivityStatus(
            isConnected: true,
            interface: .wifi,
            isExpensive: false,
            isConstrained: false
        )
        let context = BackgroundTaskContext(
            isCancelled: { false },
            connectivity: connected,
            protectedDataAvailable: true
        )

        #expect(context.protectedDataAvailable == true)
        #expect(context.connectivity.isConnected == true)
        #expect(context.connectivity.interface == .wifi)
    }

    @Test("isCancelled closure is invoked on each call")
    func isCancelledReflectsClosure() {
        let flag = Mutex(false)
        let context = BackgroundTaskContext(
            isCancelled: { flag.withLock { $0 } },
            connectivity: .disconnected,
            protectedDataAvailable: false
        )

        #expect(context.isCancelled() == false)
        flag.withLock { $0 = true }
        #expect(context.isCancelled() == true)
        flag.withLock { $0 = false }
        #expect(context.isCancelled() == false)
    }
}
