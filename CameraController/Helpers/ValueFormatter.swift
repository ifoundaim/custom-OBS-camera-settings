//
//  ValueFormatter.swift
//  CameraController
//
//  Created by CameraController contributors.
//

import Foundation

struct ValueFormatter {
    private static let epsilon: Float = 0.000_001

    static func format(_ value: Float, step: Float) -> String {
        guard value.isFinite else {
            return "-"
        }

        let decimals = decimalsForStep(step)
        if decimals == 0 {
            return String(Int(value.rounded()))
        }

        return String(format: "%.\(decimals)f", Double(value))
    }

    /// Determines the number of decimal places to show based on the slider step/resolution.
    /// - For integer-ish steps (>= 1 or effectively an integer): 0 decimals
    /// - For fractional steps: find the smallest decimal places (up to 6) that makes `step * 10^n` an integer.
    private static func decimalsForStep(_ step: Float) -> Int {
        guard step.isFinite, step > 0 else {
            return 2
        }

        if step >= 1 || isEffectivelyInteger(step) {
            return 0
        }

        for decimals in 1...6 {
            let scaled = step * powf(10, Float(decimals))
            if abs(scaled - scaled.rounded()) < epsilon {
                return decimals
            }
        }

        return 2
    }

    private static func isEffectivelyInteger(_ value: Float) -> Bool {
        abs(value - value.rounded()) < epsilon
    }
}


