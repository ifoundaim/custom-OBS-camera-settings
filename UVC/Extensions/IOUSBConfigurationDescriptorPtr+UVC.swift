//
//  IOUSBConfigurationDescriptorPtr+UVC.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import IOKit
import os.log

extension IOUSBConfigurationDescriptorPtr {
    func proccessDescriptor() -> UVCDescriptor {
        // Defaults when parsing fails
        var processingUnitID = -1
        var cameraTerminalID = -1
        var interfaceID = -1

        let rawTotalLength = Int(self.pointee.wTotalLength)
        let totalLength = Int(UInt16(littleEndian: self.pointee.wTotalLength))
        let configLength = Int(self.pointee.bLength)

        // Treat the configuration descriptor as a flat byte buffer.
        let bytes = UnsafeMutablePointer<UInt8>(OpaquePointer(self))

        if ProcessInfo.processInfo.environment["UVC_DEBUG"] == "1" {
            let log = OSLog(subsystem: "UVC", category: "Descriptor")
            os_log(
                "UVC_DEBUG: config bLength=%{public}d wTotalLength(raw)=%{public}d wTotalLength(le)=%{public}d",
                log: log,
                type: .info,
                configLength,
                rawTotalLength,
                totalLength
            )
        }

        // Safety: configuration descriptor must fit in its reported length
        guard totalLength >= configLength, totalLength > 0 else {
            if ProcessInfo.processInfo.environment["UVC_DEBUG"] == "1" {
                let log = OSLog(subsystem: "UVC", category: "Descriptor")
                let dumpLen = min(32, max(0, configLength))
                var hexParts: [String] = []
                hexParts.reserveCapacity(dumpLen)
                for i in 0..<dumpLen {
                    hexParts.append(String(format: "%02X", bytes[i]))
                }
                os_log(
                    "UVC_DEBUG: descriptor dump (first %{public}d bytes): %{public}s",
                    log: log,
                    type: .info,
                    dumpLen,
                    hexParts.joined(separator: " ")
                )
            }
            return UVCDescriptor(processingUnitID: processingUnitID,
                                 cameraTerminalID: cameraTerminalID,
                                 interfaceID: interfaceID)
        }

        if ProcessInfo.processInfo.environment["UVC_DEBUG"] == "1" {
            let log = OSLog(subsystem: "UVC", category: "Descriptor")
            os_log("UVC_DEBUG: config bLength=%{public}d wTotalLength=%{public}d", log: log, type: .info, configLength, totalLength)

            // Dump the first chunk of bytes for debugging (helps when parsing fails on some devices).
            let dumpLen = min(96, totalLength)
            var hexParts: [String] = []
            hexParts.reserveCapacity(dumpLen)
            for i in 0..<dumpLen {
                hexParts.append(String(format: "%02X", bytes[i]))
            }
            os_log("UVC_DEBUG: descriptor dump (first %{public}d bytes): %{public}s", log: log, type: .info, dumpLen, hexParts.joined(separator: " "))
        }

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
