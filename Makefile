# SolaCliq tasks. Run `make help` for the list.
#
# Needs: Node 22+, Flutter (Dart), Java 17+ for the client generator.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Prefer the JDK 21 installed for Flutter when it exists (the system Java may
# be too new for Gradle and the generator).
JDK21 := $(HOME)/development/jdk-21/bin
export PATH := $(if $(wildcard $(JDK21)),$(JDK21):,)$(PATH)

SPEC := api/openapi.yaml
API_CLIENT := mobile/packages/api_client
SOLA_UI := mobile/packages/sola_ui

.PHONY: help setup tokens gen gen-dart gen-ts mock lint test check

help: ## List tasks
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

setup: ## Install tools and app dependencies
	npm ci
	cd admin && npm ci
	cd $(SOLA_UI) && flutter pub get
	cd $(API_CLIENT) && dart pub get
	cd mobile && flutter pub get

tokens: ## Regenerate both apps' design tokens from design/tokens.json
	node tools/tokens.mjs
	dart format $(SOLA_UI)/lib/src/tokens

gen: gen-dart gen-ts ## Regenerate the API clients from the spec

gen-dart:
	rm -rf $(API_CLIENT)
	npx openapi-generator-cli generate -i $(SPEC) -g dart-dio -o $(API_CLIENT) \
	  -c api/generator/dart.yaml \
	  --global-property apiTests=false,modelTests=false,apiDocs=false,modelDocs=false
	rm -rf $(API_CLIENT)/.openapi-generator $(API_CLIENT)/.openapi-generator-ignore $(API_CLIENT)/test
	# json_serializable emits Dart 3.8+ syntax; the template pins 3.5.
	sed -i.bak "s/sdk: '>=3.5.0 <4.0.0'/sdk: ^3.13.0/" $(API_CLIENT)/pubspec.yaml
	rm $(API_CLIENT)/pubspec.yaml.bak
	cd $(API_CLIENT) && dart pub get && dart run build_runner build --delete-conflicting-outputs
	dart format $(API_CLIENT)

gen-ts:
	cd admin && npx openapi-typescript ../$(SPEC) -o src/api/schema.d.ts

mock: ## Serve the spec as a mock API on localhost:4010
	npx prism mock $(SPEC) --host 0.0.0.0 --port 4010

lint: ## Lint the spec and both apps
	npx spectral lint $(SPEC) --ruleset api/.spectral.yaml --fail-severity error
	cd $(SOLA_UI) && dart analyze --fatal-infos
	cd mobile && dart analyze --fatal-infos
	cd admin && npm run lint && npm run typecheck

test: ## Run both apps' tests
	cd $(SOLA_UI) && flutter test
	cd mobile && flutter test
	cd admin && npm test

check: ## Fail if generated files are out of date
	$(MAKE) tokens gen
	git diff --exit-code -- design admin/src/styles/tokens.css admin/src/api $(SOLA_UI)/lib/src/tokens $(API_CLIENT)
