//
//  NoAdjustableSettingsView.swift
//  CameraController
//
//  Created by CameraController contributors.
//

import SwiftUI

struct NoAdjustableSettingsView: View {
    var body: some View {
        VStack(spacing: 6) {
            Spacer()

            Text("No Adjustable Settings")
                .font(.system(size: 20).bold())

            Text("This camera doesn’t expose UVC controls that CameraController can change.")
                .font(.caption.bold())
                .multilineTextAlignment(.center)

            Text("Try selecting a different camera in Settings → Camera.")
                .font(.caption)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.vertical, 10)
    }
}

#if DEBUG
struct NoAdjustableSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NoAdjustableSettingsView()
            .frame(width: 360, height: 220)
    }
}
#endif


