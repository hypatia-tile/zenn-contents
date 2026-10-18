---
title: "Herdr"
---

`herdr`を立ち上げて、必要なら`--session`などを指定する。その中で複数のエージェントを起動できるし、画面分割もできる。
という基本的な使い方しかできていない。余り`herdr`を使いこなせている感じがしないので、調査してみる。

まだ使いこなすと何が出来るかのビジョンを持っていないので、featureを見ていく。

## herdrとは

https://herdr.dev/

> Run them anywhere. Leave them running.

> Herdr is where your coding agents live. However many you run, across however
> many projects, each in its own terminal. Walk away and they keep working.
> Come back from any machine and they're where you left them.

`herdr`は、複数のプロジェクトやコーディングエージェントをターミナル上で管理することのできるツール。
ターミナルを離れても各セッションの状態は保持され、戻ってきたときに同じ状態から作業を再開できる。
tmuxなどのターミナルマルチプレクサと比べて、エージェントネイティブに作られていて、
立ち上げているエージェントの一覧や作業の進捗などを表示してくれる。

## features

## 用語の整理

https://herdr.dev/docs/concepts/

基本的な用語の意味を曖昧にしか理解していないのでその整理を行う。

tmuxやzellijなどのターミナルマルチプレクサや、最新のレイアウト管理ツール（herdr など）で使われる主要な用語の関係性を整理する。
herdr のような最新のマルチプレクサ・ワークスペース管理ツールにおける概念は、基本的に階層構造で整理すると分かりやすくなる。

:::details 階層構造の概要

```
[ Server / Daemon ]
  └── Workspace
        └── Session
              └── Window / Tab
                    └── Pane <-- 実際のシェル/プロセスが走る場所
```

:::

---

:::details 各用語の定義と役割
1. Pane（ペイン）
 * 意味: 画面分割された「1つひとつの領域（窓）」。
 * 役割: 実際の端末（PTY）が開いており、bash や zsh、vim などのコマンドが個別に動作する最小単位。
 * 例: 画面を左右に割った場合、左側が Pane 1、右側が Pane 2 となる。
2. Window / Tab（ウィンドウ / タブ）
 * 意味: ペインの集合体（1つの画面に収まるレイアウト）。
 * 役割: 複数ペインをまとめて1枚の「タブ」として管理する。ブラウザのタブと同じ概念。
 * 例: 「開発用タブ（エディタ + ログペイン）」と「サーバー操作用タブ（SSHペイン × 3）」を切り替えて使う。
3. Session（セッション）
 * 意味: 関連するウィンドウ（タブ）群をまとめた「作業領域」。
 * 役割: 状態（アタッチ／デタッチ）を保持する独立した単位。端末を閉じたりSSHを切断したりしても、セッション自体はバックグラウンドで生き続ける。
 * 例: 「プロジェクトA用セッション」と「プロジェクトB用セッション」を分け、切り替えて作業する。
4. Workspace（ワークスペース）
 * 意味: 複数のセッションやディレクトリコンテキストを統合・管理する上位概念。
 * 役割: herdr などのモダンなツールでは、特定のプロジェクトやディレクトリ群（Gitリポジトリなど）に関連するセッションや環境変数を一括管理する単位として用いられる。
 * 例: 「フロントエンド開発環境（関連する3つのリポジトリと各セッション）」全体を1つのワークスペースとして定義・復元する。

:::

---

:::details 用語の比較・関係一覧

| 用語 | 単位 | 役割・イメージ | 主な操作 |
|---|---|---|---|
| Pane | 最小単位 | 画面分割された1つの枠。シェルが動く場所。 | 分割 (Split)、移動、リサイズ |
| Window / Tab | 画面単位 | 画面全体のレイアウト。ペインの集まり。 | タブ作成、切り替え |
| Session | 作業単位 | バックグラウンド保持可能な単位。ウィンドウの集まり。 | アタッチ、デタッチ、保存 |
| Workspace | プロジェクト単位 | 複数セッションや環境設定（設定ファイル/構成）を統括。 | ワークスペース切り替え、一括起動 |
herdr におけるポイント
herdr のようなツールでは、従来の tmux などに比べて「設定の宣言的な定義（レイアウト設定ファイル）」と「ワークスペース（プロジェクト）単位の迅速な切り替え」が強調されます。
 * Pane / Window: 見た目のレイアウトを構成する要素。
 * Session / Workspace: プロジェクトの文脈（Context）を構成・切り替える要素。

:::


## 調査

現在立ち上がっているセッションの一覧を表示する。

```sh
$ herdr session list
name                 status   directory                                        socket
default              stopped  <user-home>/.
work                 running  <user-home>/.config/herdr/sessions/work <user-home>/.config/herdr/sessions/work/herdr.sock
```

sessionの通信は`herdr/herdr.sock`や`herdr/sessions/<session-name>/herdr.sock`を通じて行っているのだろう。

そもそもセッションとは何なのだろうか?
あと`herdr/`や`herdr/sessions/<session-name>`の中身がどうなっているのか気になるので見てみる。

```sh
$ ls -lahF ~/.config/herdr/
total 384K
drwxr-xr-x  9 <user-name> staff  288 Oct  1 08:18 ./
drwxr-xr-x 33 <user-name> staff 1.1K Oct  4 00:50 ../
-rw-r--r--  1 <user-name> staff    0 Aug 14 20:14 .plugins.lock
-r--r--r--  1 <user-name> staff 1.4K Sep 18 11:33 config.toml
-rw-r--r--  1 <user-name> staff  12K Sep 18 11:31 herdr-client.log
-rw-r--r--  1 <user-name> staff 357K Sep 18 11:31 herdr-server.log
-rw-r--r--  1 <user-name> staff  734 Oct  1 08:18 release-notes.json
-rw-r--r--  1 <user-name> staff  786 Sep 18 11:31 session.json
drwxr-xr-x  3 <user-name> staff   96 Sep 22 17:33 sessions/
$ ls -lahF ~/.config/herdr/sessions/work/
total 2.1M
drwxr-xr-x 7 <user-name> staff  224 Oct  5 08:24 ./
drwxr-xr-x 3 <user-name> staff   96 Sep 22 17:33 ../
-rw-r--r-- 1 <user-name> staff 1.8K Oct  1 08:18 herdr-client.log
srw------- 1 <user-name> staff    0 Oct  1 08:18 herdr-client.sock=
-rw-r--r-- 1 <user-name> staff 1.4M Oct  5 08:24 herdr-server.log
srw------- 1 <user-name> staff    0 Oct  1 08:18 herdr.sock=
-rw-r--r-- 1 <user-name> staff 3.6K Oct  5 08:24 session.json
```

