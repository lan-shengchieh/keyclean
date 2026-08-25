import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import KeyCleanCore

public enum KeyCleanApplication {
  public static func run(allowedModes: Set<SessionMode>) -> Never {
    if CommandLine.arguments.contains("--self-test") {
      print("KeyClean app \(KeyCleanMetadata.version) self-test passed")
      exit(0)
    }

    let application = NSApplication.shared
    let delegate = ApplicationDelegate(allowedModes: allowedModes)
    application.setActivationPolicy(.regular)
    application.delegate = delegate
    withExtendedLifetime(delegate) {
      application.run()
    }
    exit(0)
  }
}

private protocol SessionController: AnyObject {
  func start()
  func invalidate()
}

private final class ApplicationDelegate: NSObject, NSApplicationDelegate {
  private let allowedModes: Set<SessionMode>
  private var session: SessionController?

  init(allowedModes: Set<SessionMode>) {
    self.allowedModes = allowedModes
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard !anotherKeyCleanApplicationIsRunning() else {
      showError(
        title: "KeyClean is already running",
        message: "Unlock the existing cleaning session before starting another one."
      )
      NSApp.terminate(nil)
      return
    }

    guard let mode = requestedMode(), allowedModes.contains(mode) else {
      showError(
        title: "Unsupported KeyClean mode",
        message: "Launch KeyClean through the keyclean command-line tool."
      )
      NSApp.terminate(nil)
      return
    }

    let finish: () -> Void = {
      NSApp.terminate(nil)
    }

    switch mode {
    case .safe:
      session = SafeModeController(onFinish: finish)
    case .full:
      session = FullLockController(onFinish: finish)
    }

    session?.start()
  }

  func applicationWillTerminate(_ notification: Notification) {
    session?.invalidate()
  }

  func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    true
  }

  private func requestedMode() -> SessionMode? {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard let modeIndex = arguments.firstIndex(of: "--mode"),
      arguments.indices.contains(modeIndex + 1)
    else {
      return allowedModes.count == 1 ? allowedModes.first : nil
    }

    return SessionMode(rawValue: arguments[modeIndex + 1])
  }

  private func anotherKeyCleanApplicationIsRunning() -> Bool {
    let identifiers = [
      KeyCleanMetadata.appBundleIdentifier,
      KeyCleanMetadata.fullAppBundleIdentifier,
    ]

    return identifiers.contains { identifier in
      NSRunningApplication.runningApplications(
        withBundleIdentifier: identifier
      ).contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    }
  }

  private func showError(title: String, message: String) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = title
    alert.informativeText = message
    alert.runModal()
  }
}

private final class OverlayWindow: NSWindow {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}

private final class SafeModeController: NSObject, SessionController {
  private let onFinish: () -> Void
  private var windows: [String: NSWindow] = [:]
  private var localMonitor: Any?
  private var screenObserver: NSObjectProtocol?
  private var resignObserver: NSObjectProtocol?
  private var originalPresentationOptions: NSApplication.PresentationOptions = []
  private var isFinishing = false

  init(onFinish: @escaping () -> Void) {
    self.onFinish = onFinish
  }

  func start() {
    originalPresentationOptions = NSApp.presentationOptions
    resignObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didResignActiveNotification,
      object: NSApp,
      queue: .main
    ) { [weak self] _ in
      // Safe Mode can only consume events while it is the active app.
      // End immediately instead of presenting a false lock guarantee.
      self?.finish()
    }

    NSApp.presentationOptions = [
      .hideDock,
      .hideMenuBar,
      .disableAppleMenu,
      .disableProcessSwitching,
      .disableForceQuit,
      .disableHideApplication,
    ]

    localMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.keyDown, .keyUp, .flagsChanged, .systemDefined]
    ) { [weak self] event in
      guard let self else { return nil }

      if event.type == .keyDown,
        KeyboardEvents.isUnlock(
          keyCode: Int64(event.keyCode),
          flags: event.cgEvent?.flags ?? cgFlags(for: event.modifierFlags)
        )
      {
        DispatchQueue.main.async {
          self.finish()
        }
      }

      return nil
    }

    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.reconcileWindows()
    }

    reconcileWindows()
    NSApp.activate(ignoringOtherApps: true)
    windows.values.first?.makeKeyAndOrderFront(nil)

    DispatchQueue.main.async { [weak self] in
      guard let self, !self.isFinishing else { return }
      if !NSApp.isActive {
        self.finish()
      }
    }
  }

  func invalidate() {
    guard !isFinishing else { return }
    isFinishing = true
    cleanUp()
  }

  @objc private func unlock(_ sender: Any?) {
    finish()
  }

  private func finish() {
    guard !isFinishing else { return }
    isFinishing = true
    cleanUp()
    onFinish()
  }

  private func cleanUp() {
    if let localMonitor {
      NSEvent.removeMonitor(localMonitor)
      self.localMonitor = nil
    }

    if let screenObserver {
      NotificationCenter.default.removeObserver(screenObserver)
      self.screenObserver = nil
    }

    if let resignObserver {
      NotificationCenter.default.removeObserver(resignObserver)
      self.resignObserver = nil
    }

    NSApp.presentationOptions = originalPresentationOptions
    for window in windows.values {
      window.close()
    }
    windows.removeAll()
  }

  private func reconcileWindows() {
    let screensByID = Dictionary(
      uniqueKeysWithValues: NSScreen.screens.map { (screenIdentifier($0), $0) }
    )
    let change = ScreenReconciliation(
      existing: Set(windows.keys),
      current: Set(screensByID.keys)
    )

    for identifier in change.removed {
      windows.removeValue(forKey: identifier)?.close()
    }

    for identifier in change.added {
      guard let screen = screensByID[identifier] else { continue }
      let window = makeOverlayWindow(for: screen)
      windows[identifier] = window
      window.orderFrontRegardless()
    }

    for (identifier, screen) in screensByID {
      windows[identifier]?.setFrame(screen.frame, display: true)
    }
  }

  private func screenIdentifier(_ screen: NSScreen) -> String {
    let key = NSDeviceDescriptionKey("NSScreenNumber")
    if let number = screen.deviceDescription[key] as? NSNumber {
      return number.stringValue
    }
    return String(describing: ObjectIdentifier(screen))
  }

  private func cgFlags(
    for modifiers: NSEvent.ModifierFlags
  ) -> CGEventFlags {
    var flags: CGEventFlags = []
    if modifiers.contains(.control) { flags.insert(.maskControl) }
    if modifiers.contains(.option) { flags.insert(.maskAlternate) }
    if modifiers.contains(.command) { flags.insert(.maskCommand) }
    if modifiers.contains(.shift) { flags.insert(.maskShift) }
    if modifiers.contains(.capsLock) { flags.insert(.maskAlphaShift) }
    return flags
  }

  private func makeOverlayWindow(for screen: NSScreen) -> NSWindow {
    let window = OverlayWindow(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false,
      screen: screen
    )
    window.backgroundColor = NSColor(
      calibratedRed: 0.055,
      green: 0.075,
      blue: 0.105,
      alpha: 1
    )
    window.isOpaque = true
    window.hasShadow = false
    // The overlay has an intentionally dark background, so pin the
    // controls to Dark Aqua instead of inheriting the user's appearance.
    window.appearance = NSAppearance(named: .darkAqua)
    window.level = .screenSaver
    window.collectionBehavior = [
      .canJoinAllSpaces,
      .fullScreenAuxiliary,
      .stationary,
      .ignoresCycle,
    ]
    window.contentView = makeSafeModeContentView()
    return window
  }

  private func makeSafeModeContentView() -> NSView {
    let container = NSView()

    let icon = NSTextField(labelWithString: "🔒")
    icon.font = .systemFont(ofSize: 52)
    icon.alignment = .center

    let title = NSTextField(labelWithString: "Keyboard cleaning mode")
    title.font = .systemFont(ofSize: 30, weight: .semibold)
    title.textColor = .white
    title.alignment = .center

    let status = NSTextField(
      wrappingLabelWithString:
        "Safe Mode · No Accessibility permission\nKeyboard events sent to KeyClean are being discarded."
    )
    status.font = .systemFont(ofSize: 15)
    status.textColor = NSColor.white.withAlphaComponent(0.72)
    status.alignment = .center

    let limitation = NSTextField(
      wrappingLabelWithString:
        "Some system-reserved media keys, Touch ID, and the power button may still take effect."
    )
    limitation.font = .systemFont(ofSize: 12)
    limitation.textColor = NSColor.white.withAlphaComponent(0.48)
    limitation.alignment = .center

    let button = NSButton(
      title: "Unlock Keyboard",
      target: self,
      action: #selector(unlock(_:))
    )
    button.bezelStyle = .rounded
    button.bezelColor = NSColor(
      srgbRed: 0.0,
      green: 0.40,
      blue: 0.80,
      alpha: 1
    )
    button.contentTintColor = .white
    button.font = .systemFont(ofSize: 16, weight: .semibold)
    button.controlSize = .large

    let shortcut = NSTextField(labelWithString: "or press  ⌃⌥⌘U")
    shortcut.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    shortcut.textColor = NSColor.white.withAlphaComponent(0.58)
    shortcut.alignment = .center

    let stack = NSStackView(views: [
      icon, title, status, button, shortcut, limitation,
    ])
    stack.orientation = .vertical
    stack.alignment = .centerX
    stack.spacing = 16
    stack.setCustomSpacing(24, after: status)
    stack.setCustomSpacing(28, after: shortcut)
    stack.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      stack.leadingAnchor.constraint(
        greaterThanOrEqualTo: container.leadingAnchor,
        constant: 32
      ),
      stack.trailingAnchor.constraint(
        lessThanOrEqualTo: container.trailingAnchor,
        constant: -32
      ),
      status.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
      limitation.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
      button.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 42),
    ])
    return container
  }
}

