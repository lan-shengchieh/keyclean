# Contributing to keyclean

Thanks for helping make `keyclean` safer and easier to use.

## Before opening an issue

- Search the existing issues first.
- Include your macOS version, Mac architecture, terminal app, and `keyclean`
  version.
- For keyboard-blocking problems, say which input was not blocked. Do not post
  private text that was typed while reproducing the issue.

## Local development

Requirements: macOS and Apple Command Line Tools with Swift.

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make clean
make test
```

Before submitting a pull request, also test the interactive flow:

```sh
./keyclean
```

Confirm that ordinary keys are blocked, the trackpad still works, and `⌃⌥⌘U`
unlocks and exits.

## Pull requests

- Keep each pull request focused on one change.
- Explain the user-visible behavior and how you tested it.
- Update the README when installation, permissions, or unlock behavior changes.
- Do not add analytics, network access, or background persistence without prior
  discussion. The project is intentionally local and minimal.

By contributing, you agree that your contribution is licensed under the MIT
License in this repository.
