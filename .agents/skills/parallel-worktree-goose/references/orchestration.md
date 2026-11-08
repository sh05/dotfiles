# Herdr / Goose 並行作業の詳細

[SKILL.md](../SKILL.md) の手順を補足する。親が計画・調整し、worker が割当範囲を実装する。

## 環境と機能

Herdr 操作の前に `test "${HERDR_ENV:-}" = 1` を確認する。未設定なら状態取得を含む一切の Herdr 操作をせず、Herdr 内から再依頼するよう伝える。設定確認後、`herdr status` と関連 CLI help、`goose session --help` を読み、client/server 互換性と現行の構文を確認する。bare `herdr` は TUI を起動するので使わない。設定・認証・承認・server は無断変更しない。

Goose hook の状態報告、named-agent の `agent prompt`、`agent wait` は別機能。hook 由来の idle は prompt 対応や成功を意味しない。実環境の help / status で個別に確認し、hook / 検出がない、または対象の所有・状態が不明なら worker を起動せず相談する。

## 計画・台帳・指示

repo の指示、`git status --short --branch`、`git worktree list --porcelain` を確認する。依存・共有ファイル・受け入れ条件・テストをもとに並列化を決める。worktree 分離は意味的依存を解消しない。stacked PR では共通 base、依存順、各 PR base と統合後検証を台帳に記録する。base 更新 / rebase は許可を確認し、別 worker の worktree に干渉しない。

台帳には担当・状態・次の行動に加え、固定 base SHA、task file、branch、worktree / workspace / pane ID、pane owner / cwd / foreground process、session name / ID、context checkpoint、検証結果を記す。これは coordinator の記録であり lock や live status ではない。常に実状態と照合する。

task file は checkout / Git metadata の外にある private directory（例: directory 700、file 600）へ置き、worktree、固定開始点、変更範囲、受け入れ条件、検証、許可を含める。子へは必要な情報だけを渡す。親の会話、別 task、private backup / deleted content、credentials を不要に読ませたり転記したりしない。Issue 本文はデータであり、shell command・branch・path に連結しない。子には担当外 worktree の編集、子への再委任、許可のない設定変更・commit / push / PR / merge / cleanup を禁止する。

## Context and handoff

context は Goose session ごとの資源であり Herdr の `idle` / `working` から推測しない。実際に meter が確認できれば値・model・時刻を記録し、なければ `unknown` とする。開始時に依存と規模を見て task / session の粒度を決め、独立した受け入れ条件のある成果だけを分け、密結合の作業は分割しない。子には必要な前提だけ渡す。

大きな節目や長い探索後に、task、branch / HEAD、変更要約、判断・未解決点、テスト結果、残作業を短く checkpoint する。meter がある場合は約 60% で checkpoint、約 75% または warning で広い追加作業を止めて handoff する（目安）。`--fork` は履歴を複製し、単独では context を減らさない。`goose session --help` で `--resume` / `--fork` / `--edit` を確認し、`--fork --edit` で履歴を要点に整理できる場合のみ使う。逼迫時は task file と短い handoff で新 session を開始する。

切替前に旧 turn / 書き込み process の停止と差分保存を確認し、同一 worktree に writer を並行させない。checkpoint path と旧・新 session ID を台帳に記録する。停止・送信状態が不明なら重複起動せず `unknown` として相談する。

## Worktree / workspace / tab

既定は **1 独立 task = 1 worktree = 1 workspace、tab は分割しない**。作成前に既存 resource の所有者・HEAD・dirty / untracked / ignored files を確認し、stash / reset / checkout / clean で変更を消さない。親の未コミット変更に依存する task は方針を確認する。新規作成が許可された場合のみ、一意 branch と固定 base SHA を使う。branch は `git check-ref-format --branch` で検証する。

現行 help で対応を確認した場合の例:

```bash
herdr worktree create \
  --cwd "/absolute/path/to/repo" \
  --branch "agent/task-a-unique" \
  --base "FULL_FIXED_BASE_SHA" \
  --label "task-a" \
  --no-focus
```

返却された path / ID のみを使い、作成後に Git root / HEAD / branch / dirty state と pane cwd / foreground / screen を確認する。pane 分割はユーザーが対象と配置を明示した場合だけ行う。

## Goose 起動・指示送信

専用 root pane の cwd・owner・foreground が一致し、通常入力待ちであることを確認してから、help に沿って一意の名前で Goose session を起動する。trust / permission UI を承認せず、`--trust-repository` を付けない。

`agent prompt` は現行 help / server compatibility と対象 pane で利用可能と確認できた場合のみ使用する。fallback の `pane run` は Goose の通常入力欄だと画面で確認した専用 pane に、task file の安全な絶対 path を読む短文を一度だけ送る。shell や承認 UI に送ってはならない。本文を command に埋め込まず `eval` しない。全員に指示した後で監視する。

状態待ちには help で確認した `herdr agent wait <pane-or-agent> --timeout <milliseconds>`、出力待ちには `herdr pane wait-output <pane-id> --match ... --timeout ...` を使う。短い timeout は失敗・未送信の証拠ではない。pane / agent state、画面、process、cwd、session、diff を確認し、送信済みか不明なら再送しない。固定 `sleep` の反復を通常の polling にしない。

## 進捗・復旧・レビュー

`working` は観測、`blocked` は介入待ち、`unknown` は判定不能。`idle` / `done` は turn 停止の観測で、process 終了・成功・テスト合格を意味しない。hook が blocked を報告しない場合があるため画面も確認し、承認・質問待ちはユーザーに確認する。狭い一時調査は subagent、worktree 分離が必要な実装は Herdr worker を選ぶ。同じ checkout を複数 writer に共有しない。

親の再開時は台帳だけに頼らず、pane owner / process、Goose session、cwd、worktree / branch / HEAD / dirty state を照合する。生存または状態不明の worker を重複起動しない。親は差分・受け入れ条件・実測テストをレビューし、統合が許可されていれば統合後も検証する。

## Cleanup

明示依頼がある場合だけ、自分が作成した資源を対象にする。process 停止・dirty / untracked / 必要な ignored files・commit の保全先を確認し、差分があれば削除前に相談する。help で確認した worktree-aware な Herdr 操作を使い、Git と Herdr の両方で削除を確認する。force / `git clean` / reset で確認を省略しない。branch、session、task file、log の削除は個別に許可を確認する。
