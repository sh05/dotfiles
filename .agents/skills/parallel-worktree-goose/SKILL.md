---
name: parallel-worktree-goose
description: >-
  Coordinate parallel tasks in isolated Git worktrees and Goose sessions using Herdr,
  including planning, worker monitoring, progress reporting, and cleanup. Use only when
  the user explicitly requests Herdr; Herdr operations require HERDR_ENV=1.
---

# parallel-worktree-goose

Herdr が明示された並行開発で使う。親 Goose は計画・worker 調整・レビューを担い、子 Goose は割り当て範囲を実装する。依存・競合のある作業は直列化する。

## 親の責務

- 依存、受け入れ条件、変更範囲、許可を決め、task file と親専用の台帳を用意する。
- 実際の pane / process / cwd / session と台帳を照合し、状態・ブロッカー・次の行動を更新する。
- 子の diff・受け入れ条件・テストを確認してから検証済みとする。commit / push / PR / merge は許可された範囲だけ行う。

## 子 session の context

開始前に task の依存・規模・検証量を見積もり、独立した成果だけを分ける。worktree はファイル、Goose session は会話 context の境界。Herdr の `idle` / `working` から context 使用量を推測せず、meter が確認できない場合は `unknown` とする。

大きな節目で短い checkpoint を取る。meter があれば約 60% で checkpoint、約 75% または client warning で広い作業を止めて handoff する（目安）。`--fork` は履歴を複製し context を空にしない。`--fork --edit` が実際の help で確認でき、履歴を要点に整理できる場合のみ使う。それ以外は task file と短い handoff で新 session を始め、同じ worktree の旧 writer が停止し変更が保存されたことを確かめてから切り替える。context の handoff は [references/orchestration.md](references/orchestration.md#context-and-handoff) を参照。

## 実施

1. `HERDR_ENV=1` を確認する。未設定なら Herdr の状態取得・操作をせず、Herdr 内から再依頼するよう伝える。
2. 実行環境の `herdr` / `goose` help と status を確認する。構文や機能を推測せず、設定・認証・承認・server を無断変更しない。
3. repo 指示・Git 状態・依存・既存 worktree / pane の所有と差分を確認する。新規作成が許可された場合だけ、一意な branch と固定 base で worktree を作る。
4. task file を全 checkout / Git metadata の外に置き、必要な情報、許可範囲、受け入れ条件、検証方法だけを渡す。Issue 本文を shell / branch / path に展開しない。
5. 状態待ちには `agent wait`、文字列待ちには `pane wait-output` を使う。timeout 後は状態を再確認し、送信・稼働が不明なら再送や重複起動をしない。idle / done は成功の証拠ではない。

既定は **1 独立 task = 1 worktree / workspace、分割しない tab**。詳細手順、復旧、cleanup は [references/orchestration.md](references/orchestration.md)。worker 指示と台帳の例は [templates/worker-task.md](templates/worker-task.md)、[templates/run-registry.json](templates/run-registry.json)。
