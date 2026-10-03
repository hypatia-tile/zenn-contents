# zenn-contents

`https://zenn.dev/` に投稿するコンテンツを書くためのリポジトリです。

## セットアップ

執筆に必要なものはすべてこのリポジトリ内で pin されています。
グローバルにインストールするものはありません。

```sh
nix develop        # 初回に入ったときに pnpm install が自動で走る
```

direnv を使う場合は、最初に一度だけ次を実行します。

```sh
direnv allow       # 以降は cd するだけで dev shell に入る
```

## コマンド

```sh
zenn preview        # ブラウザでコンテンツをプレビュー
zenn new:article    # 記事を追加
zenn new:book       # 本を追加
zenn list:articles  # 記事の一覧
zenn list:books     # 本の一覧
```

詳しくは <https://zenn.dev/zenn/articles/zenn-cli-guide> を参照してください。

## 下書き

下書きは `published: false` のまま `main` で直接育てます。
本は `config.yaml` の `published` がそのチャプター全体に効きます。
公開は `published: true` にするコミットで行います。

本文中の自分用メモは 1 行の HTML コメントで書きます。
Zenn では表示されませんが、このリポジトリは public なので GitHub からは読めます。

```md
<!-- TODO: まだ書いていないこと -->
<!-- Q: 確かめていない疑問 -->
<!-- NOTE: 残しておきたい考え (公開後も残してよい) -->
```

## Lint

lint は公開済みのファイルだけを対象にします。
下書きは引数でファイルを渡すと個別に lint できます。

```sh
pnpm lint:text [file...]     # textlint - 日本語の文章 (ja-technical-writing preset)
pnpm lint:md [file...]       # markdownlint - Markdown の構文とスタイル
pnpm lint:typos [file...]    # typos - typo の検出
pnpm lint:markers [file...]  # TODO / Q コメントの残り
lychee articles books        # リンク切れの検出 (下書きも含む)
```

一部の指摘は `textlint --fix` で自動修正できます。

## pin の管理場所

| 対象 | pin しているファイル | 更新方法 |
| --- | --- | --- |
| zenn-cli, textlint, textlint のルール | `pnpm-lock.yaml` | `pnpm update` |
| Node.js, pnpm, markdownlint-cli2, typos, lychee | `flake.lock` | `nix flake update` |

textlint のルールパッケージ (`textlint-rule-preset-ja-technical-writing` など) は
nixpkgs になく、npm からしかインストールできません。
そのため JavaScript のツール類はすべて pnpm 側で管理しています。
