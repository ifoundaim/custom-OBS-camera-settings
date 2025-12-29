//
//  AVCaptureDevice+USB.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation
import IOKit.usb

extension AVCaptureDevice {

    private func getIOService() throws -> io_service_t {
        var camera: io_service_t = 0
        let cameraInformation = try self.modelID.extractCameraInformation()
        // On modern macOS versions, USB devices are commonly exposed as IOUSBHostDevice.
        // Keep a fallback to IOUSBDevice for older systems / compatibility layers.
        func matchingDict(_ className: String) -> NSMutableDictionary {
            let dict: NSMutableDictionary = IOServiceMatching(className) as NSMutableDictionary
            dict["idVendor"] = cameraInformation.vendorId
            dict["idProduct"] = cameraInformation.productId
            return dict
        }

        let dictionaries: [NSMutableDictionary] = [
            matchingDict("IOUSBHostDevice"),
            matchingDict("IOUSBDevice")
        ]

        // adding other keys to this dictionary like kUSBProductString, kUSBVendorString, etc don't
        // seem to have any affect on using IOServiceGetMatchingService to get the correct camera,
        // so we instead get an iterator for the matching services based on idVendor and idProduct
        // and fetch their property dicts and then match against the more specific values

        for dictionary in dictionaries {
            var iter: io_iterator_t = 0
            if IOServiceGetMatchingServices(kIOMasterPortDefault, dictionary, &iter) == kIOReturnSuccess {
                var cameraCandidate: io_service_t
                cameraCandidate = IOIteratorNext(iter)
                while cameraCandidate != 0 {
                    var propsRef: Unmanaged<CFMutableDictionary>?

                    if IORegistryEntryCreateCFProperties(
                        cameraCandidate,
                        &propsRef,
                        kCFAllocatorDefault,
                        0) == kIOReturnSuccess {
                        var found: Bool = false
                        if let properties = propsRef?.takeRetainedValue() {

                            // uniqueID starts with hex version of locationID
                            if let locationID = (properties as NSDictionary)["locationID"] as? Int {
                                let locationIDHex = "0x" + String(locationID, radix: 16)
                                if self.uniqueID.hasPrefix(locationIDHex) {
                                    camera = cameraCandidate
                                    found = true
                                }
                            }
                            if found {
                                // break out of `while (cameraCandidate != 0)`
                                break
                            }
                        }
                    }
                    cameraCandidate = IOIteratorNext(iter)
                }
                // Release iterator and exit outer loop if found
                let code: kern_return_t = IOObjectRelease(iter)
                assert(code == kIOReturnSuccess)
            }
            if camera != 0 {
                break
            }
        }

        // if we haven't found a camera after looping through the iterator, fallback on GetMatchingService method
        if camera == 0 {
            // Keep compatibility fallback for older systems.
            camera = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict("IOUSBDevice"))
        }

