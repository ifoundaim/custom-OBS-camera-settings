//
//  UpdaterConfigurationTests.swift
//  CameraControllerTests
//
//  Regression coverage for Sparkle updater wiring.
//

import XCTest
import ObjectiveC.runtime
@testable import CameraController

final class UpdaterConfigurationTests: XCTestCase {
    func testFeedURLPointsToFork() {
        let bundle = Bundle(for: AppDelegate.self)
        let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        XCTAssertEqual(
            feedURL,
            "https://raw.githubusercontent.com/ifoundaim/custom-OBS-camera-settings/master/appcast.xml"
        )
    }

    func testAppDelegateHasCheckForUpdatesAction() {
        let method = class_getInstanceMethod(AppDelegate.self, #selector(AppDelegate.checkForUpdates(_:)))
        XCTAssertNotNil(method)
    }
}


