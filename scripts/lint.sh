#!/usr/bin/env sh
# Usage: lint.sh <text|md|typos|markers> [file...]
#
# Lints the given files, or every published file when none are given (see
# published-files.sh). Pass a draft explicitly to lint it before publishing.
set -eu

tool=${1:?usage: lint.sh <text|md|typos|markers> [file...]}
shift

if [ "$#" -eq 0 ]; then
  files=$(sh "$(dirname "$0")/published-files.sh")
  if [ -z "$files" ]; then
    echo "lint $tool: nothing is published yet, skipping"
    exit 0
  fi
  # Zenn slugs are [a-z0-9_-], so word splitting on newlines is safe here.
  # shellcheck disable=SC2086
  set -- $files
fi

case "$tool" in
  text)  exec textlint "$@" ;;
  md)    exec markdownlint-cli2 "$@" ;;
  typos) exec typos -- "$@" ;;
  markers)
    # TODO and Q comments are open work; NOTE may stay in a published file.
    if grep -En '<!-- (TODO|Q):' "$@"; then
      echo "lint markers: resolve the TODO/Q comments above before publishing" >&2
      exit 1
    fi
    ;;
  *) echo "lint.sh: unknown tool '$tool'" >&2; exit 2 ;;
esac
