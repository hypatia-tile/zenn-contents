---
name: draft
description: Support the owner's hand-written Zenn drafts in this repository — start a new topic as an empty draft, take stock of the drafts in progress and their open TODO/Q comments, commit the owner's edits one topic at a time, and on request review a draft by asking questions. Never writes the prose. Use when the owner wants to start, check on, commit or talk through an article or book chapter; the owner may phrase this in Japanese.
---

# Growing drafts

The owner writes every sentence in this repository by hand. Putting things in
their own words is how they make sense of a large amount of input, AI output
included — so prose written for them defeats the purpose. This skill handles
everything around the writing and none of the writing.

## Hard limits

- **Never write, complete, rewrite or "polish" body text**, not even a
  sentence. Suggestions are given in the conversation, as questions or
  pointers; the owner decides whether and how they enter the draft.
- **Never bring material in** from Zenn scraps, `hypatia-tile/scrap` or
  anywhere else. The owner moves material between those by hand.
- **Never decide to publish.** Flipping `published: true` is the owner's
  edit. When asked, run the lint gate (below) so they know whether it passes.
- **Never push.** The owner pushes. `main` is the branch Zenn deploys from.

What to write about is decided with the owner case by case; do not propose a
backlog of topics on your own.

## Conventions

- Drafts live on `main` with `published: false`. There are no draft branches.
- An article is `articles/<slug>.md`; it is published by its own frontmatter.
  A book is `books/<slug>/`; its `config.yaml` `published` covers every
  chapter, and a chapter is only part of the book once it is listed in
  `chapters`.
- Notes to self inside a draft are single-line HTML comments. Zenn does not
  render them, but the repository is public, so they are readable on GitHub.

  ```md
  <!-- TODO: something not written yet -->
  <!-- Q: an open question, not yet checked -->
  <!-- NOTE: a thought worth keeping; may stay after publishing -->
  ```

  Keep each on one line so `grep` finds it whole.
- CI lints only published files (`scripts/published-files.sh`), and fails on
  leftover `TODO`/`Q` comments in them. Drafts can be as rough as the owner
  likes.

## Start a topic

1. Ask whether it is an article or a chapter of a book (existing or new).
2. Agree on the slug with the owner. Article slugs are 12–50 characters of
   `a-z0-9_-`, and the slug is the filename — Zenn treats a renamed file as a
   different article. Check it is not taken.
3. Create the file with frontmatter only:
   - Article: `zenn new:article --slug <slug> --title "<title>" --type <tech|idea> --emoji <emoji>`
     inside the dev shell (`published` defaults to false). Ask for the title,
     type, emoji and topics rather than inventing them; leave the body empty.
   - Book chapter: create `books/<book>/<chapter>.md` with just a `title` in
     frontmatter, and add it to `chapters` in `config.yaml` only if the owner
     wants it in the book's order now.
   - New book: `zenn new:book --slug <slug>` (`published` defaults to false).
4. Commit the empty draft on its own (see Commit).

## Take stock

When asked where things stand, report every unpublished article and book
chapter (and, if asked, the published ones too). For each:

- the last commit touching it: `git log -1 --format='%cs %s' -- <file>`
- whether it has uncommitted changes (`git status --short -- <file>`)
- its headings (`grep -n '^#' <file>`) and line count, as a sense of shape
- its `TODO` / `Q` / `NOTE` comments: `grep -n '<!-- \(TODO\|Q\|NOTE\):' <file>`

Present it as a compact table plus the comment list per topic. Report what is
in the files; do not summarise or judge the content unless asked.

## Commit

The owner edits; you commit. One commit per topic, staging only that topic's
files (the draft, and its book's `config.yaml` if it changed) — never sweep
several topics into one commit, so `git log -- <file>` tells one draft's
story.

- Read the diff before writing the message, and name what grew: "Start the
  nix eval chapter of learning-nix-by-inspection", "Outline the sealed
  interfaces section of java-pattern-matching". Not "update draft".
- Commit messages are English (`AGENTS.md`), whatever the draft's language.
- End with the attribution line the session asks for.
- Leave anything that is not a draft (scripts, config) to its own commit.

## Review (only when asked)

Read the draft and respond in the conversation, as questions:

- gaps in the argument, and where a reader would get lost
- claims that look unchecked — ask how the owner knows, and what would settle
  it
- structure: what seems to want to be split, merged or reordered
- open `TODO`/`Q` comments that the current text already answers, or that
  block other parts

Quote the draft's own words to point at a spot; do not offer replacement
wording. If the owner wants a deeper interrogation, `grilling` fits.

## Before publishing (only when asked)

Run the gate on the files that will be published, and report the output:

```sh
pnpm lint:text <file...>
pnpm lint:md <file...>
pnpm lint:typos <file...>
pnpm lint:markers <file...>
```

Fixing what it finds is the owner's edit, except purely mechanical fixes they
explicitly hand over (e.g. `textlint --fix`).
