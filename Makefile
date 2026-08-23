PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
SWIFTC ?= xcrun swiftc

.PHONY: all build install uninstall test clean

all: build

build: keyclean

keyclean: keyclean.swift
	$(SWIFTC) -O keyclean.swift -o keyclean

install: keyclean
	mkdir -p "$(BINDIR)"
	install -m 755 keyclean "$(BINDIR)/keyclean"

uninstall:
	rm -f "$(BINDIR)/keyclean"

test: keyclean
	./keyclean --version
	./keyclean --help >/dev/null

clean:
	rm -f keyclean
