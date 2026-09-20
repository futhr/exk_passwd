#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
browser_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
bundle="$browser_dir/_release/core/bundle.avm"
compressed_bundle="$bundle.gz"

if [ ! -s "$bundle" ]; then
  echo "Browser core bundle is missing or empty: $bundle" >&2
  exit 1
fi

if [ ! -s "$compressed_bundle" ]; then
  echo "Compressed browser core bundle is missing or empty: $compressed_bundle" >&2
  exit 1
fi

gzip -t "$compressed_bundle"

if ! gzip -dc "$compressed_bundle" | cmp -s "$bundle" -; then
  echo "Compressed browser core does not match bundle.avm" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$bundle" "$compressed_bundle"
else
  shasum -a 256 "$bundle" "$compressed_bundle"
fi
