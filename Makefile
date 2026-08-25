PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBEXECDIR ?= $(PREFIX)/libexec
SWIFT ?= swift
CONFIGURATION ?= release
CODESIGN_IDENTITY ?= -

MODULE_CACHE := $(abspath .build/module-cache)
SWIFT_ENV := CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" \
	SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)"

BUILD_ROOT := build
LAYOUT_ROOT := $(BUILD_ROOT)/layout
LAYOUT_BIN := $(LAYOUT_ROOT)/bin
LAYOUT_LIBEXEC := $(LAYOUT_ROOT)/libexec
SWIFT_BIN := .build/$(CONFIGURATION)
MAIN_APP := $(LAYOUT_LIBEXEC)/KeyClean.app
FULL_APP := $(LAYOUT_LIBEXEC)/KeyCleanFull.app

.PHONY: all build cross-build bundle install uninstall test verify clean

all: bundle

build:
	$(SWIFT_ENV) $(SWIFT) build --disable-sandbox -c $(CONFIGURATION)

cross-build:
	$(SWIFT_ENV) $(SWIFT) build --scratch-path .build/cross-arm64 --disable-sandbox \
		-c release --triple arm64-apple-macosx13.0
	$(SWIFT_ENV) $(SWIFT) build --scratch-path .build/cross-x86_64 --disable-sandbox \
		-c release --triple x86_64-apple-macosx13.0

bundle: build
	rm -rf "$(LAYOUT_ROOT)"
	mkdir -p "$(LAYOUT_BIN)" "$(MAIN_APP)/Contents/MacOS"
	install -m 755 "$(SWIFT_BIN)/keyclean-cli" "$(LAYOUT_BIN)/keyclean"
	cp "Resources/KeyClean-Info.plist" "$(MAIN_APP)/Contents/Info.plist"
	install -m 755 "$(SWIFT_BIN)/KeyCleanSafe" "$(MAIN_APP)/Contents/MacOS/KeyClean"
	mkdir -p "$(FULL_APP)/Contents/MacOS"
	cp "Resources/KeyCleanFull-Info.plist" "$(FULL_APP)/Contents/Info.plist"
	install -m 755 "$(SWIFT_BIN)/KeyCleanFull" "$(FULL_APP)/Contents/MacOS/KeyCleanFull"
	codesign --force --sign "$(CODESIGN_IDENTITY)" --options runtime --timestamp=none "$(FULL_APP)"
	codesign --force --sign "$(CODESIGN_IDENTITY)" --options runtime --timestamp=none "$(MAIN_APP)"

install: bundle
	mkdir -p "$(BINDIR)" "$(LIBEXECDIR)"
	install -m 755 "$(LAYOUT_BIN)/keyclean" "$(BINDIR)/keyclean"
	rm -rf "$(LIBEXECDIR)/KeyClean.app" "$(LIBEXECDIR)/KeyCleanFull.app"
	/usr/bin/ditto "$(MAIN_APP)" "$(LIBEXECDIR)/KeyClean.app"
	/usr/bin/ditto "$(FULL_APP)" "$(LIBEXECDIR)/KeyCleanFull.app"

uninstall:
	rm -f "$(BINDIR)/keyclean"
	rm -rf "$(LIBEXECDIR)/KeyClean.app" "$(LIBEXECDIR)/KeyCleanFull.app"

test:
	$(SWIFT_ENV) $(SWIFT) test --disable-sandbox
	$(MAKE) bundle
	$(MAKE) verify

verify:
	"$(LAYOUT_BIN)/keyclean" --version
	"$(LAYOUT_BIN)/keyclean" --help >/dev/null
	"$(LAYOUT_BIN)/keyclean" --help | grep -q -- "--full-once"
	rm -rf "$(BUILD_ROOT)/verify-missing-app"
	mkdir -p "$(BUILD_ROOT)/verify-missing-app/bin"
	install -m 755 "$(LAYOUT_BIN)/keyclean" "$(BUILD_ROOT)/verify-missing-app/bin/keyclean"
	! "$(BUILD_ROOT)/verify-missing-app/bin/keyclean" --full 2>"$(BUILD_ROOT)/verify-missing-app/error.log"
	grep -q "KeyCleanFull.app" "$(BUILD_ROOT)/verify-missing-app/error.log"
	test "$$('$(LAYOUT_BIN)/keyclean' --version | awk '{print $$2}')" = \
		"$$('/usr/libexec/PlistBuddy' -c 'Print :CFBundleShortVersionString' '$(MAIN_APP)/Contents/Info.plist')"
	"$(MAIN_APP)/Contents/MacOS/KeyClean" --self-test
	"$(FULL_APP)/Contents/MacOS/KeyCleanFull" --self-test
	plutil -lint "$(MAIN_APP)/Contents/Info.plist" "$(FULL_APP)/Contents/Info.plist"
	codesign --verify --deep --strict "$(MAIN_APP)"
	codesign --verify --deep --strict "$(FULL_APP)"
	test -z "$$(codesign -d --entitlements :- "$(MAIN_APP)" 2>/dev/null)"
	test -z "$$(codesign -d --entitlements :- "$(FULL_APP)" 2>/dev/null)"

clean:
	$(SWIFT_ENV) $(SWIFT) package --disable-sandbox clean
	rm -rf "$(BUILD_ROOT)"
