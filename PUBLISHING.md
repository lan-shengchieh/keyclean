# Publishing keyclean

Maintainer checklist for releases and the Homebrew tap.

- Upstream: <https://github.com/lan-shengchieh/keyclean>
- Tap: <https://github.com/lan-shengchieh/homebrew-tap>
- Install: `brew install lan-shengchieh/tap/keyclean`

## Prepare a release

1. Update `appVersion` in `keyclean.swift`.
2. Update user-facing documentation when behavior changes.
3. Run the local checks:

   ```sh
   make clean
   make test
   ./keyclean
   ```

4. Commit and push the release preparation.
5. Create an annotated, immutable version tag:

   ```sh
   VERSION="0.1.1"
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
VERSION="0.1.1"
ARCHIVE="/tmp/keyclean-${VERSION}.tar.gz"

curl -L \
  "https://github.com/lan-shengchieh/keyclean/archive/refs/tags/v${VERSION}.tar.gz" \
  -o "${ARCHIVE}"
shasum -a 256 "${ARCHIVE}"
```

In `lan-shengchieh/homebrew-tap`, update the Formula URL and SHA-256, then run:

```sh
brew update
brew reinstall --build-from-source lan-shengchieh/tap/keyclean
brew test lan-shengchieh/tap/keyclean
brew audit --strict --formula lan-shengchieh/tap/keyclean
brew style lan-shengchieh/tap/keyclean
```

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

## Homebrew/core readiness

Do not open a `homebrew/core` pull request until the project satisfies the
current official policies:

- [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)

Because a pull request from the upstream repository owner is a self-submission,
the normal notability threshold is at least 90 forks, 90 watchers, or 225 stars.
A repository less than 30 days old is normally not eligible. Recheck the live
policy before submitting because these requirements can change.

For a new core Formula, run the stricter validation immediately before opening
the pull request:

```sh
HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source keyclean
brew test keyclean
brew audit --new --strict --formula keyclean
brew style keyclean
```

Homebrew requires disclosure when AI/LLM assistance was used on the submission.
Review the current contribution policy and answer maintainer questions yourself.
