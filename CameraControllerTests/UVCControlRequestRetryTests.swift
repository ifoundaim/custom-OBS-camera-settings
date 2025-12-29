import XCTest
import IOKit.usb
@testable import UVC

final class UVCControlRequestRetryTests: XCTestCase {
    private struct TestSelector: Selector {
        let value: Int
        func raw() -> Int { value }
    }

    func testControlRequestRetriesAfterOpeningInterface() throws {
        // Dummy interface pointer (never dereferenced by our injected callouts).
        typealias USBInterfacePointer = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface190>>
        let outer = USBInterfacePointer.allocate(capacity: 1)
        let inner = UnsafeMutablePointer<IOUSBInterfaceInterface190>.allocate(capacity: 1)
        outer.initialize(to: inner)
        defer {
            outer.deinitialize(count: 1)
            inner.deallocate()
            outer.deallocate()
        }

        var calls: [String] = []
        var controlCount = 0

        let callouts = UVCControl.USBInterfaceCallouts(
            controlRequest: { _ in
                calls.append("control")
                controlCount += 1
                // Fail first request, succeed second.
                return controlCount == 1 ? -1 : kIOReturnSuccess
            },
            open: {
                calls.append("open")
                return kIOReturnSuccess
            },
            openSeize: {
                calls.append("openSeize")
                return kIOReturnSuccess
            },
            close: {
                calls.append("close")
                return kIOReturnSuccess
            }
        )

        let control = UVCControl(outer, 1, TestSelector(value: 1), 1, 1, callouts: callouts)

        // Any request path triggers performRequest internally; updateIsCapable uses getInfo.
        control.updateIsCapable()

        // Should attempt control request, then openSeize, then control again, then close.
        XCTAssertEqual(calls, ["control", "openSeize", "control", "close"])
        XCTAssertTrue(control.isCapable)
    }
}


