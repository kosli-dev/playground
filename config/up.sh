#!/usr/bin/env bash
set -Eeu

readonly PORT="${ALPHA_PORT:-80}"
readonly MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export RUBYOPT='-W2'

puma \
  --port=${PORT} \
  --config=${MY_DIR}/puma.rb
