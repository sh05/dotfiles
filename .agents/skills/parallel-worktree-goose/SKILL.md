---
name: parallel-worktree-goose
description: >-
  Coordinate parallel tasks in isolated Git worktrees and Goose sessions using Herdr,
  including planning, worker monitoring, progress reporting, and cleanup. Use only when
  the user explicitly requests Herdr; Herdr operations require HERDR_ENV=1.
---

# parallel-worktree-goose

Herdr が明示された依頼で、親 Goose は**調整役**、子 Goose は**実作業担当**となる。独立タスクごとに専用 Git worktree / Herdr workspace を用意し、子 session に割り当てる。親は計画・分担・起動・進捗管理・質問への回答・成果確認に集中し、原則として担当タスクの実装や具体的なコード変更をしない。依存や競合がある作業は直列化するか子の担当を再編する。親が実装を肩代わりせず、必要なら子に追加指示または新しい担当を割り当てる。

## 親の責務と進捗管理

- 着手前に全体計画、依存関係、受け入れ条件、各担当・許可範囲を決め、子ごとに自己完結した task file を渡す。
- 親専用の台帳で、計画の各項目・依存・担当・状態・ブロッカー・次のアクションと、各 worker の worktree / session / 検証結果を更新する。状態は実物を確認して記録し、推測で完了扱いにしない。
- ユーザーから進捗や計画について質問されたら、台帳と最新の観測をもとに、完了・進行中・未着手・blocked / unknown、依存、次のアクションを簡潔に回答する。状況が古ければ回答前に状態を確認する。
- 子の報告後は差分・受け入れ条件・実行テストを確認し、成果を統合する。コードの競合解消や追加実装が必要なら原則子に割り当てる。commit / push / PR / merge は別途許可された範囲だけ行う。

### レイアウト

既定は **1 独立タスク = 1 worktree = 1 workspace、各 tab は分割しない1画面**。返却された root pane ID は session 起動・監視に使う。pane 分割はユーザーが対象と配置を明示した場合だけ許可する。詳細は [references/orchestration.md](references/orchestration.md)。

## 操作上の前提

- Herdr の状態取得・操作は `HERDR_ENV=1` のときだけ行う。未設定なら何も調べず停止し、「Herdr 内で親 Goose を起動してから再依頼してください」と伝える。設計相談やこの Skill の編集は Herdr 操作なしで行ってよい。
- `HERDR_ENV=1` 確認後、インストール版 `herdr` / `goose` の help を確認する。実際の help が構文と機能の根拠。`herdr` 単体で TUI を起動したり、未対応の `agent start` / Goose kind / prompt 機能を推測したりしない。
- Herdr 0.9.5 / Goose 1.56.0 では Goose hooks による状態検出と Herdr named-agent 操作は別で、`agent get` の idle 表示でも `agent prompt` が `agent_not_ready` となり得た。環境ごとに確認する。使えない場合は、専用 pane が期待する Goose session・cwd・入力待ちであると確認した後だけ raw pane で task file の path を送る。送信失敗・timeout 後に、届いたか不明な指示を再送しない。
- Hook の idle / done は turn 停止の観測であり、process 終了・成功・テスト合格ではない。blocked を報告しない hook もあるため pane の画面を確認する。Hook / detection がない、または所有や状態を確認できない場合は推測で進めず停止して相談する。
- Goose / Herdr の設定、認証、承認、server を無断変更・再起動しない。承認画面を自動で通さない。

## 実施フロー

1. **計画する**: repo 指示、Git state、依存・共有範囲、受け入れ条件・テストを確認する。独立性を確認してから並列数を決める。親が計画と担当を台帳に記録する。
2. **作業先を準備する**: 新規作成が許可された場合のみ、固定 base SHA と安全で一意な branch を使い、help で確認した `herdr worktree create` 等を使う。既存 worktree / pane は所有者・path・branch・dirty 状態・稼働状況を照合し、再利用が許可された場合だけ開く。既存変更を stash / reset / checkout / clean しない。`--no-focus` が使えれば親の focus を保つ。
3. **指示・起動する**: task file は全 checkout と Git metadata の外の private directory に置く。作業範囲、禁止事項、受け入れ条件、検証方法を明示する。Issue 本文を shell / branch / path に連結しない。子には担当外 checkout の編集、子への再委任、許可のない外部操作を禁止する。専用 root pane の cwd・process・session・入力待ちを確認してから Goose を起動し、指示を一度送る。すべての子に投入してから監視する。
4. **管理・回答する**: pane / agent の実状態と台帳を照合し、進捗、依存、ブロッカー、次の行動を更新する。timeout / unknown は再送・再起動の根拠にしない。親は子の質問・ブロッカーを整理してユーザーへ確認し、全体進捗の質問にも回答できる状態を保つ。
5. **検証・終了する**: 親は各 branch / diff / dirty state と受け入れ条件、実測テストを確認して台帳で verified とする。統合依頼があれば成果を統合し、統合後も検証する。完了報告には各タスクの状態、検証、残件・ブロッカー、残した pane / session / worktree を含める。

台帳例: [templates/run-registry.json](templates/run-registry.json)。worker 指示例: [templates/worker-task.md](templates/worker-task.md)。台帳は coordinator の記録であり、Herdr / Goose の組み込み状態や lock ではない。

## 再開・cleanup

親が再開したら台帳だけを信頼せず、pane owner / foreground process / cwd、Goose session、worktree / branch / HEAD / dirty state を照合する。生存中または状態不明の子を重複起動しない。pane / process / 差分の所有が不明なら停止する。

cleanup はユーザーが明示した場合のみ、自分が作成した対象に限定する。process 停止、未コミット・未追跡・必要な ignored file、commit の保全先を確認し、残りがあれば削除せず相談する。worktree / workspace の削除はローカル help で確認した worktree-aware な方法を使い、`--force` / `git clean` / reset で確認を省略しない。branch、session、task file 等の削除は別リソースとして個別に許可を確認する。
