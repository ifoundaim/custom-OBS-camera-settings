import XCTest
@testable import UVC

final class UVCDescriptorParsingTests: XCTestCase {
    func testParsesVideoControlInterfaceAndUnitIDs() {
        // Minimal synthetic configuration descriptor blob:
        // - Configuration descriptor (9 bytes) with wTotalLength
        // - Interface descriptor (VideoControl, interface #2)
        // - CS_INTERFACE VC_INPUT_TERMINAL (terminal id 3)
        // - CS_INTERFACE VC_PROCESSING_UNIT (unit id 5)
        //
        // We only need enough bytes for our byte-scanning parser.
        let totalLength: UInt16 = 9 + 9 + 8 + 8
        let totalLengthLE0 = UInt8(totalLength & 0xFF)
        let totalLengthLE1 = UInt8((totalLength >> 8) & 0xFF)

        var bytes: [UInt8] = [
            // Configuration descriptor
            9, 0x02, totalLengthLE0, totalLengthLE1, 1, 1, 0, 0x80, 50,

            // Interface descriptor (length 9, type 0x04)
            9, 0x04,
            2, // bInterfaceNumber
            0, // bAlternateSetting
            1, // bNumEndpoints
            0x0E, // bInterfaceClass (Video)
            0x01, // bInterfaceSubClass (VideoControl)
            0x00, // bInterfaceProtocol
            0, // iInterface

            // CS_INTERFACE - VC_INPUT_TERMINAL (length 8, type 0x24, subtype 0x02)
            8, 0x24, 0x02,
            3, // bTerminalID
            0, 0, 0, 0, // padding

            // CS_INTERFACE - VC_PROCESSING_UNIT (length 8, type 0x24, subtype 0x05)
            8, 0x24, 0x05,
            5, // bUnitID
            0, 0, 0, 0 // padding
        ]

        // Allocate raw memory for the descriptor and bind it to IOUSBConfigurationDescriptorPtr.
        let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
        ptr.initialize(from: &bytes, count: bytes.count)
        defer { ptr.deallocate() }

        let configPtr = IOUSBConfigurationDescriptorPtr(OpaquePointer(ptr))
        let desc = configPtr.proccessDescriptor()

        XCTAssertEqual(desc.interfaceID, 2)
        XCTAssertEqual(desc.cameraTerminalID, 3)
        XCTAssertEqual(desc.processingUnitID, 5)
    }
}


