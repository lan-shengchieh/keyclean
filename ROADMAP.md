# keyclean roadmap

The goal is to keep `keyclean` small, auditable, and useful while collecting
enough real-world evidence for an eventual submission to `homebrew/core`.

## Now: public testing

- Collect compatibility reports across multiple macOS versions.
- Confirm behavior on Apple Silicon and Intel Macs.
- Test Terminal, iTerm2, Ghostty, Warp, and other commonly used terminals.
- Document which media and system keys are visible to the session event tap.

[Share a compatibility report](https://github.com/lan-shengchieh/keyclean/issues/new?template=compatibility_report.yml)
after testing. Reports of problems are as valuable as successful results.

## Next: evidence-backed improvements

- Summarize meaningful compatibility results in the README.
- Fix reproducible input or recovery problems without adding a background
  service, analytics, or network access.
- Publish a patch release when user-visible behavior changes.

## Later: official Homebrew distribution

The upstream repository was created on August 23, 2026. Homebrew's current
Package Acceptance Policy normally excludes repositories less than 30 days old,
so the first ordinary eligibility date is September 22, 2026.

A self-submission also normally requires at least one documented signal of public
interest: 225 stars, 90 forks, or 90 watchers. These requirements may change, so
the live policy will be checked again before submitting.

- [Homebrew Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy)
- [Homebrew Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)

Only genuine use and interest count. The project will not buy, trade, or automate
stars, forks, watchers, downloads, or comments.
