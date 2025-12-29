//
//  ValueFormatterTests.swift
//  CameraControllerTests
//
//  Created by CameraController contributors.
//

import XCTest
@testable import CameraController

final class ValueFormatterTests: XCTestCase {
    func testIntegerStepFormatsWithoutDecimals() {
        XCTAssertEqual(ValueFormatter.format(42.1, step: 1), "42")
        XCTAssertEqual(ValueFormatter.format(42.9, step: 5), "43")
    }

    func testFractionalStepFormatsWithExpectedDecimals() {
        XCTAssertEqual(ValueFormatter.format(0.5, step: 0.1), "0.5")
        XCTAssertEqual(ValueFormatter.format(0.5, step: 0.01), "0.50")
        XCTAssertEqual(ValueFormatter.format(0.25, step: 0.25), "0.25")
    }

    func testNegativeValuesAreFormattedPredictably() {
        XCTAssertEqual(ValueFormatter.format(-1.2, step: 1), "-1")
        XCTAssertEqual(ValueFormatter.format(-1.25, step: 0.25), "-1.25")
    }

    func testNonFiniteValuesReturnPlaceholder() {
        XCTAssertEqual(ValueFormatter.format(.infinity, step: 1), "-")
        XCTAssertEqual(ValueFormatter.format(.nan, step: 0.1), "-")
    }
}


