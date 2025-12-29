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

    func testAppIsNotAgentApp() {
        // Regression: app should behave like a normal windowed Dock app (LSUIElement must not be true).
        let bundle = Bundle(for: AppDelegate.self)
        let agentFlag = bundle.object(forInfoDictionaryKey: "LSUIElement") as? Bool
        XCTAssertFalse(agentFlag ?? false)
    }

    func testAppDelegateHasCheckForUpdatesAction() {
        let method = class_getInstanceMethod(AppDelegate.self, #selector(AppDelegate.checkForUpdates(_:)))
        XCTAssertNotNil(method)
    }
}


