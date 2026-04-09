import Testing
import Foundation
@testable import ForgeBackgroundTasks

@Suite("BackgroundTaskSchedule")
struct BackgroundTaskScheduleTests {

    // MARK: - Interval Extraction

    @Test("refresh with nil interval returns nil")
    func refreshNilInterval() {
        let schedule = BackgroundTaskSchedule.refresh()
        #expect(schedule.interval == nil)
    }

    @Test("refresh with explicit interval returns it")
    func refreshExplicitInterval() {
        let schedule = BackgroundTaskSchedule.refresh(interval: 3600)
        #expect(schedule.interval == 3600)
    }

    @Test("processing with nil interval returns nil")
    func processingNilInterval() {
        let schedule = BackgroundTaskSchedule.processing()
        #expect(schedule.interval == nil)
    }

    @Test("processing with explicit interval returns it")
    func processingExplicitInterval() {
        let schedule = BackgroundTaskSchedule.processing(
            requiresNetwork: true,
            requiresCharging: true,
            interval: 7200
        )
        #expect(schedule.interval == 7200)
    }

    // MARK: - Defaults

    @Test("processing defaults do not require network or charging")
    func processingDefaults() {
        let schedule = BackgroundTaskSchedule.processing()
        if case .processing(let network, let charging, _) = schedule {
            #expect(network == false)
            #expect(charging == false)
        } else {
            Issue.record("Expected .processing case")
        }
    }
}