private final class FullLockController: NSObject, SessionController, NSWindowDelegate {
  private let onFinish: () -> Void
  private var panel: NSPanel?
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var activeObserver: NSObjectProtocol?
  private var isFinishing = false

  init(onFinish: @escaping () -> Void) {
    self.onFinish = onFinish
  }

  func start() {
    makePanelIfNeeded()
    evaluateAccess()
    activeObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: NSApp,
      queue: .main
    ) { [weak self] _ in
      self?.evaluateAccess()
    }
  }

  func invalidate() {
    guard !isFinishing else { return }
    isFinishing = true
    cleanUp()
  }

  func windowWillClose(_ notification: Notification) {
    guard !isFinishing else { return }
    finish()
  }

  @objc private func unlock(_ sender: Any?) {
    finish()
  }

  @objc private func openAccessibilitySettings(_ sender: Any?) {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    else { return }
    prepareForExternalPermissionUI()
    NSWorkspace.shared.open(url)
  }

  @objc private func cancel(_ sender: Any?) {
    finish()
  }

  private func finish() {
    guard !isFinishing else { return }
    isFinishing = true
    cleanUp()
    onFinish()
  }

  private func cleanUp() {
    if let activeObserver {
      NotificationCenter.default.removeObserver(activeObserver)
      self.activeObserver = nil
    }

    removeEventTap()

    panel?.delegate = nil
    panel?.close()
    panel = nil
  }

  private func removeEventTap() {
    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
      self.runLoopSource = nil
    }

    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      CFMachPortInvalidate(eventTap)
      self.eventTap = nil
    }
  }

  private func evaluateAccess() {
    guard !isFinishing else { return }

    if AXIsProcessTrusted() {
      installEventTap()
      return
    }

    removeEventTap()
    showPermissionInstructions()
  }

  private func prepareForExternalPermissionUI() {
    panel?.level = .normal
    panel?.orderBack(nil)
  }

  private func setPanelLevel(for state: FullLockPanelState) {
    panel?.level = state.shouldFloat ? .floating : .normal
  }

  private func installEventTap() {
    if let eventTap {
      if CGEvent.tapIsEnabled(tap: eventTap) {
        showLockedControls()
        return
      }
      removeEventTap()
    }

    let userInfo = Unmanaged.passUnretained(self).toOpaque()
    let tap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: KeyboardEvents.eventsOfInterest,
      callback: fullLockCallback,
      userInfo: userInfo
    )

    guard let tap else {
      showTapUnavailable()
      return
    }

    guard
      let source = CFMachPortCreateRunLoopSource(
        kCFAllocatorDefault,
        tap,
        0
      )
    else {
      CFMachPortInvalidate(tap)
      showTapUnavailable()
      return
    }

    eventTap = tap
    runLoopSource = source
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    guard CGEvent.tapIsEnabled(tap: tap) else {
      removeEventTap()
      showTapUnavailable()
      return
    }

    showLockedControls()
  }

  fileprivate func handleEvent(
    type: CGEventType,
    event: CGEvent
  ) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: true)
        if !CGEvent.tapIsEnabled(tap: eventTap) {
          DispatchQueue.main.async { [weak self] in
            guard let self, !self.isFinishing else { return }
            self.removeEventTap()
            self.showTapUnavailable()
          }
        }
      }
      return Unmanaged.passUnretained(event)
    }

    if type == .keyDown,
      KeyboardEvents.isUnlock(
        keyCode: event.getIntegerValueField(.keyboardEventKeycode),
        flags: event.flags
      )
    {
      DispatchQueue.main.async { [weak self] in
        self?.finish()
      }
      return nil
    }

    if type == .keyDown || type == .keyUp || type == .flagsChanged {
      return nil
    }

    if type.rawValue == KeyboardEvents.systemDefinedRaw {
      return nil
    }

    return Unmanaged.passUnretained(event)
  }

  private func makePanelIfNeeded() {
    guard panel == nil else { return }

    let panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 430, height: 260),
      styleMask: [.titled, .closable, .utilityWindow],
      backing: .buffered,
      defer: false
    )
    panel.title = "KeyClean"
    panel.isReleasedWhenClosed = false
    panel.hidesOnDeactivate = false
    panel.isMovableByWindowBackground = true
    panel.level = .normal
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.delegate = self
    panel.center()
    self.panel = panel

    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
  }

  private func showPermissionInstructions() {
    setPanelLevel(for: .permission)
    panel?.contentView = makePanelContent(
      symbol: "🔐",
      title: "Full Lock needs Accessibility",
      message:
        "Enable KeyClean Full Lock—not Terminal—in System Settings, then return to KeyClean. Full Lock will start automatically.",
      buttons: [
        ("Open System Settings", #selector(openAccessibilitySettings(_:))),
        ("Cancel", #selector(cancel(_:))),
      ]
    )
    panel?.makeKeyAndOrderFront(nil)
  }

  private func showTapUnavailable() {
    setPanelLevel(for: .unavailable)
    panel?.contentView = makePanelContent(
      symbol: "⚠️",
      title: "Full Lock is unavailable",
      message:
        "macOS allowed event access but denied the active event tap. Cancel and use permission-free Safe Mode. If this persists, revoke and re-grant KeyClean Full Lock in System Settings.",
      buttons: [
        ("Cancel", #selector(cancel(_:)))
      ]
    )
    panel?.makeKeyAndOrderFront(nil)
  }

  private func showLockedControls() {
    setPanelLevel(for: .locked)
    panel?.contentView = makePanelContent(
      symbol: "🔒",
      title: "Keyboard locked",
      message:
        "Full Lock · Accessibility belongs to KeyClean\nYour trackpad and mouse remain available.",
      buttons: [
        ("Unlock Keyboard", #selector(unlock(_:)))
      ],
      footer: "or press  ⌃⌥⌘U"
    )
    panel?.makeKeyAndOrderFront(nil)
  }

  private func makePanelContent(
    symbol: String,
    title: String,
    message: String,
    buttons: [(String, Selector)],
    footer: String? = nil
  ) -> NSView {
    let container = NSView()

    let symbolLabel = NSTextField(labelWithString: symbol)
    symbolLabel.font = .systemFont(ofSize: 34)
    symbolLabel.alignment = .center

    let titleLabel = NSTextField(labelWithString: title)
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.alignment = .center

    let messageLabel = NSTextField(wrappingLabelWithString: message)
    messageLabel.alignment = .center
    messageLabel.textColor = .secondaryLabelColor

    let buttonViews = buttons.map { title, action -> NSButton in
      let button = NSButton(title: title, target: self, action: action)
      button.bezelStyle = .rounded
      return button
    }
    let buttonStack = NSStackView(views: buttonViews)
    buttonStack.orientation = .horizontal
    buttonStack.alignment = .centerY
    buttonStack.distribution = .fillProportionally
    buttonStack.spacing = 8

    var views: [NSView] = [symbolLabel, titleLabel, messageLabel, buttonStack]
    if let footer {
      let footerLabel = NSTextField(labelWithString: footer)
      footerLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
      footerLabel.textColor = .tertiaryLabelColor
      footerLabel.alignment = .center
      views.append(footerLabel)
    }

    let stack = NSStackView(views: views)
    stack.orientation = .vertical
    stack.alignment = .centerX
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      stack.leadingAnchor.constraint(
        greaterThanOrEqualTo: container.leadingAnchor,
        constant: 24
      ),
      stack.trailingAnchor.constraint(
        lessThanOrEqualTo: container.trailingAnchor,
        constant: -24
      ),
      messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 370),
    ])
    return container
  }
}

private let fullLockCallback: CGEventTapCallBack = {
  _, type, event, userInfo in
  guard let userInfo else {
    return Unmanaged.passUnretained(event)
  }

  let controller = Unmanaged<FullLockController>
    .fromOpaque(userInfo)
    .takeUnretainedValue()
  return controller.handleEvent(type: type, event: event)
}
