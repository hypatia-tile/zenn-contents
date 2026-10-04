---
title: "Shell utility"
---

## Bash関連

Bashにて環境変数がセットされた場所を調べるにはどうする?

```sh
bash -x -c 'echo $SHELL' 2>&1 | less
```

<!-- bashコマンドのman pageはちゃんとみよう -->

```sh
bash -lx
```

みたいなデバッグオプションを使うか。

## Zsh関連

やはり基本的にはZshを使いたい気持ちがある。
