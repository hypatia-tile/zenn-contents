#!/usr/bin/env sh
# textlint exits non-zero when it finds no target files, which would fail CI
# while articles/ and books/ are still empty. Skip the run in that case.
set -eu

if [ -z "$(find articles books -name '*.md' -type f 2>/dev/null)" ]; then
  echo "lint:text: no markdown files yet, skipping"
  exit 0
fi

exec textlint "$@" articles books
