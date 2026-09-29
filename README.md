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

## Lint

```sh
pnpm lint:text        # textlint - 日本語の文章 (ja-technical-writing preset)
markdownlint-cli2     # Markdown の構文とスタイル
typos articles books  # typo の検出
lychee articles books # リンク切れの検出
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
