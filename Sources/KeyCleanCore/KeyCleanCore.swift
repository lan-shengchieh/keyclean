import CoreGraphics

public enum KeyCleanMetadata {
  public static let name = "keyclean"
  public static let version = "0.2.0"
  public static let appBundleIdentifier = "io.github.lan-shengchieh.keyclean"
  public static let fullAppBundleIdentifier = "io.github.lan-shengchieh.keyclean.full"
}

public enum FullAccessRevocation {
  // Reset both current app identities. Early v0.2 preview builds could grant
  // Accessibility to either one, and TCC entries can outlive app files.
  public static let bundleIdentifiers = [
    KeyCleanMetadata.fullAppBundleIdentifier,
    KeyCleanMetadata.appBundleIdentifier,
  ]

  // PostEvent clears grants made by early v0.2 preview builds that used the
  // Core Graphics post-event preflight API. Accessibility is the service
  // used by the final AX trust flow.
  public static let services = ["Accessibility", "PostEvent"]
}

public enum SessionMode: String, Hashable {
  case safe
  case full

  public var appBundleName: String {
    switch self {
    case .safe:
      return "KeyClean.app"
    case .full:
      return "KeyCleanFull.app"
    }
  }
}

public enum CLICommand: Equatable {
  case launch(SessionMode, revokeAfterSession: Bool)
  case revokeFullAccess
  case help
  case version
}

public enum CLIParseError: Error, Equatable, CustomStringConvertible {
  case unknownOption(String)
  case tooManyArguments

  public var description: String {
    switch self {
    case .unknownOption(let option):
      return "unknown option: \(option)"
    case .tooManyArguments:
      return "only one option may be specified"
    }
  }
}

public enum CLIParser {
  public static func parse(_ arguments: [String]) throws -> CLICommand {
    guard arguments.count <= 1 else {
      throw CLIParseError.tooManyArguments
    }

    guard let argument = arguments.first else {
      return .launch(.safe, revokeAfterSession: false)
    }

    switch argument {
    case "--safe":
      return .launch(.safe, revokeAfterSession: false)
    case "--full":
      return .launch(.full, revokeAfterSession: false)
    case "--full-once":
      return .launch(.full, revokeAfterSession: true)
    case "--revoke-full-access":
      return .revokeFullAccess
    case "--help", "-h":
      return .help
    case "--version", "-v":
      return .version
    default:
      throw CLIParseError.unknownOption(argument)
    }
  }
}

public let keyCleanHelpText = """
  keyclean \(KeyCleanMetadata.version)

  Temporarily suppress keyboard input while you clean your Mac keyboard.

  Usage:
    keyclean                         Start permission-free Safe Mode
    keyclean --safe                  Start permission-free Safe Mode
    keyclean --full                  Start Full Lock with Accessibility
    keyclean --full-once             Start Full Lock, then revoke its access
    keyclean --revoke-full-access    Revoke KeyClean's Accessibility access
    keyclean --help
    keyclean --version

  Safe Mode:
    Covers every display and consumes keyboard events delivered to KeyClean.
    It does not request Accessibility permission. Some system-reserved keys may
    still take effect.

  Full Lock:
    Uses an active CGEventTap to suppress keyboard events system-wide. macOS
    grants Accessibility to KeyClean itself; your terminal does not need it.
    Use --full-once to revoke that access automatically after the app exits.

  Unlock:
    Click Unlock with the trackpad, or press Control + Option + Command + U.

  Touch ID and the physical power button are outside KeyClean's guarantee.
  """

public enum KeyboardEvents {
  public static let systemDefinedRaw: UInt32 = 14
  public static let unlockKeyCode: Int64 = 32

  private static func eventMask(_ type: CGEventType) -> CGEventMask {
    CGEventMask(1) << type.rawValue
  }

  private static func rawEventMask(_ rawValue: UInt32) -> CGEventMask {
    CGEventMask(1) << rawValue
  }

  public static let eventsOfInterest =
    eventMask(.keyDown) | eventMask(.keyUp) | eventMask(.flagsChanged)
    | rawEventMask(systemDefinedRaw)

  public static func isUnlock(
    keyCode: Int64,
    flags: CGEventFlags
  ) -> Bool {
    let required: CGEventFlags = [
      .maskControl,
      .maskAlternate,
      .maskCommand,
    ]

    return keyCode == unlockKeyCode && flags.contains(required)
  }
}

public enum FullLockPanelState: Equatable {
  case permission
  case unavailable
  case locked

  public var shouldFloat: Bool {
    self == .locked
  }
}

public struct ScreenReconciliation {
  public let added: Set<String>
  public let removed: Set<String>

  public init(existing: Set<String>, current: Set<String>) {
    added = current.subtracting(existing)
    removed = existing.subtracting(current)
  }
}
