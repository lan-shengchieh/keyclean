import AppKit
import Darwin
import Foundation
import KeyCleanCore

private func fail(_ message: String, code: Int32 = 1) -> Never {
  fputs("\(KeyCleanMetadata.name): \(message)\n", stderr)
  exit(code)
}

private func resolvedExecutableURL() -> URL {
  var size: UInt32 = 0
  _ = _NSGetExecutablePath(nil, &size)
  var buffer = [CChar](repeating: 0, count: Int(size))

  guard _NSGetExecutablePath(&buffer, &size) == 0 else {
    fail("could not resolve the keyclean executable path")
  }

  return URL(fileURLWithPath: String(cString: buffer))
    .resolvingSymlinksInPath()
    .standardizedFileURL
}

private func installationRoot() -> URL {
  resolvedExecutableURL()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
}

private func appURL(for mode: SessionMode) -> URL {
  let libexec = installationRoot().appendingPathComponent("libexec", isDirectory: true)
  return libexec.appendingPathComponent(mode.appBundleName, isDirectory: true)
}

private func runningKeyCleanApplications() -> [NSRunningApplication] {
  FullAccessRevocation.bundleIdentifiers.flatMap {
    NSRunningApplication.runningApplications(withBundleIdentifier: $0)
  }
}

private func launch(_ mode: SessionMode) -> Int32 {
  guard runningKeyCleanApplications().isEmpty else {
    fail("KeyClean is already running. Unlock it before starting another session.")
  }

  let applicationURL = appURL(for: mode)
  guard FileManager.default.fileExists(atPath: applicationURL.path) else {
    fail("KeyClean application is missing at \(applicationURL.path)")
  }

  let configuration = NSWorkspace.OpenConfiguration()
  configuration.activates = true
  configuration.arguments = ["--mode", mode.rawValue]

  var launchedApplication: NSRunningApplication?
  var launchError: Error?
  var launchFinished = false

  NSWorkspace.shared.openApplication(
    at: applicationURL,
    configuration: configuration
  ) { application, error in
    launchedApplication = application
    launchError = error
    launchFinished = true
  }

  while !launchFinished {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
  }

  if let launchError {
    fail("could not launch KeyClean: \(launchError.localizedDescription)")
  }

  guard let launchedApplication else {
    fail("macOS did not return a running KeyClean application")
  }

  while !launchedApplication.isTerminated {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
  }

  return 0
}

private func revokeFullAccess() -> Int32 {
  guard runningKeyCleanApplications().isEmpty else {
    fail("KeyClean is running. Unlock it before revoking Full Lock access.")
  }

  var failedResets: [String] = []

  for service in FullAccessRevocation.services {
    for bundleIdentifier in FullAccessRevocation.bundleIdentifiers {
      let process = Process()
      let standardError = Pipe()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
      process.arguments = ["reset", service, bundleIdentifier]
      process.standardError = standardError

      do {
        try process.run()
        process.waitUntilExit()
      } catch {
        fail("could not run tccutil: \(error.localizedDescription)")
      }

      let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
      let errorMessage = String(data: errorData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)

      // Exit 64 means that an app identity is not registered on this Mac,
      // or that the legacy preview service is absent. Neither should
      // prevent the current Full Lock identity from being reset.
      if process.terminationStatus != 0 && process.terminationStatus != 64 {
        let detail = errorMessage.map { " (\($0))" } ?? ""
        failedResets.append("\(service):\(bundleIdentifier)\(detail)")
      }
    }
  }

  guard failedResets.isEmpty else {
    fail("tccutil could not reset \(failedResets.joined(separator: ", "))")
  }

  print("Revoked Full Lock access for every registered KeyClean app identity.")
  print("Close and reopen System Settings if its Accessibility list is stale.")
  return 0
}

let arguments = Array(CommandLine.arguments.dropFirst())

do {
  switch try CLIParser.parse(arguments) {
  case .launch(let mode, let revokeAfterSession):
    let launchStatus = launch(mode)
    if revokeAfterSession {
      exit(revokeFullAccess())
    }
    exit(launchStatus)
  case .revokeFullAccess:
    exit(revokeFullAccess())
  case .help:
    print(keyCleanHelpText)
  case .version:
    print("\(KeyCleanMetadata.name) \(KeyCleanMetadata.version)")
  }
} catch let error as CLIParseError {
  fail("\(error.description)\nTry 'keyclean --help'.", code: 64)
} catch {
  fail(error.localizedDescription)
}
