//
//  IOUSBConfigurationDescriptorPtr+UVC.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import IOKit

extension IOUSBConfigurationDescriptorPtr {
    func proccessDescriptor() -> UVCDescriptor {
        // Defaults when parsing fails
        var processingUnitID = -1
        var cameraTerminalID = -1
        var interfaceID = -1

        let totalLength = Int(UInt16(littleEndian: self.pointee.wTotalLength))
        let configLength = Int(self.pointee.bLength)

        // Safety: configuration descriptor must fit in its reported length
        guard totalLength >= configLength, totalLength > 0 else {
            return UVCDescriptor(processingUnitID: processingUnitID,
                                 cameraTerminalID: cameraTerminalID,
                                 interfaceID: interfaceID)
        }

        // Treat the configuration descriptor as a flat byte buffer and scan through all sub-descriptors.
        let bytes = UnsafeMutablePointer<UInt8>(OpaquePointer(self))
        var offset = configLength

        // Track whether we're currently inside the VideoControl interface descriptor block.
        var inVideoControlInterface = false
        var videoControlInterfaceNumber: Int = -1

        while offset + 2 <= totalLength {
            let length = Int(bytes[offset])
            if length <= 0 || offset + length > totalLength {
                break
            }

            let descriptorType = bytes[offset + 1]

            // Standard Interface Descriptor (0x04)
            if descriptorType == kUSBInterfaceDesc, length >= 9 {
                let bInterfaceNumber = Int(bytes[offset + 2])
                let bInterfaceClass = bytes[offset + 5]
                let bInterfaceSubClass = bytes[offset + 6]

                if bInterfaceClass == UInt8(UVCConstants.classVideo) &&
                    bInterfaceSubClass == UInt8(UVCConstants.subclassVideoControl) {
                    inVideoControlInterface = true
                    videoControlInterfaceNumber = bInterfaceNumber
                    interfaceID = bInterfaceNumber
                } else {
                    inVideoControlInterface = false
                }
            }

            // Class-specific Interface Descriptor (0x24)
            if inVideoControlInterface && descriptorType == UVCConstants.descriptorTypeInterface, length >= 4 {
                let subType = bytes[offset + 2]

                // VC_INPUT_TERMINAL (0x02) – terminal id at offset 3
                if subType == UVCConstants.DescriptorSubtype.inputTerminal.rawValue {
                    cameraTerminalID = Int(bytes[offset + 3])
                }

                // VC_PROCESSING_UNIT (0x05) – unit id at offset 3
                if subType == UVCConstants.DescriptorSubtype.processingUnit.rawValue {
                    processingUnitID = Int(bytes[offset + 3])
                }

                if interfaceID != -1 && processingUnitID != -1 && cameraTerminalID != -1 {
                    return UVCDescriptor(processingUnitID: processingUnitID,
                                         cameraTerminalID: cameraTerminalID,
                                         interfaceID: interfaceID)
                }
            }

            offset += length
        }

        return UVCDescriptor(processingUnitID: processingUnitID,
                             cameraTerminalID: cameraTerminalID,
                             interfaceID: interfaceID)
    }
}
