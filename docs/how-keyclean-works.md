# How keyclean locks a Mac keyboard without disabling the trackpad

`keyclean` is a one-file Swift command-line utility for temporarily locking a
Mac keyboard while it is being cleaned. It uses a macOS Core Graphics event tap
instead of a kernel extension, device driver, login item, or background service.

## The event flow

1. `keyclean` creates a session-level `CGEventTap` at the head of the event-tap
   chain.
2. The event mask includes ordinary key presses, key releases, modifier changes,
   and system-defined keyboard events such as the media keys visible at this
   layer.
3. The callback returns `nil` for those events, which prevents them from
   continuing to the active application.
4. `Control + Option + Command + U` stops the run loop instead of being passed
   through.
5. The process disables and removes its event tap before exiting. macOS also
   removes the tap automatically if the process is terminated.

The complete implementation is in [keyclean.swift](../keyclean.swift).

## Why the trackpad keeps working

The event mask deliberately excludes mouse, cursor, scrolling, and gesture
events. `keyclean` never seizes a pointing device, so the trackpad or mouse can
still move the pointer and close the Terminal window if needed.

That is the project's main tradeoff: it is a focused keyboard-cleaning CLI, not
a full-screen mode that disables every input device.

## Why Accessibility permission is required

macOS protects event taps that can suppress user input. The terminal application
that launches `keyclean` therefore needs Accessibility permission. `keyclean`
does not require `sudo`, administrator privileges, Input Monitoring permission,
or a persistent helper.

## Privacy and security boundaries

- The callback does not convert key codes into text or store input.
- There is no network code, analytics, configuration file, or background process.
- `keyclean` is not a login lock, security boundary, or parental-control tool.
- Touch ID and the physical power button are handled below the event-tap layer
  and are outside its guarantee.
- If macOS disables a slow event tap, `keyclean` re-enables it before continuing.

Because the source is a single file with no third-party dependencies, users can
inspect the entire input-handling path before building it.

## Recovery paths

Use any of these methods to restore normal keyboard input:

1. Press `Control + Option + Command + U`.
2. Use the trackpad or mouse to close the Terminal window running `keyclean`.
3. Terminate the `keyclean` process from another session.

All three end the process and remove its event tap.

## Build and inspect it yourself

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make test
```

The Homebrew Formula also compiles the tagged Swift source directly rather than
downloading a prebuilt executable.
