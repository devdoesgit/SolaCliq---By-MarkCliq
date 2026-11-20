#!/usr/bin/env bash
# Builds a release on this machine: the API binary (for any Linux with
# glibc 2.30 or newer, via cargo-zigbuild) and the admin website, packed as
# deploy/out/solacliq-<commit>.tar.gz. Nothing is sent anywhere.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Uncommitted changes: commit first, so the release matches a commit." >&2
  exit 1
fi
name="solacliq-$(git rev-parse --short HEAD)"
stage="deploy/out/$name"
rm -rf "$stage" && mkdir -p "$stage"

(cd backend && cargo zigbuild --release --target x86_64-unknown-linux-gnu.2.31)
cp backend/target/x86_64-unknown-linux-gnu/release/backend "$stage/backend"

(cd admin && npm ci && npm run build)
cp -r admin/dist "$stage/admin"

tar -C deploy/out -czf "deploy/out/$name.tar.gz" "$name"
rm -rf "$stage"
echo "Built deploy/out/$name.tar.gz"
