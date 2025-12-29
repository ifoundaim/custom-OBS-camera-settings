//
//  ValueBadge.swift
//  CameraController
//
//  Created by CameraController contributors.
//

import SwiftUI

struct ValueBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(Constants.Colors.regularColor.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Constants.Colors.sectionBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Style.smallCornerRadius))
            // Stable-ish width to avoid layout jitter as values change.
            .frame(width: 64, alignment: .trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

#if DEBUG
struct ValueBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 10) {
            ValueBadge(text: "42")
            ValueBadge(text: "0.50")
            ValueBadge(text: "65535")
        }
        .padding()
        .background(Constants.Colors.background)
    }
}
#endif


