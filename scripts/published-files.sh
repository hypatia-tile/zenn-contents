#!/usr/bin/env sh
# Print the markdown files that are published on Zenn, one per line.
# Drafts (`published: false`) grow on main in a rough state, so the lint gate
# only applies to what readers can see. An article is published by its own
# frontmatter; a book chapter by the `published` field of its book's
# config.yaml.
set -eu

# True when the frontmatter at the top of $1 says `published: true`.
frontmatter_published() {
  awk '
    NR == 1 && $0 != "---" { exit 1 }
    NR > 1 && $0 == "---"  { exit 1 }
    /^published:[ \t]*true([ \t]|#|$)/ { found = 1; exit 0 }
    END { exit !found }
  ' "$1"
}

for f in articles/*.md; do
  [ -f "$f" ] || continue
  if frontmatter_published "$f"; then echo "$f"; fi
done

for config in books/*/config.yaml; do
  [ -f "$config" ] || continue
  if grep -Eq '^published:[[:space:]]*true([[:space:]]|#|$)' "$config"; then
    for f in "$(dirname "$config")"/*.md; do
      [ -f "$f" ] && echo "$f"
    done
  fi
done
