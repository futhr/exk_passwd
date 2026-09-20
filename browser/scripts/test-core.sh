#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
browser_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repository_dir=$(CDPATH= cd -- "$browser_dir/.." && pwd)
image='hexpm/elixir:1.17.3-erlang-26.0.2-alpine-3.20.3'

docker run --rm \
  --volume "$repository_dir:/workspace" \
  --workdir /workspace/browser \
  --env MIX_ENV=test \
  "$image" \
  sh -eu -c '
    mix local.hex --force
    mix local.rebar --force
    mix deps.get
    mix format --check-formatted
    mix compile --warnings-as-errors
    mix test
  '
