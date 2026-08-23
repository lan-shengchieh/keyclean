# keyclean

[![CI](https://github.com/lan-shengchieh/keyclean/actions/workflows/ci.yml/badge.svg)](https://github.com/lan-shengchieh/keyclean/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/lan-shengchieh/keyclean)](https://github.com/lan-shengchieh/keyclean/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[繁體中文](README.zh-TW.md)

Lock the keyboard. Keep the trackpad. Clean your MacBook without accidental keystrokes.

`keyclean` is a tiny, open-source macOS command-line utility. It temporarily
swallows keyboard input while leaving the trackpad and mouse available, then
restores normal input when you press the unlock shortcut or exit the process.

## Install

```sh
brew install lan-shengchieh/tap/keyclean
```

Then run:

```sh
keyclean
```

Unlock with **Control + Option + Command + U** (`⌃⌥⌘U`). You can also close the
Terminal window with the trackpad; ending the process removes the event tap and
restores keyboard input.

## First run

macOS may ask for Accessibility permission for the terminal app that launches
`keyclean`:

**System Settings → Privacy & Security → Accessibility**

Enable Terminal, iTerm2, or the terminal application you use, then run
`keyclean` again.

## What it does

| Input | While `keyclean` runs |
| --- | --- |
| Ordinary keys and modifiers | Blocked |
| Media/system keys visible to the session event tap | Blocked |
| Trackpad and mouse | Available |
| `⌃⌥⌘U` | Unlocks and exits |

Touch ID and the physical power button are outside the guarantee of this tool.

## Small by design

- One Swift source file and no third-party dependencies.
- No network access, analytics, background service, or stored data.
- Keyboard input returns automatically when the process exits.
- Source builds and tests on GitHub Actions for macOS.

## Build from source

Requirements: macOS and Apple Command Line Tools with Swift.

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make test
```

Install the locally built binary to `~/.local/bin`:

```sh
make install
```

## Troubleshooting

**`could not create the keyboard event tap`**

Grant Accessibility permission to the terminal app that launches `keyclean`,
quit and reopen that app if needed, then try again.

**The keyboard is still locked**

Press `⌃⌥⌘U`. If that does not work, close the Terminal window with the
trackpad. Exiting the process removes the event tap.

## Contributing

Bug reports, compatibility results, and focused pull requests are welcome. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the local test commands.

If `keyclean` saves you from an accidental key press, sharing the project helps
other Mac users find it.

## License

[MIT](LICENSE)
