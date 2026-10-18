---
name: zenn-polish
description: Polish a specified Zenn-related Markdown file in this repository, or add an entry to english_words.md. Use only when the user explicitly invokes this skill for delegated editing; use zenn-ideate when the user wants to develop their own ideas.
disable-model-invocation: true
---

# Zenn Polish

Edit the specified file directly when the target and intent are clear. Ask a
question before editing only when either is ambiguous. Work only on files
already inside this repository; importing material from Scrap or another
repository is out of scope.

Check and improve, as applicable:

- typos, missing words, particles, and accidental repetition;
- inconsistent spelling, punctuation, spacing, and use of Latin characters;
- Markdown and Zenn-specific syntax;
- heading structure, code fences, and link presentation;
- readability where it can be improved without changing the author's point.

Preserve the author's claims and voice. Do not add arguments, substantially
restructure the article, or rewrite its style wholesale. Report such
opportunities as suggestions instead.

For `english_words.md`, follow the existing `:::details` and table format.
Create an entry from the word and any supplied context, covering only useful
parts of speech, meanings, usage notes, etymology, or examples. Research
uncertain meanings, usage, etymology, and technical terms with reputable
dictionaries or official documentation. Do not fill gaps by guessing.

After editing, verify the diff and report what changed plus any point that
still needs the user's judgment.
