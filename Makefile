SHELL := /bin/sh

FLUTTER ?= flutter
DART ?= dart
FORMAT_TARGETS := lib test packages
PRD_API_BASE_URL ?=

.PHONY: help get analyze format format-check test flutter-test dart-test \
	network-test character-test clean clean-cache run-dev run-stg run-prd \
	build-prd-local run-prod

help:
	@echo "Targets: get analyze format format-check test dart-test clean clean-cache build-prd-local"
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
	$(FLUTTER) run --flavor dev -t lib/main_dev.dart --dart-define=APP_ENV=dev --dart-define=DEV_API_BASE_URL=fixture://dev/api/ --dart-define=DEV_FIXTURE_ROOT=assets/fixtures/dev

run-stg:
	$(FLUTTER) run --flavor stg -t lib/main_stg.dart --dart-define=APP_ENV=stg --dart-define=STG_API_BASE_URL=fixture://stg/api/ --dart-define=STG_FIXTURE_ROOT=assets/fixtures/stg

run-prd:
	$(FLUTTER) run --flavor prd -t lib/main_prd.dart --dart-define=APP_ENV=prd --dart-define=PRD_API_BASE_URL=$(PRD_API_BASE_URL)

build-prd-local:
	@api_base_url=$$(awk -F= '$$1 == "API_BASE_URL" { value=$$0; sub(/^[^=]*=/, "", value); print value; exit }' .env.prd); \
	if [ -z "$$api_base_url" ]; then \
		echo "Erro: .env.prd precisa definir API_BASE_URL."; \
		exit 1; \
	fi; \
	$(FLUTTER) build apk --release --flavor prd -t lib/main_prd.dart \
		--dart-define=APP_ENV=prd \
		--dart-define=PRD_API_BASE_URL="$$api_base_url"

run-prod: run-prd
