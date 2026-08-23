import Foundation
import CoreGraphics
import CoreFoundation
import Darwin

private let appName = "keyclean"
private let appVersion = "0.1.0"

private let helpText = """
keyclean \(appVersion)

Temporarily suppress keyboard events while you clean your Mac keyboard.

Usage:
  keyclean
  keyclean --help
  keyclean --version

Unlock:
  Control + Option + Command + U

You can also close the Terminal window with the trackpad. When the process
exits, its CGEventTap disappears and keyboard input returns automatically.

Notes:
  - Trackpad/mouse input is not intercepted.
  - Touch ID / the physical power button are outside the guarantee of this tool.
  - macOS may require Accessibility permission for the terminal application
    that launches keyclean.
"""

private func fail(_ message: String, code: Int32 = 1) -> Never {
    fputs("\(appName): \(message)\n", stderr)
    exit(code)
}

let arguments = Array(CommandLine.arguments.dropFirst())

if let argument = arguments.first {
    switch argument {
    case "--help", "-h":
        print(helpText)
        exit(0)
    case "--version", "-v":
        print("\(appName) \(appVersion)")
        exit(0)
    default:
        fail("unknown option: \(argument)\nTry '\(appName) --help'.", code: 64)
    }
}

var eventTap: CFMachPort?

private func eventMask(_ type: CGEventType) -> CGEventMask {
    CGEventMask(1) << type.rawValue
}

// CGEventType does not expose a public `.systemDefined` Swift case.
// NX_SYSDEFINED has historically used raw event type 14 and is where
// media/brightness-style system key events may appear.
private let systemDefinedRaw: UInt32 = 14

private func rawEventMask(_ rawValue: UInt32) -> CGEventMask {
    CGEventMask(1) << rawValue
}

// macOS virtual key code for U.
private let unlockKeyCode: Int64 = 32

private let eventsOfInterest =
    eventMask(.keyDown) |
    eventMask(.keyUp) |
    eventMask(.flagsChanged) |
    rawEventMask(systemDefinedRaw)

private let callback: CGEventTapCallBack = { _, type, event, _ in
    // macOS can temporarily disable a slow event tap. Re-enable it if needed.
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // Detect Control + Option + Command + U before swallowing the event.
    if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let requiredFlags: CGEventFlags = [
            .maskControl,
            .maskAlternate,
            .maskCommand
        ]

        if keyCode == unlockKeyCode && flags.contains(requiredFlags) {
            // The U keyDown itself is swallowed. Stopping the run loop causes
            // the process to exit, which removes the event tap automatically.
            CFRunLoopStop(CFRunLoopGetCurrent())
            return nil
        }
    }

    // Swallow ordinary keyboard and modifier events.
    if type == .keyDown || type == .keyUp || type == .flagsChanged {
        return nil
    }

    // Swallow system-defined keyboard-ish events such as media keys when they
    // are visible at this event-tap location.
    if type.rawValue == systemDefinedRaw {
        return nil
    }

    return Unmanaged.passUnretained(event)
}

eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventsOfInterest,
    callback: callback,
    userInfo: nil
)

guard let eventTap else {
    fail("""
    could not create the keyboard event tap.

    Enable Accessibility permission for your terminal app:
      System Settings
        > Privacy & Security
        > Accessibility

    Then run keyclean again.
    """)
}

guard let source = CFMachPortCreateRunLoopSource(
    kCFAllocatorDefault,
    eventTap,
    0
) else {
    fail("could not create a run-loop source for the event tap.")
}

let runLoop = CFRunLoopGetCurrent()
CFRunLoopAddSource(runLoop, source, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

print("""
🔒 Keyboard locked

Unlock: ⌃⌥⌘U
Or close this Terminal window using the trackpad.
""")

CFRunLoopRun()

CGEvent.tapEnable(tap: eventTap, enable: false)
CFRunLoopRemoveSource(runLoop, source, .commonModes)

print("🔓 Keyboard unlocked")
