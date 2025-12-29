import XCTest
@testable import CameraController

final class DevicesManagerSelectionTests: XCTestCase {
    func testPicksLastSelectedWhenPresent() {
        let candidates: [DevicesManager.DeviceSelectionCandidate] = [
            .init(uniqueID: "a", isConfigurable: false),
            .init(uniqueID: "b", isConfigurable: true),
            .init(uniqueID: "c", isConfigurable: true)
        ]

        let index = DevicesManager.pickDefaultCandidateIndex(candidates, lastSelectedDeviceId: "c")
        XCTAssertEqual(index, 2)
    }

    func testFallsBackToFirstConfigurableWhenLastSelectedMissing() {
        let candidates: [DevicesManager.DeviceSelectionCandidate] = [
            .init(uniqueID: "a", isConfigurable: false),
            .init(uniqueID: "b", isConfigurable: true),
            .init(uniqueID: "c", isConfigurable: true)
        ]

        let index = DevicesManager.pickDefaultCandidateIndex(candidates, lastSelectedDeviceId: "missing")
        XCTAssertEqual(index, 1)
    }

    func testFallsBackToFirstDeviceWhenNoneConfigurable() {
        let candidates: [DevicesManager.DeviceSelectionCandidate] = [
            .init(uniqueID: "a", isConfigurable: false),
            .init(uniqueID: "b", isConfigurable: false)
        ]

        let index = DevicesManager.pickDefaultCandidateIndex(candidates, lastSelectedDeviceId: nil)
        XCTAssertEqual(index, 0)
    }

    func testReturnsNilWhenNoDevices() {
        let index = DevicesManager.pickDefaultCandidateIndex([], lastSelectedDeviceId: nil)
        XCTAssertNil(index)
    }
}


