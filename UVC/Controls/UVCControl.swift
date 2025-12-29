//
//  UVCControl.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

protocol Selector {
    func raw() -> Int
}

public class UVCControl {
    let interface: USBInterfacePointer
    let uvcSize: Int
    let uvcSelector: Int
    let uvcUnit: Int
    let uvcInterface: Int

    struct USBInterfaceCallouts {
        let controlRequest: (_ request: inout IOUSBDevRequest) -> Int32
        let open: () -> Int32
        let openSeize: () -> Int32
        let close: () -> Int32

        static func live(_ interface: USBInterfacePointer) -> USBInterfaceCallouts {
            USBInterfaceCallouts(
                controlRequest: { request in
                    interface.pointee.pointee.ControlRequest(interface, 0, &request)
                },
                open: { interface.pointee.pointee.USBInterfaceOpen(interface) },
                openSeize: { interface.pointee.pointee.USBInterfaceOpenSeize(interface) },
                close: { interface.pointee.pointee.USBInterfaceClose(interface) }
            )
        }
    }

    private let callouts: USBInterfaceCallouts

    public var isCapable: Bool = false

    init(_ interface: USBInterfacePointer, _ uvcSize: Int, _ uvcSelector: Selector,
         _ uvcUnit: Int, _ uvcInterface: Int, callouts: USBInterfaceCallouts? = nil) {
        self.interface = interface
        self.uvcSize = uvcSize
        self.uvcSelector = uvcSelector.raw()
        self.uvcUnit = uvcUnit
        self.uvcInterface = uvcInterface
        self.callouts = callouts ?? USBInterfaceCallouts.live(interface)
    }

    func getDataFor(type: UVCRequestCodes, length: Int) -> Int {
        let requestType = USBmakebmRequestType(direction: kUSBIn, type: kUSBClass, recipient: kUSBInterface)

        do {
            return try performRequest(type: type,
                                      length: length,
                                      requestType: requestType)
        } catch {
            // Should not return 0, but working on improving this
            return 0
        }
    }

    func setData(value: Int, length: Int) -> Bool {
        let requestType = USBmakebmRequestType(direction: kUSBOut, type: kUSBClass, recipient: kUSBInterface)

        do {
            _ = try performRequest(type: UVCRequestCodes.setCurrent,
                                   length: length,
                                   requestType: requestType,
                                   value: value)
            return true
        } catch {
            return false
        }
    }

    func updateIsCapable() {
        isCapable = getDataFor(type: UVCRequestCodes.getInfo, length: 1) != 0
    }

    private func performRequest(type: UVCRequestCodes,
                                length: Int,
                                requestType: UInt8,
                                value: Int = 0) throws -> Int {
        guard uvcUnit >= 0 else {
            throw UVCError.invalidUnitId
        }

        var value = value

        try withUnsafeMutablePointer(to: &value, { value in
            var request = IOUSBDevRequest(bmRequestType: requestType,
                                          bRequest: UInt8(type.rawValue),
                                          wValue: UInt16(uvcSelector<<8),
                                          wIndex: UInt16(uvcUnit<<8) | UInt16(uvcInterface),
                                          wLength: UInt16(length),
                                          pData: value,
                                          wLenDone: 0)

            // Attempt request optimistically first (works if interface already open / doesn't require open).
            if callouts.controlRequest(&request) == kIOReturnSuccess {
                return
            }

            // Retry with an explicitly opened interface.
            let openResult = callouts.open()
            if openResult != kIOReturnSuccess {
                guard callouts.openSeize() == kIOReturnSuccess else {
                    throw UVCError.requestError
                }
            }
            defer { _ = callouts.close() }

            guard callouts.controlRequest(&request) == kIOReturnSuccess else {
                throw UVCError.requestError
            }
        })
        return value
    }

    private func USBmakebmRequestType(direction: Int, type: Int, recipient: Int) -> UInt8 {
        return UInt8((direction & kUSBRqDirnMask) << kUSBRqDirnShift) |
            UInt8((type & kUSBRqTypeMask) << kUSBRqTypeShift)|UInt8(recipient & kUSBRqRecipientMask)

    }
}
