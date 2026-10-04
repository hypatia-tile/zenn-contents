---
title: "Org-modeの基本"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["emacs", "org-mode"]
published: false
---

## Org-modeの基本概念

<!-- NOTE: Org-modeを使い始めたので、マニュアルを参照しながら基本概念を確認していく。
たまたま見ていたのがorg-refileについてだったので、そこから読み始めているが、
順番には拘らず分からないところから埋めていきたい。
-->

<!-- NOTE: 現在のemacsの設定 -->

```elisp
(use-package org
  :ensure nil
  :defer t
  :bind
  ("C-c l" . org-store-link)
  ("C-c a" . org-agenda)
  ("C-c c" . org-capture)
  :custom
  (org-agenda-files '("~/org-notes/todo.org") "Tentative agenda file I am currently using.")
  (org-default-notes-file "~/org-notes/inbox.org" "Target of the capture templates' (file \"\") and (file+headline \"\" ...).")
  (org-capture-templates
   '(("i" "Inbox" entry (file "") "* %?\n%U\n")
     ("t" "Task" entry (file+headline "" "Tasks") "* TODO %?\n%u\n%a")
     ("j" "Journal" entry (file+olp+datetree "~/org-notes/journal.org")
      "* %<%H:%M> %^g\n%?"))
   "Capture raw notes (i) and tasks (t) into the inbox, thoughts (j) into the journal.")
  (org-startup-indented t)
  (org-log-done 'time)
  (org-startup-folded t)
  (org-hide-emphasis-markers t)
  (org-startup-with-inline-images t)
  :hook
  (org-mode . visual-line-mode))
```

### org-refile

https://orgmode.org/manual/Refile-and-Copy.html

