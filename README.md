# keyclean

A tiny macOS command-line utility that suppresses keyboard events while you clean a MacBook keyboard.

## Behavior

Run:

```sh
keyclean
```

While it is running:

- ordinary keyboard events are swallowed;
- modifier keys are swallowed;
- media/system key events visible to the session event tap are swallowed;
- trackpad and mouse input continue to work;
- `Control + Option + Command + U` exits the program and restores normal input;
- closing the Terminal window with the trackpad also ends the process, which removes the event tap.

Touch ID and the physical power button are outside the guarantee of this tool.

## Requirements

- macOS
- Apple Command Line Tools with Swift (`swiftc`)
- Accessibility permission for the terminal app that launches `keyclean`

Check your compiler:

```sh
swiftc --version
```

## Build

```sh
make
./keyclean --version
```

Or directly:

```sh
xcrun swiftc -O keyclean.swift -o keyclean
```

## Install locally

```sh
make install
```

By default this installs to:

```text
~/.local/bin/keyclean
```

Make sure `~/.local/bin` is in your `PATH`.

## Homebrew

After replacing `YOUR_GITHUB_USERNAME` below with the actual GitHub username:

```sh
brew install YOUR_GITHUB_USERNAME/tap/keyclean
```

## Permission

On first use, macOS may require Accessibility permission:

**System Settings → Privacy & Security → Accessibility**

Enable the terminal application you use to launch `keyclean`, then run the command again.

## Release

See `PUBLISHING.md`.

## License

MIT
