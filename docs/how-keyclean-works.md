# How KeyClean blocks input without granting Accessibility to your terminal

KeyClean 0.2 separates a permission-free foreground cleaning mode from an
opt-in system-wide lock. Both are launched by a small CLI through macOS
LaunchServices and terminate completely after unlocking.

## Process layout

The reproducible free build installs three components:

```text
Terminal (no Accessibility)
  └─ keyclean CLI (no Accessibility)
       ├─ Safe Mode → KeyClean.app (no TCC permission)
       └─ Full Lock → KeyCleanFull.app (Accessibility, if granted)
```

The CLI calls `NSWorkspace.openApplication` instead of executing an app binary
as a terminal child. This gives macOS an application bundle to identify as the
responsible code for privacy decisions. The CLI waits for that application to
exit so the terminal workflow remains `keyclean` → clean → unlock → prompt.

Only one process with either KeyClean bundle identifier may run at a time.

## Safe Mode event flow

1. `KeyClean.app` activates and creates a borderless overlay for every
   `NSScreen`.
2. App presentation options hide the Dock and menu bar and disable application
   switching, Hide, the Apple menu, and the Force Quit panel while KeyClean is
   active.
3. A local `NSEvent` monitor receives keyboard events dispatched to KeyClean.
4. The monitor recognizes `⌃⌥⌘U`, then returns `nil` for key-down, key-up,
   modifier, and visible system-defined events.
5. Clicking Unlock or pressing the shortcut removes the monitor, restores the
   previous presentation options, closes every overlay, and exits.

This needs no Accessibility or Input Monitoring permission because it modifies
only events delivered to KeyClean itself. That is also its boundary: macOS may
handle certain media keys, Touch ID, or the power button before an application
can cancel them.

Safe Mode listens for display-topology changes and reconciles its overlay set.
If KeyClean loses application focus, it exits immediately rather than claiming
to protect events it can no longer consume.

## Full Lock event flow

1. `KeyCleanFull.app` checks `AXIsProcessTrusted()`.
2. When access is missing, the normal-level permission panel offers Open System
   Settings and Cancel. Opening Settings moves the panel behind it so the
   permission controls remain usable.
3. KeyClean observes `NSApplication.didBecomeActiveNotification`. Returning
   from System Settings triggers another `AXIsProcessTrusted()` check and starts
   Full Lock automatically after approval; macOS exposes no public TCC-change
   callback for this permission.
4. After approval, the app creates a session-level `CGEventTap` at the head of
   the tap chain with `CGEventTapOptions.defaultTap`.
5. The callback returns `nil` for keyboard, modifier, and visible system-defined
   events. It recognizes `⌃⌥⌘U` before discarding the event.
6. A small floating panel remains mouse-accessible. Unlocking disables and
   invalidates the tap, removes its run-loop source, closes the panel, and exits.

Pointer events are deliberately absent from the event mask. If macOS disables a
slow tap, the callback re-enables it. Terminating the process also causes macOS
to remove the tap.

## Why the modes use different apps

An active event filter can discard input but needs macOS Accessibility. A
listen-only event tap can use the narrower Input Monitoring permission, but it
cannot implement keyboard suppression.

Accessibility grants broader input capabilities than KeyClean needs. macOS does
not expose a public keyboard-suppression-only TCC capability. The free build
therefore isolates that broad permission to `KeyCleanFull.app`; the default Safe
Mode app and the terminal never receive it.

Run this to revoke KeyClean's Full Lock decisions without touching the
terminal's permissions:

```sh
keyclean --revoke-full-access
```

`keyclean --full-once` uses the same reset immediately after the launched Full
Lock app terminates. Because the CLI waits through LaunchServices, this also
covers Cancel and app crashes while the CLI itself remains alive.

The CLI refuses to reset permission while either KeyClean app is running. It
resets the current Full Lock identifier and the KeyClean identifier used by
early v0.2 previews. It also clears the preview build's `PostEvent` decision,
but never resets a terminal application's privacy settings.

## Signing boundary

The Homebrew Formula compiles the immutable tagged source locally. Its default
split build uses ad-hoc code signatures and Hardened Runtime so assembled code
is sealed, but an ad-hoc signature has no publisher identity and is not
notarized.

The split layout is the only supported build. Both apps are signed without
entitlements and contain no network or file-handling feature, but the operating
system does not enforce a no-network boundary for this build.

## Recovery paths

- Click **Unlock Keyboard** with the trackpad or mouse.
- Press `Control + Option + Command + U`.
- Terminate the active KeyClean app from another session.
- If Safe Mode loses focus, it restores state and exits automatically.

Crashing or killing either app cannot leave an event monitor or event tap
installed because both mechanisms belong to the terminating process.
