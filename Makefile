SHELL := /bin/sh

FLUTTER ?= flutter
DART ?= dart
FORMAT_TARGETS := lib test packages

.PHONY: help get analyze format format-check test flutter-test dart-test \
	network-test character-test clean clean-cache run-dev run-stg run-prd run-prod

help:
	@echo "Targets: get analyze format format-check test dart-test clean clean-cache"
	@echo "Run: run-dev run-stg run-prd (alias: run-prod)"

get:
	$(FLUTTER) pub get
	cd packages/network && $(DART) pub get
	cd packages/character && $(DART) pub get

analyze:
	$(FLUTTER) analyze

format:
	$(DART) format $(FORMAT_TARGETS)

format-check:
	$(DART) format --output=none --set-exit-if-changed $(FORMAT_TARGETS)

test: flutter-test network-test character-test

flutter-test:
	$(FLUTTER) test

network-test:
	cd packages/network && $(DART) test

character-test:
	cd packages/character && $(DART) test

dart-test: network-test character-test

clean clean-cache:
	$(FLUTTER) clean

run-dev:
	$(FLUTTER) run --flavor dev -t lib/main_dev.dart --dart-define=APP_ENV=dev

run-stg:
	$(FLUTTER) run --flavor stg -t lib/main_stg.dart --dart-define=APP_ENV=stg

run-prd:
	$(FLUTTER) run --flavor prd -t lib/main_prd.dart --dart-define=APP_ENV=prd

run-prod: run-prd
