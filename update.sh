#!/usr/bin/env bash
# Helper script for CI: regenerate deps.json and yarn hash after updating source.
set -euo pipefail

echo "==> Building fetch-deps script..."
nix build .#bookshelf.fetch-deps --no-link --print-out-paths | while read -r out; do
  echo "==> Running fetch-deps to regenerate deps.json..."
  "$out" "$(pwd)/deps.json"
done

echo "==> deps.json regenerated successfully."
