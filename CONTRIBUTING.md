# Contributing to keyclean

Thanks for helping make `keyclean` safer and easier to use.

## Before opening an issue

- Search the existing issues first.
- Include the Safe/Full mode, macOS version, Mac architecture, terminal app,
  `keyclean` version, and which app appears in Accessibility.
- For keyboard-blocking problems, say which input was not blocked. Do not post
  private text that was typed while reproducing the issue.

## Local development

Requirements: macOS 13 or later and Apple Command Line Tools with Swift 5.7 or
later.

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make clean
make test
make cross-build
```

Before submitting a pull request, also test the interactive flow:

```sh
build/layout/bin/keyclean --safe
build/layout/bin/keyclean --full
```

Confirm that Safe Mode requests no privacy permission, Full Lock identifies
KeyClean rather than the terminal in Accessibility, the pointer still works,
and both the button and `⌃⌥⌘U` unlock and exit.

## Pull requests

- Keep each pull request focused on one change.
- Explain the user-visible behavior and how you tested it.
- Update the README when installation, permissions, or unlock behavior changes.
- Do not add analytics, network code or entitlements, file-access entitlements,
  or background persistence without prior discussion. The project is
  intentionally local and minimal.

By contributing, you agree that your contribution is licensed under the MIT
License in this repository.
