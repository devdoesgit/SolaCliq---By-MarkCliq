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

.PHONY: help setup tokens gen gen-dart gen-ts mock lint test check db api api-test app-e2e

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
	  --type-mappings=date=String \
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

CONTAINER := $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

db: ## Start local Postgres 17 for the backend (dev only, matches backend/.env.example)
	$(CONTAINER) start solacliq-pg 2>/dev/null || $(CONTAINER) run -d --name solacliq-pg \
	  -e POSTGRES_USER=solacliq -e POSTGRES_PASSWORD=solacliq -e POSTGRES_DB=solacliq \
	  -p 127.0.0.1:5432:5432 -v solacliq-pgdata:/var/lib/postgresql/data \
	  docker.io/library/postgres:17
	# Over TCP: on first start the image runs a socket-only setup server first.
	until $(CONTAINER) exec solacliq-pg pg_isready -q -h 127.0.0.1 -U solacliq; do sleep 1; done
	# The API's restricted login (docs/architecture.md, "Row-level security").
	$(CONTAINER) exec -i solacliq-pg psql -q -U solacliq -d solacliq -v ON_ERROR_STOP=1 < backend/dev-roles.sql

api: ## Run the Rust API on localhost:8080 (needs backend/.env)
	cd backend && cargo run

api-test: ## Run the backend's tests, clippy and format check
	cd backend && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test

app-e2e: ## Seed the local API, then run each role's flow in the app on the emulator (API and emulator running)
	cd backend && cargo run -q -- seed > /dev/null
	# --keep-app-running: no uninstall at the end, which crashes this machine's emulator.
	cd mobile && flutter drive --driver=test_driver/integration_test.dart \
		--target=integration_test/flows_test.dart --flavor development \
		--dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1 --dart-define=QUICK_FORMS=false \
		--keep-app-running
