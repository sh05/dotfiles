---
name: parallel-worktree-goose
description: >-
  Coordinate parallel tasks in isolated Git worktrees and Goose sessions using Herdr,
  including session monitoring, resume, and cleanup. Use only when the user explicitly
  requests Herdr; Herdr operations require HERDR_ENV=1.
---

# parallel-worktree-goose

親 Goose が調整し、各 worker は **専用 Git worktree の Herdr workspace / tab で独立した Goose interactive session** を実行する。Herdr は端末と worktree 作成、Git worktree はファイルの分離、Goose CLI は実装を担当する。これは Goose の組み込みサブエージェントではなく、Herdr が常に Goose を agent kind として制御できるという意味でもない。

### レイアウトの原則: pane 分割は使わない

- 既定は **1 タスク = 1 worktree = 1 workspace、各 tab は 1 画面**。同じ worktree に複数の会話が必要なら追加 tab を使い、画面を pane に分割しない。親の focus は維持する。
- Herdr の tab / workspace には実行単位として root pane が必要であり、`pane run` / `pane read` 等でその ID を操作することは可能。ここで避けるのは **レイアウトの分割や追加 pane の作成**であって、root pane ID を用いた起動・監視ではない。
- ユーザーが pane 分割を明示した場合だけ例外とし、位置と対象を確認する。指定が曖昧なら勝手に作らず確認する。例外でも独立した並列編集には別 worktree を使い、承認・所有確認・focus 保持を省かない。ログ表示など並列実装ではない pane 操作は、この Skill ではなく Herdr Skill に委ねる。

- 詳細な手順と復旧: [references/orchestration.md](references/orchestration.md)
- 子への自己完結した指示: [templates/worker-task.md](templates/worker-task.md)
- 親が管理する台帳の例: [templates/run-registry.json](templates/run-registry.json)。これはこの運用の記録であり、Herdr / Goose の組み込み状態や排他機構ではない。
- 正常系・安全性・復旧の評価ケース: [evals/evals.json](evals/evals.json)。

## 実測した互換性と重要な制約

- Herdr 0.9.5 の `herdr agent` の kind に Goose は含まれなかった。一方、Goose 1.56.0 の `goose session --name <name>` を専用 pane で起動すると、ユーザーの Goose plugin hooks が状態を報告し、`herdr agent get <pane-id>` で idle と検出された。**hook による状態報告・検出と Goose kind / prompt 操作の対応は別機能**である。
- 同じ環境で `herdr agent prompt <pane-id> <text>` は `agent_not_ready`（active named agent ではない）を返した。名前変更後も解決しなかった。従って `agent get` が idle でも prompt が送れるとは限らない。検出結果だけで prompt 対応を判断しない。
- hook が無い・無効・Herdr server が古い・状態報告や検出が利用できない場合は、構成を推測・変更せず停止して説明し、相談する。Goose / Herdr の設定、認証、server を無許可で変更・再起動しない。
- `Stop` hook が報告する idle は Goose turn が止まった状態であり、Goose process の終了やタスクの合格を意味しない。Goose hooks は blocked を常に報告するとは限らないため、状態表示だけでなく pane の画面も読む。

## 1. Herdr を操作する前に確認する

Herdr の状態取得・操作は `HERDR_ENV=1` のときだけ行う。満たさなければ Herdr の状態を調べず停止し、「Herdr 内で親 Goose を起動してから再依頼してください」と説明する。設計相談や Skill の編集だけなら、Herdr を操作せず続けてよい。

```bash
test "${HERDR_ENV:-}" = 1
```

条件を確認した後、インストール版の `herdr --help`、`herdr status`、各 command group の help、`goose session --help` で実際の構文・version・機能を確かめる。**その環境の help が構文の根拠**。`herdr` 単体は TUI を起動するので使わず、`agent start` や `agent prompt` の対応を推測しない。古い Herdr を更新したり server を再起動したりして解決しようとしない。

ユーザー環境で確認された Goose hooks は `~/.agents/plugins/sh05-goose` にあり、SessionStart → idle、UserPromptSubmit → working、Stop → idle、SessionEnd → release を報告する。hook の報告には session ID と resume command が含まれる場合がある。`sh05.goose` Herdr plugin の action / link 登録は別経路であり、hook が動くことの前提ではない。公開 dotfiles の pinned source から plugin が配置される環境でも、Goose / Herdr の runtime config、認証、session state はユーザー所有として扱い、作業中に書き換えない。

