# keyclean

[![CI](https://github.com/lan-shengchieh/keyclean/actions/workflows/ci.yml/badge.svg)](https://github.com/lan-shengchieh/keyclean/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/lan-shengchieh/keyclean)](https://github.com/lan-shengchieh/keyclean/releases/latest)
[![GitHub stars](https://img.shields.io/github/stars/lan-shengchieh/keyclean?style=flat)](https://github.com/lan-shengchieh/keyclean/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[繁體中文](README.zh-TW.md)

![keyclean — Lock the keys. Keep the trackpad.](.github/social-preview.jpg)

Lock the keyboard. Keep the trackpad. Clean your MacBook without accidental
keystrokes.

KeyClean 0.2 provides two deliberately different security modes on macOS 13 or
later:

- **Safe Mode** is the default. It covers every display, consumes keyboard
  events delivered to KeyClean, and requests no Accessibility permission.
- **Full Lock** is opt-in. It uses an active Core Graphics event tap to suppress
  keyboard events system-wide. Accessibility belongs to a dedicated KeyClean
  app, never to Terminal, iTerm2, or another terminal application.

Both modes leave the pointer available and exit completely when you unlock.
There is no daemon, login item, analytics, network code, or stored input.

## Install

```sh
brew install lan-shengchieh/tap/keyclean
```

Start permission-free Safe Mode:

```sh
keyclean
```

The current tap continues to serve v0.1.0 until v0.2.0 is tagged. To test the
v0.2 source build before that release, use:

```sh
brew install --HEAD lan-shengchieh/tap/keyclean
```

## Choose a mode

### Safe Mode — default, no privacy permission

```sh
keyclean
# or
keyclean --safe
```

Safe Mode places a cleaning overlay on every connected display and keeps
KeyClean in the foreground. Ordinary keys and common application-switching
shortcuts cannot reach another app. Use the trackpad or mouse to click
**Unlock Keyboard**, or press **Control + Option + Command + U** (`⌃⌥⌘U`).

Safe Mode is intentionally a best-effort application-level lock. System-reserved
media keys, Touch ID, and the physical power button may still take effect.

### Full Lock — opt-in Accessibility

```sh
keyclean --full
```

Full Lock suppresses keyboard, modifier, and visible media-key events with an
active `CGEventTap`. Its small floating panel leaves the trackpad and mouse free
to interact with other apps.

On first use, click **Open System Settings**, then enable **KeyClean Full
Lock**—not your terminal—under:

**System Settings → Privacy & Security → Accessibility**

Return to KeyClean afterward. It rechecks access when it becomes active and
starts Full Lock automatically; there is no manual retry step.

Accessibility is a broad macOS permission, not a keyboard-suppression-only
capability. KeyClean cannot make that system permission more granular. Revoke
only KeyClean's Full Lock permission at any time with:

```sh
keyclean --revoke-full-access
```

For a one-time Full Lock that automatically revokes KeyClean access as soon as
the session exits, use:

```sh
keyclean --full-once
```

The next Full Lock will require approval again. Automatic revocation also runs
after Cancel or an app crash, as long as the waiting `keyclean` CLI remains
running.

## Security model

The free, reproducible Homebrew build uses a split layout:

| Component | TCC permission | Purpose |
| --- | --- | --- |
| `keyclean` CLI | None | Launches the selected app through LaunchServices |
| `KeyClean.app` | None | Runs the foreground Safe Mode overlay |
| `KeyCleanFull.app` | Accessibility, when granted | Runs the system-wide active event tap |

The split ensures that using Full Lock never grants Accessibility to the Safe
Mode app or to every command launched by your terminal. Only one KeyClean
session may run at a time, and neither app persists after unlocking.

Homebrew compiles the tagged source locally and applies an ad-hoc code signature
so macOS can verify that the assembled bundle has not changed after signing.
Ad-hoc signing does **not** authenticate the publisher or provide notarization.
The release intentionally ships only this split layout and signs both apps
without entitlements. It contains no network code, but the operating system does
not enforce a no-network boundary for this build.

Read [how KeyClean works](docs/how-keyclean-works.md) for event flow, process
attribution, permission boundaries, and recovery paths.

## Upgrading from v0.1

KeyClean 0.1 asked you to grant Accessibility to the terminal that launched it.
Version 0.2 no longer needs that terminal permission. If you enabled Terminal,
iTerm2, Ghostty, Warp, or another terminal only for KeyClean, disable it manually
in System Settings after upgrading. KeyClean does not revoke terminal permissions
automatically because other workflows may rely on them.

## Build from source

Requirements: macOS 13 or later and Apple Command Line Tools with Swift 5.7 or
later.

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make test
make cross-build
```

Install the locally built CLI and apps under `~/.local`:

```sh
make install
```

`make test` is non-interactive: it runs unit tests, assembles the free split
bundle, validates both property lists and code signatures, and invokes each app's
self-test without requesting privacy permission.

## Troubleshooting

**Safe Mode closes immediately**

Safe Mode must remain the active application to consume events safely. If macOS
moves focus elsewhere, KeyClean exits instead of pretending the keyboard is
still locked.

**Full Lock says Accessibility is missing**

Enable KeyClean Full Lock in Accessibility, then return to KeyClean. It will
recheck automatically. Do not enable your terminal.

**Full Lock is unavailable after permission was granted**

Run `keyclean --revoke-full-access`, start Full Lock again, and re-grant KeyClean
Full Lock in System Settings. If the active event tap is still unavailable, use
Safe Mode.

**`--revoke-full-access` reports success but Settings still looks unchanged**

Close and reopen System Settings; TCC can leave its current view stale. If a
second attempt is needed, run `keyclean --revoke-full-access` again. The command
resets the current Full Lock identity, the early-v0.2 KeyClean identity, and its
legacy `PostEvent` decision; it never resets your terminal.

**The keyboard is still locked**

Click **Unlock Keyboard** or press `⌃⌥⌘U`. Terminating the KeyClean app also
removes its local monitor or event tap automatically.

## Contributing

Bug reports, compatibility results, and focused pull requests are welcome. See
[CONTRIBUTING.md](CONTRIBUTING.md) for checks and reporting details.

Please include the selected mode, macOS version, Mac architecture, terminal app,
and whether Accessibility lists KeyClean or the terminal in compatibility
reports.

## License

[MIT](LICENSE)
