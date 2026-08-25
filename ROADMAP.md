# keyclean roadmap

The goal is to keep `keyclean` small, auditable, and useful while collecting
enough real-world evidence for maintainable Homebrew distribution.

## Now: validate the v0.2 security model

- Verify permission-free Safe Mode on clean macOS 13, 15, and 26 systems.
- Confirm Full Lock lists KeyClean—not Terminal, iTerm2, Ghostty, or Warp—in
  Accessibility on Apple Silicon and Intel Macs.
- Document which media and system keys escape Safe Mode and which are visible
  to the Full Lock session event tap.
- Validate `--revoke-full-access`, display hot-plugging, focus-loss recovery,
  Homebrew upgrades, and ad-hoc TCC behavior across releases.

[Share a compatibility report](https://github.com/lan-shengchieh/keyclean/issues/new?template=compatibility_report.yml)
after testing. Reports of problems are as valuable as successful results.

## Next: evidence-backed packaging

- Keep the reproducible split build as the only supported distribution layout.
- Fix reproducible input or recovery problems without adding a background
  service, analytics, or network code.

## Later: official Homebrew distribution

The third-party tap remains the supported route. The current package includes
native `.app` bundles, so it should not be submitted as a `homebrew/core`
Formula under Homebrew's current policy. Before pursuing an official repository,
re-evaluate whether KeyClean has become an eligible Formula or can provide the
prebuilt, Gatekeeper-compatible artifact expected of a Cask.

The upstream repository was created on August 23, 2026. Homebrew's current
Package Acceptance Policy normally excludes repositories less than 30 days old,
so the first ordinary eligibility date is September 22, 2026.

A self-submission also normally requires at least one documented signal of public
interest: 225 stars, 90 forks, or 90 watchers. These requirements may change, so
the live policy will be checked again before submitting.

- [Homebrew Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy)
- [Homebrew Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Homebrew Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)

Only genuine use and interest count. The project will not buy, trade, or automate
stars, forks, watchers, downloads, or comments.
