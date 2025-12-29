//
//  DeviceManager.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Combine
import Foundation
import AVFoundation

final class DevicesManager: ObservableObject {
    static let shared = DevicesManager()

    private let deviceMonitor = DeviceMonitor()

    @Published var devices: [CaptureDevice] = []

    @Published var selectedDevice: CaptureDevice? {
        willSet {
            if newValue != nil && selectedDevice != newValue {
                UserSettings.shared.lastSelectedDevice = newValue?.avDevice?.uniqueID
            }
            deviceMonitor.updateDevice(newValue)
        }
    }

    private init() {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown, .builtInWideAngleCamera],
                                                                mediaType: nil,
                                                                position: .unspecified)
        devices = session.devices.map({ (device) -> CaptureDevice in
            CaptureDevice(avDevice: device)
        })

        let candidates = devices.map {
            DeviceSelectionCandidate(uniqueID: $0.avDevice?.uniqueID, isConfigurable: $0.isConfigurable())
        }

        if let index = Self.pickDefaultCandidateIndex(
            candidates,
            lastSelectedDeviceId: UserSettings.shared.lastSelectedDevice
        ) {
            selectedDevice = devices[index]
        }
    }

    struct DeviceSelectionCandidate {
        let uniqueID: String?
        let isConfigurable: Bool
    }

    static func pickDefaultCandidateIndex(
        _ candidates: [DeviceSelectionCandidate],
        lastSelectedDeviceId: String?
    ) -> Int? {
        guard !candidates.isEmpty else { return nil }

        if let lastSelectedDeviceId {
            if let index = candidates.firstIndex(where: { $0.uniqueID == lastSelectedDeviceId }) {
                return index
            }
        }

        if let index = candidates.firstIndex(where: { $0.isConfigurable }) {
            return index
        }

        return 0
    }

    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceAdded(notif:)),
                                               name: NSNotification.Name.AVCaptureDeviceWasConnected,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceRemoved(notif:)),
                                               name: NSNotification.Name.AVCaptureDeviceWasDisconnected,
                                               object: nil)
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVCaptureDeviceWasConnected,
                                                  object: nil)
    }

    @objc
    func deviceAdded(notif: NSNotification) {
        guard let device = notif.object as? AVCaptureDevice else {
            return
        }

        devices.append(CaptureDevice(avDevice: device))
        NotificationCenter.default.post(name: .devicesUpdated, object: nil)
    }

    @objc
    func deviceRemoved(notif: NSNotification) {
        guard let device = notif.object as? AVCaptureDevice else {
            return
        }

        let index = devices.firstIndex { (captureDevice) -> Bool in
            captureDevice.avDevice == device
        }

        guard index != nil else {
            return
        }

        devices.remove(at: index!)

        if device.uniqueID == selectedDevice?.avDevice?.uniqueID {
            selectedDevice = nil
        }
        NotificationCenter.default.post(name: .devicesUpdated, object: nil)
    }
}
