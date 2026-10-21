# 書きものの置き場所

まだ公開する予定のないメモは `books/scratch-notes/` に置く。この本は `zenn preview` で読むためだけにあり、`published` は `false` のままにする。`true` にすると `scripts/published-files.sh` が失敗する。本の `published` は全チャプターに効くので、この本に置いたメモは、その場では公開できない。

公開するかどうかは、記事か別の本に移したあとで、クオリティを見て決める。

## どれに書くか

### scratch note

トピックごとに `books/scratch-notes/<topic>.md` を 1 つ書く。frontmatter は `title` だけ。

`config.yaml` の `chapters` に載せると、本の中の順番が付く。載せていないチャプターも `zenn preview` には出る。

### 記事

記事にまとめる単位として適していると判断したときに、記事にする。比較的狭く、深い内容を想定する。ファイルは `articles/<slug>.md` で、公開はそのファイルの `published` で行う。

本文を scratch note で育てているあいだ、slug だけ先に取るときは `articles/<slug>.md` を frontmatter だけにする。`java-pattern-matching` と `org-mode-fundamental` がそうなっている。

### 大きなトピック

scratch note ではまとまらなさそうな大きなトピックは、それ用の本 (`books/<slug>/`) か記事を別に作る。本の公開は `config.yaml` の `published` が全チャプターに効く。チャプターは `chapters` に載せたときに、その本の一部になる。

## 作る

dev shell の中で実行する（`nix develop`、または direnv を許可したディレクトリ）。`zenn` はその中の `node_modules/.bin` にある。

`--slug` を付ける。付けないと、14 文字のランダムな16進数が slug になる。slug は `a-z`、`0-9`、`_`、`-` の 12〜50 文字。同じ slug のファイルが既にあると失敗し、上書きはしない。`published` はどちらもデフォルトで `false` なので、公開用のフラグは付けない。

### 記事

```sh
zenn new:article --slug <slug> --title "<title>" --type tech --emoji "<emoji>"
```

`articles/<slug>.md` ができる。本文は空で、frontmatter だけが入る。

- `--type` は `tech`（技術記事）か `idea`（アイデア記事）。省略すると `tech`。
- `--emoji` は 1 文字。省略すると絵文字がランダムに入る。
- `--title` を省略すると空文字。
- `topics` を付けるフラグはない。作ったあと frontmatter の `topics` に書く。

### 本

```sh
zenn new:book --slug <slug> --title "<title>" --summary "<summary>"
```

`books/<slug>/config.yaml` と、`example1.md`、`example2.md` ができる。`chapters` にはその 2 つが入る。`price` は `0`。`--title` と `--summary` を省略すると空文字。

チャプターを足すコマンドはない。`books/<slug>/<chapter>.md` を自分で作り、`config.yaml` の `chapters` に拡張子なしのファイル名を書く。チャプターのファイル名に 12 文字の下限はない。frontmatter は `title` だけにする。

```md
---
title: "<title>"
---
```

`example1.md` と `example2.md` を使わないときは、ファイルと `chapters` の両方から外す。

### scratch note

`zenn new` では作らない。`books/scratch-notes/` は既にある。`books/scratch-notes/<topic>.md` を、上と同じ `title` だけの frontmatter で作る。ファイル名に 12 文字の下限はない。順番を付けるときは `config.yaml` の `chapters` に足す。

## 題名

公開するまでは、題名を適宜変える。ファイル名の接頭辞 (`-fundamental`、`reading-memo-` など) は決まった付け方ではない。

記事のファイル名は slug である。12〜50 文字の `a-z`、`0-9`、`_`、`-`。Zenn はファイル名を記事の識別子として扱うので、ファイル名を変えると別の記事になる。frontmatter の `title` を変えても slug は変わらない。
