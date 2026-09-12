# zenn-contents

Write content to post to `https://zenn.dev/`

## Setup

Everything needed for writing is pinned inside this repository. Nothing has to
be installed globally.

```sh
nix develop        # runs pnpm install automatically on first entry
```

With direnv, once only:

```sh
direnv allow       # afterwards the dev shell is entered just by cd-ing in
```

## Commands

```sh
zenn preview        # preview the content in a browser
zenn new:article    # add a new article
zenn new:book       # add a new book
zenn list:articles  # list articles
zenn list:books     # list books
```

See https://zenn.dev/zenn/articles/zenn-cli-guide for details.

## Lint

```sh
pnpm lint:text        # textlint - Japanese prose (ja-technical-writing preset)
markdownlint-cli2     # Markdown syntax and style
typos articles books  # typo detection
lychee articles books # broken link check
```

Some findings are auto-fixable with `textlint --fix`.

## Where things are pinned

| What | Pinned by | How to update |
| --- | --- | --- |
| zenn-cli, textlint, textlint rules | `pnpm-lock.yaml` | `pnpm update` |
| Node.js, pnpm, markdownlint-cli2, typos, lychee | `flake.lock` | `nix flake update` |

The textlint rule packages (`textlint-rule-preset-ja-technical-writing` and
friends) are not in nixpkgs and can only be installed from npm, so all
JavaScript tooling is kept on the pnpm side.