        return camera
    }

    func usbDevice() throws -> USBDevice {

        let camera = try self.getIOService()
        defer {
            let code: kern_return_t = IOObjectRelease(camera)
            assert( code == kIOReturnSuccess )
        }
        var interfaceRef: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface190>>?
        var configDesc: IOUSBConfigurationDescriptorPtr?
        try camera.ioCreatePluginInterfaceFor(service: kIOUSBDeviceUserClientTypeID) {
            let deviceInterface: DeviceInterfacePointer = try $0.getInterface(uuid: kIOUSBDeviceInterfaceID)
            defer { _ = deviceInterface.pointee.pointee.Release(deviceInterface) }

            // On newer macOS versions / some devices, config descriptor reads can return empty data unless the
            // device interface is opened first.
            let openResult = deviceInterface.pointee.pointee.USBDeviceOpen(deviceInterface)
            if openResult != kIOReturnSuccess {
                let seizeResult = deviceInterface.pointee.pointee.USBDeviceOpenSeize(deviceInterface)
                guard seizeResult == kIOReturnSuccess else {
                    throw NSError(domain: #function, code: #line, userInfo: nil)
                }
            }
            defer { _ = deviceInterface.pointee.pointee.USBDeviceClose(deviceInterface) }

            let interfaceRequest = IOUSBFindInterfaceRequest(bInterfaceClass: UVCConstants.classVideo,
                                                             bInterfaceSubClass: UVCConstants.subclassVideoControl,
                                                             bInterfaceProtocol: UInt16(kIOUSBFindInterfaceDontCare),
                                                             bAlternateSetting: UInt16(kIOUSBFindInterfaceDontCare))
            try deviceInterface.iterate(interfaceRequest: interfaceRequest) {
                interfaceRef = try $0.getInterface(uuid: kIOUSBInterfaceInterfaceID)
            }

            var returnCode: Int32 = 0
            var numConfig: UInt8 = 0
            returnCode = deviceInterface.pointee.pointee.GetNumberOfConfigurations(deviceInterface, &numConfig)
            if returnCode != kIOReturnSuccess {
                print("unable to get number of configurations")
                return
            }

            returnCode = deviceInterface.pointee.pointee.GetConfigurationDescriptorPtr(deviceInterface, 0, &configDesc)
            if returnCode != kIOReturnSuccess {
                print("unable to get config description for config 0 (index)")
                return
            }
        }
        guard interfaceRef != nil else { throw NSError(domain: #function, code: #line, userInfo: nil) }

        // Get interface number from the actual interface (more reliable than parsing config descriptors on modern macOS).
        var interfaceNumber: Int = -1
        do {
            var intf: UInt8 = 0
            let rc = interfaceRef!.pointee.pointee.GetInterfaceNumber(interfaceRef!, &intf)
            if rc == kIOReturnSuccess {
                interfaceNumber = Int(intf)
            }
        }

        var descriptor = configDesc?.proccessDescriptor() ?? UVCDescriptor(processingUnitID: -1, cameraTerminalID: -1, interfaceID: -1)

        // Fallback: some devices/OS versions don't expose a readable config descriptor via IOUSBLib (bLength/wTotalLength become 0).
        // If parsing fails, probe the unit IDs empirically via GET_INFO.
        if descriptor.interfaceID == -1, interfaceNumber != -1 {
            descriptor = UVCDescriptor(processingUnitID: descriptor.processingUnitID,
                                       cameraTerminalID: descriptor.cameraTerminalID,
                                       interfaceID: interfaceNumber)
        }

        if descriptor.interfaceID != -1, (descriptor.processingUnitID == -1 || descriptor.cameraTerminalID == -1) {
            func probeUnitId(_ selector: Selector, maxUnitId: Int = 32) -> Int? {
                for unit in 1...maxUnitId {
                    let control = UVCControl(interfaceRef!, 1, selector, unit, descriptor.interfaceID)
                    control.updateIsCapable()
                    if control.isCapable {
                        return unit
                    }
                }
                return nil
            }

            let probedCameraTerminal = descriptor.cameraTerminalID == -1 ? probeUnitId(UVCCameraTerminal.aeMode) : nil
            let probedProcessingUnit = descriptor.processingUnitID == -1 ? probeUnitId(UVCProcessingUnit.brightness) : nil

            if ProcessInfo.processInfo.environment["UVC_DEBUG"] == "1" {
                print("UVC_DEBUG: probed cameraTerminalID=\(probedCameraTerminal ?? -1) processingUnitID=\(probedProcessingUnit ?? -1) interfaceID=\(descriptor.interfaceID)")
            }

            descriptor = UVCDescriptor(
                processingUnitID: probedProcessingUnit ?? descriptor.processingUnitID,
                cameraTerminalID: probedCameraTerminal ?? descriptor.cameraTerminalID,
                interfaceID: descriptor.interfaceID
            )
        }

        return USBDevice(interface: interfaceRef.unsafelyUnwrapped,
                         descriptor: descriptor)
    }
}