## 2. 分割と親の計画

起動前に依存関係、同じファイルへの変更、受け入れ条件、各 repo の Git state を調べる。同じ worktree を複数 worker に割り当てず、競合・依存がある作業は直列化するか担当を一本化する。独立性を確認したうえで同時実行数を決め、資源や quota が不明なら 2 worker から始める。

親だけが更新する台帳に、repo と固定 base SHA、タスクの許可範囲、task file、branch、返却された worktree / workspace / tab / pane ID、session name と確認できた session ID、実際に確認した process、状態、検証結果を記録する。台帳は coordinator 独自の記録であり、Herdr / Goose の自動 lock や強制的な排他保証ではない。起動の直前にも台帳と実物を照合する。

子には task file で担当 worktree、変更可能な範囲、受け入れ条件、テスト方法を明示する。子による孫への委任、他の worktree / checkout の編集、設定変更、無許可の commit / push / PR / merge を禁止する。Issue 題名はそのまま branch 名、path、shell command にしない。

## 3. 許可された worktree と workspace / tab を準備する

1. repo に `cd` し、`AGENTS.md` 等の指示、`git status --short --branch`、`git worktree list --porcelain` を確認する。既存の変更（ignored file を含む）を保全し、stash / reset / checkout / clean しない。
2. branch と task ID を安全で一意な値にし、`git check-ref-format --branch "$branch"` と固定 base SHA を確認する。既存 branch / worktree / pane / process があれば所有者・path・状態を照合し、上書き・二重起動しない。親の未コミット変更は新しい worktree に自動で引き継がれないため、タスクがその変更に依存する場合は方針を確認する。
3. task file は全 checkout、worktree と Git metadata の外に、親だけが管理する private directory（例: mode 700）を作り、必要に応じ file も mode 600 で保存する。Issue 本文や指示本文は shell command に連結せず、ファイル内容として書き込む。
4. 新しい配置がユーザーに許可され、インストール版 help が対応を示す場合、以下の `herdr worktree create` は linked worktree と専用 Herdr workspace / tab / root pane を同時に作る。原則この root pane のみを使い、画面を分割しない。repo は必ず絶対 path で渡し、現在の shell cwd に依存しない。別の topology が明示されている場合はそれに合わせ、二重に作成しない。既存 worktree の branch / path / 所有者 / dirty 状態を照合し、安全でユーザーが再利用を許可した場合は `herdr worktree open` で開ける。既存 branch や未コミット変更を上書きせず、稼働中の作業先を二重割当しない。

```bash
herdr worktree create \
  --cwd "/absolute/path/to/repo" \
  --branch "agent/task-a-unique" \
  --base "FULL_FIXED_BASE_SHA" \
  --label "task-a" \
  --no-focus
```

Herdr 0.9.5 では返却 JSON の `.result.worktree.path`、`.result.workspace.workspace_id`、`.result.tab.tab_id`、`.result.root_pane.pane_id` から実際の値を読み取り台帳に保存できる。別 version では応答を確認する。返却 path で `pwd` / Git root、branch、HEAD、dirty / untracked / ignored files を確認し、pane の cwd・foreground process・画面も確かめる。予測した ID や path を使わない。Herdr がこの topology を提供しない場合は構文を推測せず停止して相談する。

同じ worktree 内に複数の会話をユーザーが明示した場合だけ、その workspace に cwd を指定した追加 tab を作れる。各 tab の root pane ID を使い、既存の画面を分割・上書きしない。ただし **独立した並列編集** は必ず別々の worktree とする。

## 4. Goose session を起動し task file を渡す

各専用 root pane が対応する worktree を cwd とする空き pane であることを確かめてから、`goose session --help` が示す構文で一意な session name を付けた Goose interactive session を起動する（実測環境では `goose session --name <name>`）。起動後、pane の cwd、前面の Goose process / session、画面、hook による状態を照合する。trust・認証・承認画面に遭遇したら無条件に承認せず、`--trust-repository` も自動指定しない。

指示は全 worker 分を private task file に用意してから、各 session へ一行の短い prompt で path を伝える。task 本文や Issue 題名を shell に埋め込まない。`agent prompt` はインストール版の help が対応を示すだけでなく、その pane が実際に prompt を受け付けることを確認できた場合だけ使う。**hook 由来の `agent get` が idle というだけでは十分でない。** task file を読む tool や認証の準備を確認し、子が読めない場合は作業を始めさせず停止して相談する。Extension や承認設定を無断変更しない。

