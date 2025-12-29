//
//  SliderWithValue.swift
//  CameraController
//
//  Created by CameraController contributors.
//

import SwiftUI

struct SliderWithValue: View {
    @Binding var value: Float

    let step: Float
    let sliderRange: ClosedRange<Float>

    init(value: Binding<Float>,
         step: Float = 1,
         sliderRange: ClosedRange<Float> = 0...100) {
        self._value = value
        self.step = step
        self.sliderRange = sliderRange
    }

    var body: some View {
        HStack(spacing: 8) {
            Slider(value: $value, step: step, sliderRange: sliderRange)
            ValueBadge(text: ValueFormatter.format(value, step: step))
        }
    }
}

#if DEBUG
struct SliderWithValue_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(Float(40.0)) { value in
            VStack(spacing: 10) {
                SliderWithValue(value: value, step: 1, sliderRange: 0...100)
                    .frame(width: 320)
                SliderWithValue(value: value, step: 0.25, sliderRange: 0...1)
                    .frame(width: 320)
            }
            .padding()
            .background(Constants.Colors.background)
        }
    }
}
#endif


