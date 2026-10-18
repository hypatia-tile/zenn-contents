---
name: zenn-housekeeping
description: Review and organize stale Zenn work products in this repository, archiving confirmed items and maintaining navigation. Use only when the user explicitly invokes this skill for repository housekeeping.
disable-model-invocation: true
---

# Zenn Housekeeping

Inspect the repository and identify stale or completed work products. Consider
their purpose, references, git history, and current relevance; age alone does
not make a file obsolete. Treat persistent resources such as
`english_words.md` as active unless evidence or the user says otherwise.

Before moving anything, present each candidate, the evidence that it is stale,
and the proposed destination. Wait for the user to confirm the candidates.
An item the user has already explicitly identified as completed needs no
additional stale-content determination, but still preserve the archive rules.

Move confirmed items under `archive/YYYY/`, using the current year and
preserving enough of the original path to keep names unambiguous. Check for
incoming links and name collisions before moving. Update README or another
existing index when the move would otherwise make the repository misleading
or difficult to navigate.

Never delete a file or directory without an explicit deletion instruction.
This includes apparent temporary files and empty directories: report them as
candidates and wait for confirmation. Prefer archiving recoverable content.

After applying confirmed changes, inspect the diff and report moved items,
navigation updates, and anything deliberately left in place. Do not inspect or
organize content outside this repository.
