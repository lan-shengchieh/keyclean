# Publishing keyclean and a Homebrew tap

This guide assumes:

- main repository: `https://github.com/YOUR_GITHUB_USERNAME/keyclean`
- tap repository: `https://github.com/YOUR_GITHUB_USERNAME/homebrew-tap`
- first release: `v0.1.0`

Replace `YOUR_GITHUB_USERNAME` everywhere before publishing.

## 1. Prerequisites

```sh
brew install gh
gh auth login

git --version
gh --version
brew --version
swiftc --version
```

## 2. Test the project locally

From the `keyclean` directory:

```sh
make clean
make
./keyclean --version
./keyclean --help
```

Expected version output:

```text
keyclean 0.1.0
```

Then test the actual cleaning mode:

```sh
./keyclean
```

Unlock with:

```text
Control + Option + Command + U
```

## 3. Create the main Git repository

From the `keyclean` directory:

```sh
git init -b main
git add .
git commit -m "Initial release"
```

Create the GitHub repository and push:

```sh
gh repo create keyclean \
  --public \
  --source=. \
  --remote=origin \
  --push
```

Confirm:

```sh
git remote -v
git status
```

## 4. Create v0.1.0

Create an annotated tag:

```sh
git tag -a v0.1.0 -m "keyclean v0.1.0"
git push origin v0.1.0
```

Create a GitHub Release:

```sh
gh release create v0.1.0 \
  --title "keyclean v0.1.0" \
  --generate-notes
```

## 5. Calculate the source archive SHA-256

Set your GitHub username once in the shell:

```sh
GH_USER="YOUR_GITHUB_USERNAME"
VERSION="0.1.0"
```

Download the exact archive that the Homebrew Formula will use:

```sh
curl -L \
  "https://github.com/${GH_USER}/keyclean/archive/refs/tags/v${VERSION}.tar.gz" \
  -o "/tmp/keyclean-${VERSION}.tar.gz"
```

Calculate the checksum:

```sh
SHA256="$(shasum -a 256 "/tmp/keyclean-${VERSION}.tar.gz" | awk '{print $1}')"
echo "$SHA256"
```

Keep this value. It goes into the Formula.

## 6. Create the Homebrew tap

Homebrew's recommended helper creates the tap layout and CI workflow files:

```sh
brew tap-new "${GH_USER}/homebrew-tap"
```

Find the generated tap directory:

```sh
TAP_DIR="$(brew --repository "${GH_USER}/homebrew-tap")"
echo "$TAP_DIR"
```

Copy the Formula template from this release kit:

```sh
cp ../homebrew-tap-template/Formula/keyclean.rb \
  "${TAP_DIR}/Formula/keyclean.rb"
```

Replace the placeholders in the Formula:

```sh
sed -i '' "s/YOUR_GITHUB_USERNAME/${GH_USER}/g" \
  "${TAP_DIR}/Formula/keyclean.rb"

sed -i '' "s/REPLACE_WITH_SHA256/${SHA256}/g" \
  "${TAP_DIR}/Formula/keyclean.rb"
```

Inspect it:

```sh
cat "${TAP_DIR}/Formula/keyclean.rb"
```

## 7. Commit and publish the tap

```sh
cd "$TAP_DIR"

git add Formula/keyclean.rb
git commit -m "keyclean 0.1.0 (new formula)"
```

Create the GitHub tap repository and push it:

```sh
gh repo create "${GH_USER}/homebrew-tap" \
  --public \
  --source=. \
  --remote=origin \
  --push
```

If `brew tap-new` already configured a remote in your Homebrew version, inspect first:

```sh
git remote -v
```

If an `origin` already exists, create the GitHub repository without `--remote=origin`,
then push using the existing remote as appropriate.

## 8. Test installation from the tap

First uninstall any manually installed copy that could hide a problem:

```sh
rm -f ~/.local/bin/keyclean
```

Then build/install from your tap:

```sh
brew uninstall keyclean 2>/dev/null || true
brew install --build-from-source "${GH_USER}/tap/keyclean"
```

Verify:

```sh
which keyclean
keyclean --version
brew test "${GH_USER}/tap/keyclean"
```

Then test interactive behavior:

```sh
keyclean
```

Unlock with `Control + Option + Command + U`.

## 9. Audit the Formula

```sh
brew audit --formula "${GH_USER}/tap/keyclean"
```

For a third-party tap, an audit warning does not always mean the formula is unusable,
but fix genuine syntax/style issues before announcing the release.

## 10. User installation command

Users can install directly with:

```sh
brew install YOUR_GITHUB_USERNAME/tap/keyclean
```

Homebrew will add the tap automatically.

## 11. Future releases

Example for `0.1.1`.

### Main repository

1. Change `appVersion` in `keyclean.swift` to `0.1.1`.
2. Commit and push:

```sh
git add keyclean.swift
git commit -m "Prepare v0.1.1"
git push
```

3. Tag and release:

```sh
git tag -a v0.1.1 -m "keyclean v0.1.1"
git push origin v0.1.1
gh release create v0.1.1 --title "keyclean v0.1.1" --generate-notes
```

### Recalculate SHA-256

```sh
GH_USER="YOUR_GITHUB_USERNAME"
VERSION="0.1.1"

curl -L \
  "https://github.com/${GH_USER}/keyclean/archive/refs/tags/v${VERSION}.tar.gz" \
  -o "/tmp/keyclean-${VERSION}.tar.gz"

SHA256="$(shasum -a 256 "/tmp/keyclean-${VERSION}.tar.gz" | awk '{print $1}')"
echo "$SHA256"
```

### Update the tap Formula

Edit:

```text
Formula/keyclean.rb
```

Change:

- URL tag/version to the new release.
- `sha256` to the new checksum.

Then:

```sh
brew audit --formula "${GH_USER}/tap/keyclean"
brew reinstall --build-from-source "${GH_USER}/tap/keyclean"
brew test "${GH_USER}/tap/keyclean"

git add Formula/keyclean.rb
git commit -m "keyclean 0.1.1"
git push
```

Users can then run:

```sh
brew update
brew upgrade keyclean
```

## 12. Optional: bottles later

The initial Formula builds from source, so you do not need bottles to publish it.

`brew tap-new` creates Homebrew-oriented workflow files that can be used later if
you decide to build and publish bottles. Do that only after the source-based release
flow is stable.