対応が確認できない場合の raw pane fallback は、所有している専用 pane の foreground が期待した Goose session であること、cwd / session が一致すること、画面が通常の Goose 入力待ちであることを確認してから使う。Herdr 0.9.5 で実際に使ったのは `herdr pane run <pane-id> <single-line-prompt>` に task file の path を読ませる一行だけを渡す方法である。`pane run` はテキストと Enter を送るため、受信先が shell なら実行される。Goose の入力欄だと確認できなければ送らない。安全な private path を変数に入れ、引用した変数展開で prompt を作って一引数として渡す (`prompt="Read and follow the task instructions in ${task_file}."; herdr pane run "$pane_id" "$prompt"`)。`eval` や Issue 題名・task 本文の shell 展開は使わない。権限・認証・承認画面へ入力してはならない。

全 worker への prompt 送信を先に済ませてから状態を確認する。送信成功だけでは作業開始の証拠にならない。hook の working や pane の表示を照合し、動かない場合は送信済みの可能性も考えて調査する。timeout / stalled / error が出た場合も確認せず再送しない。

## 5. 監視・復旧・完了確認

`herdr agent get` / `agent read` と `herdr pane get` / `pane read` は、インストール版 help で確認した形式を使う。prompt 操作を利用できる場合でも、まず全員に送信してから待つ。Goose session history は、実際の session と履歴がその環境で確認できた場合だけ参照する。存在を確認していないログ形式や status file を前提にしない。

状態は慎重に読む: working は作業中の観測、blocked は介入待ち、unknown は判定不能、idle は turn が止まった観測に過ぎない。idle は process 終了でも task 完了でもない。hooks が blocked を報告しない場合があるので pane 画面を必ず照合し、承認・質問待ちではユーザーに確認する。idle / done 表示や子の完了報告だけで verified にしない。

親の再開時は台帳と実物を照合し、PID と command、子 process、Goose session ID / resume command、pane の所有者と foreground process、cwd、worktree path / branch / HEAD / dirty state を突き合わせる。live worker を重複起動せず、他人の pane を使わない。process / session / pane の所有が不明なら停止して相談する。dirty / untracked / ignored file を保全し、reset / clean や強制 cleanup をしない。

親は worker ごとに branch と差分、変更範囲、実際に行われたテストとその結果を独立にレビューする。受け入れ条件を満たしたものだけ親の台帳で verified とする。統合が依頼された場合は worker の作業終了後に取り込み、統合後のテストも再実行する。commit / push / PR / merge / cleanup は実装依頼だけでは許可されたことにならない。

ユーザーが完了・cleanup を明示した場合、自分が作成した対象だけを片付ける。PR / branch の統合または破棄の許可、停止した process、未コミット・未追跡・必要な ignored file、変更や commit の保全先を確認する。何か残っていれば保全して相談し、強制削除しない。`herdr worktree remove --workspace <確認済みID>` が利用可能なら worktree と関連 workspace を同時に削除し、実際に消えたことを確認する。branch / session / log の削除は別途許可が必要。詳細は [cleanup](references/orchestration.md#6-差分レビュー外部操作cleanup)。

## 完了チェック

- [ ] ユーザーが明示した場合を除き、画面を pane 分割していない
- [ ] 各タスクの担当・固定 base・branch・worktree path と Herdr ID が親の台帳および実物と一致
- [ ] 同じ worktree の二重割当がなく、全 worker が完了または blocked / unknown の理由を明示
- [ ] 親が差分・dirty state・受け入れ条件・実テスト結果を確認し、verified を判断
- [ ] 許可されていない commit / push / PR / merge / cleanup を実行していない
- [ ] 保留中の pane / workspace / worktree と未解決事項を報告

## 検証元

- Goose の session 名・ID・再開: [CLI Commands](https://goose-docs.ai/docs/guides/goose-cli-commands)、[Session Management](https://goose-docs.ai/docs/guides/sessions/session-management)
- Goose の hook event・plugin 発見: [Hooks](https://goose-docs.ai/docs/guides/context-engineering/hooks)、[Plugins](https://goose-docs.ai/docs/guides/context-engineering/plugins)
- Herdr の構文: 実行時の Herdr Skill とインストール版 help。Goose 1.56.0 / Herdr 0.9.5 の実測結果を別 version に無条件で一般化しない。
