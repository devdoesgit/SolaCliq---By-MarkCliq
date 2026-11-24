#!/usr/bin/env bash
# Builds a release on this machine: the API's container image (built with
# Docker, so the server compiles nothing) and the admin website, packed as
# deploy/out/solacliq-<commit>.tar.gz. Nothing is sent anywhere.
# SOLACLIQ_ALLOW_DIRTY=1 builds uncommitted work, for trying it locally.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -n "$(git status --porcelain)" && -z "${SOLACLIQ_ALLOW_DIRTY:-}" ]]; then
  echo "Uncommitted changes: commit first, so the release matches a commit." >&2
  exit 1
fi
name="solacliq-$(git rev-parse --short HEAD)"
stage="deploy/out/$name"
rm -rf "$stage" && mkdir -p "$stage"

image="solacliq-api:${name#solacliq-}"
docker build --load --platform linux/amd64 -t "$image" backend
docker save -o "$stage/api-image.tar" "$image"

(cd admin && npm ci && npm run build)
cp -r admin/dist "$stage/admin"

tar -C deploy/out -czf "deploy/out/$name.tar.gz" "$name"
rm -rf "$stage"
echo "Built deploy/out/$name.tar.gz"
