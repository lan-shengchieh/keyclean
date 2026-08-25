# Publishing keyclean

Maintainer checklist for releases and the Homebrew tap.

- Upstream: <https://github.com/lan-shengchieh/keyclean>
- Tap: <https://github.com/lan-shengchieh/homebrew-tap>
- Install: `brew install lan-shengchieh/tap/keyclean`

## Prepare a release

1. Keep the version synchronized in `KeyCleanMetadata.version` and both
   Info.plist resources; increment `CFBundleVersion` in both resources for every
   published bundle.
2. Update user-facing documentation when behavior or permission boundaries
   change.
3. Run the non-interactive checks:

   ```sh
   make clean
   make test
   make cross-build
   ```

4. Build the exact free distribution layout and test both interactive modes:

   ```sh
   make bundle
   build/layout/bin/keyclean --safe
   build/layout/bin/keyclean --full
   ```

   Confirm on clean macOS 13, 15, and 26 test systems that Safe Mode requests no
   privacy permission; Full Lock lists KeyClean Full Lock rather than the
   terminal; unlock, process termination, display changes, and
   `--revoke-full-access` all restore input safely. Do not substitute a day-to-day
   development machine for clean TCC state.

5. Commit and push the release preparation.
6. Create an annotated, immutable version tag:

   ```sh
   VERSION="0.2.0"
   git tag -a "v${VERSION}" -m "keyclean v${VERSION}"
   git push origin main "v${VERSION}"
   gh release create "v${VERSION}" \
     --title "keyclean v${VERSION}" \
     --generate-notes
   ```

Never move or replace a published tag. Homebrew treats changed release checksums
as a possible supply-chain compromise.

## Update the tap

Calculate the checksum of the exact tagged archive:

```sh
VERSION="0.2.0"
ARCHIVE="/tmp/keyclean-${VERSION}.tar.gz"

curl -L \
  "https://github.com/lan-shengchieh/keyclean/archive/refs/tags/v${VERSION}.tar.gz" \
  -o "${ARCHIVE}"
shasum -a 256 "${ARCHIVE}"
```

In `lan-shengchieh/homebrew-tap`, update the Formula URL and SHA-256. Remove the
temporary v0.1 source-compatibility branch once stable points at v0.2.0, then
run:

```sh
brew update
brew reinstall --build-from-source lan-shengchieh/tap/keyclean
brew test lan-shengchieh/tap/keyclean
brew audit --strict --formula lan-shengchieh/tap/keyclean
brew style lan-shengchieh/tap/keyclean
```

Verify the installed keg contains `bin/keyclean`, `libexec/KeyClean.app`, and
`libexec/KeyCleanFull.app`; both bundles must pass `codesign --verify --deep
--strict`. The free release is ad-hoc signed and not notarized, so release notes
must not claim publisher authentication or OS-enforced network isolation.

Commit the tap update as `keyclean <version>` and push it.

## GitHub repository presentation

Keep the repository metadata aligned with the README:

- Description: `Lock your Mac keyboard while cleaning it—without disabling the trackpad.`
- Topics: `macos`, `swift`, `cli`, `keyboard`, `utility`, `homebrew`, `macbook`,
  `accessibility`, `privacy`
- Social preview: upload `.github/social-preview.jpg` under
  **Settings → General → Social preview**.

The checked-in social preview is 1280 × 640 and under 1 MB, matching GitHub's
recommended dimensions and upload limit.

## Official Homebrew repository eligibility

The third-party tap is the supported Homebrew distribution route. Do not open a
`homebrew/core` pull request for the current Formula: KeyClean's usable product
includes native `.app` bundles, and Homebrew's current Formula policy directs
native macOS applications toward Casks. An official Cask would instead require
an upstream prebuilt artifact that satisfies the current Cask and Gatekeeper
rules, which the source-built, ad-hoc-signed release deliberately does not
provide.

Re-evaluate the package type and live policies before proposing official
distribution:

- [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)

Repository age and notability are additional requirements, not a way around the
package-type issue. A self-submission normally needs at least 90 forks, 90
watchers, or 225 stars, and repositories less than 30 days old are normally not
eligible. These thresholds can change.
