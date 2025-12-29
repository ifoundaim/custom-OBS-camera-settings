//
//  AdvancedView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct AdvancedView: View {
    @ObservedObject var controller: DeviceController

    var body: some View {
        if hasAnyControls {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Constants.Style.controlsSpacing) {
                    if controller.powerLineFrequency.isCapable {
                        PowerLineView(controller: controller)
                    }

                    if controller.backlightCompensation.isCapable {
                        BacklightView(controller: controller)
                    }

                    if controller.zoomAbsolute.isCapable {
                        ZoomView(controller: controller)
                    }

                    if controller.panTiltAbsolute.isCapable {
                        PanTiltView(controller: controller)
                    }

                    if controller.rollAbsolute.isCapable {
                        RollView(controller: controller)
                    }

                    if controller.focusAbsolute.isCapable {
                        FocusView(controller: controller)
                    }
                }
                .padding(.top, 2)
                .padding(.bottom, Constants.Style.topSpacing)
            }
            .frame(maxHeight: 300)
        } else {
            NoAdjustableSettingsView()
                .frame(maxHeight: 300)
        }
    }

    private var hasAnyControls: Bool {
        controller.powerLineFrequency.isCapable ||
        controller.backlightCompensation.isCapable ||
        controller.zoomAbsolute.isCapable ||
        controller.panTiltAbsolute.isCapable ||
        controller.rollAbsolute.isCapable ||
        controller.focusAbsolute.isCapable
    }
}
