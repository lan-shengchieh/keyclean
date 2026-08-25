import CoreGraphics
import Foundation
import KeyCleanCore
import XCTest

final class KeyCleanCoreTests: XCTestCase {
  private var repositoryRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  func testCLIUsesSafeModeByDefault() throws {
    XCTAssertEqual(
      try CLIParser.parse([]),
      .launch(.safe, revokeAfterSession: false)
    )
    XCTAssertEqual(
      try CLIParser.parse(["--safe"]),
      .launch(.safe, revokeAfterSession: false)
    )
  }

  func testCLIParsesFullAndMaintenanceCommands() throws {
    XCTAssertEqual(
      try CLIParser.parse(["--full"]),
      .launch(.full, revokeAfterSession: false)
    )
    XCTAssertEqual(
      try CLIParser.parse(["--full-once"]),
      .launch(.full, revokeAfterSession: true)
    )
    XCTAssertEqual(
      try CLIParser.parse(["--revoke-full-access"]),
      .revokeFullAccess
    )
    XCTAssertEqual(try CLIParser.parse(["--help"]), .help)
    XCTAssertEqual(try CLIParser.parse(["--version"]), .version)
  }

  func testEachModeSelectsItsDedicatedApplication() {
    XCTAssertEqual(SessionMode.safe.appBundleName, "KeyClean.app")
    XCTAssertEqual(SessionMode.full.appBundleName, "KeyCleanFull.app")
  }

  func testCLIRejectsUnknownAndMultipleOptions() {
    XCTAssertThrowsError(try CLIParser.parse(["--unknown"])) { error in
      XCTAssertEqual(
        error as? CLIParseError,
        .unknownOption("--unknown")
      )
    }

    XCTAssertThrowsError(try CLIParser.parse(["--safe", "--full"])) {
      error in
      XCTAssertEqual(error as? CLIParseError, .tooManyArguments)
    }
  }

  func testUnlockChordRequiresKeyAndRequiredModifiers() {
    let required: CGEventFlags = [
      .maskControl,
      .maskAlternate,
      .maskCommand,
    ]

    XCTAssertTrue(
      KeyboardEvents.isUnlock(
        keyCode: KeyboardEvents.unlockKeyCode,
        flags: required
      )
    )
    XCTAssertTrue(
      KeyboardEvents.isUnlock(
        keyCode: KeyboardEvents.unlockKeyCode,
        flags: required.union(.maskShift)
      )
    )
    XCTAssertFalse(
      KeyboardEvents.isUnlock(
        keyCode: KeyboardEvents.unlockKeyCode,
        flags: [.maskControl, .maskCommand]
      )
    )
    XCTAssertFalse(
      KeyboardEvents.isUnlock(keyCode: 31, flags: required)
    )
  }

  func testEventMaskContainsKeyboardAndSystemDefinedEvents() {
    let expected =
      (CGEventMask(1) << CGEventType.keyDown.rawValue)
      | (CGEventMask(1) << CGEventType.keyUp.rawValue)
      | (CGEventMask(1) << CGEventType.flagsChanged.rawValue)
      | (CGEventMask(1) << KeyboardEvents.systemDefinedRaw)

    XCTAssertEqual(KeyboardEvents.eventsOfInterest, expected)
  }

  func testFullLockPanelFloatsOnlyDuringAnActiveLock() {
    XCTAssertFalse(FullLockPanelState.permission.shouldFloat)
    XCTAssertFalse(FullLockPanelState.unavailable.shouldFloat)
    XCTAssertTrue(FullLockPanelState.locked.shouldFloat)
  }

  func testRevocationCoversCurrentAppsAndPreviewService() {
    XCTAssertEqual(
      Set(FullAccessRevocation.bundleIdentifiers),
      [
        KeyCleanMetadata.appBundleIdentifier,
        KeyCleanMetadata.fullAppBundleIdentifier,
      ]
    )
    XCTAssertEqual(
      Set(FullAccessRevocation.services),
      ["Accessibility", "PostEvent"]
    )
  }

  func testScreenReconciliationAddsAndRemovesOnlyDifferences() {
    let change = ScreenReconciliation(
      existing: ["main", "old"],
      current: ["main", "new"]
    )

    XCTAssertEqual(change.added, ["new"])
    XCTAssertEqual(change.removed, ["old"])
  }

  func testBundleMetadataUsesStableIdentifiersAndMinimumOS() throws {
    let resources = repositoryRoot.appendingPathComponent("Resources")
    let expectations = [
      ("KeyClean-Info.plist", KeyCleanMetadata.appBundleIdentifier),
      ("KeyCleanFull-Info.plist", KeyCleanMetadata.fullAppBundleIdentifier),
    ]

    for (filename, bundleIdentifier) in expectations {
      let data = try Data(
        contentsOf: resources.appendingPathComponent(filename)
      )
      let value = try PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      )
      let info = try XCTUnwrap(value as? [String: Any])

      XCTAssertEqual(info["CFBundleIdentifier"] as? String, bundleIdentifier)
      XCTAssertEqual(
        info["CFBundleShortVersionString"] as? String,
        KeyCleanMetadata.version
      )
      XCTAssertEqual(info["LSMinimumSystemVersion"] as? String, "13.0")
    }
  }
}
