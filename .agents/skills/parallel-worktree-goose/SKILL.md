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

- 着手前に全体計画、依存関係、受け入れ条件、各担当・許可範囲を決め、子ごとに自己完結した task file を渡す。タスク間の独立性を確認し、依存作業は順序化する。並列 PR / stacked PR では親が共通 base、依存順、PR base branch と親のレビュー・統合後検証を管理する。子の branch が他 PR に依存する場合は台帳に明記し、base の更新や rebase は許可と状態を確認して親が行う。
- ユーザーが複数の指示をまとめて出しても、その一式をそのまま一人の子へ転送しない。親が指示を成果物単位の小さく独立して検証可能な作業項目に分解し、曖昧さ・依存・共通ファイルの競合を解決してから割り当てる。各 worker には一度に一つの明確な成果物 / 範囲だけを渡し、後続の作業は別タスクとして台帳の queue に置く。依存作業は先行成果を親が確認してから次を割り当てる。分解後も大きいタスクは段階ごとに区切り、各段階に完了条件と停止点を置く。
- 並列数は独立性とレビュー可能性に合わせ、台帳の `max_workers` を上限とする。上限に達したら新しい子を起動せず queue に残す。細分化のためだけに無意味な worker を増やさず、タスクが強く結合している場合は一人に狭く担当させるか順番に割り当てる。
- 子は割り当てられた一つのタスクだけを実行し、ユーザーの他の依頼や台帳 queue に自分で着手しない。受け入れ条件を満たした時点で停止して結果を報告し、次の指示を待つ。親は task file に明記し、子の報告後に差分・テストを確認してから次の作業を再計画・割り当てる。
- 親は伝言係ではなく作業マネージャーとして、依頼の整理・優先順位づけ・分割・依存管理・割当・進捗確認・ブロッカー解消・成果レビューを担う。ユーザー指示や回答を丸ごと子へ転送せず、その担当に必要な仕様・決定事項だけを task file / 追加指示に要約する。曖昧な要件・優先順位・共有契約の判断が必要ならユーザーに確認し、独断で子に判断を委ねない。
- 長時間の一括 wait を既定にしない。`agent wait` は状態変化を待つ手段で、親が管理を止める理由ではない。既定の単回 timeout は 15 秒、最大でも 30 秒とし、長時間待機が必要な場合も短い timeout で制御を戻す。timeout のたびに state / pane / 差分を確認し、台帳更新、他 worker の進捗・レビュー、ブロッカー対応、ユーザーへの状況報告など管理作業を行ってから次の wait を選ぶ。状態確認も管理上の作業もなく timeout を連続して待つだけのループに入らず、無期限 / 180 秒級の wait はユーザーが明示的に望む場合を除き使わない。ユーザー対応が必要なら作業状態を報告して確認を求める。
- 親専用の台帳で、計画の各項目・依存・担当・状態・ブロッカー・次のアクションと、各 worker の worktree / workspace / tab / pane / session / 検証結果を更新する。各 task に対応する実際の pane owner、cwd、foreground process を記録・照合する。状態は実物を確認して記録し、推測で完了扱いにしない。
- ユーザーから進捗や計画について質問されたら、台帳と最新の観測をもとに、完了・進行中・未着手・blocked / unknown、依存、次のアクションを簡潔に回答する。状況が古ければ回答前に状態を確認する。
- 子の報告後は差分・受け入れ条件・実行テストを確認し、成果を統合する。コードの競合解消や追加実装が必要なら原則子に割り当てる。commit / push / PR / merge は別途許可された範囲だけ行う。

### レイアウト

既定は **1 独立タスク = 1 worktree = 1 workspace、各 tab は分割しない1画面**。返却された root pane ID は session 起動・監視に使う。pane 分割はユーザーが対象と配置を明示した場合だけ許可する。詳細は [references/orchestration.md](references/orchestration.md)。

## 操作上の前提

- Herdr の状態取得・操作は `HERDR_ENV=1` のときだけ行う。未設定なら何も調べず停止し、「Herdr 内で親 Goose を起動してから再依頼してください」と伝える。設計相談やこの Skill の編集は Herdr 操作なしで行ってよい。
- `HERDR_ENV=1` 確認後、`herdr status` で client/server の版と互換性を確認し、インストール版 `herdr` / `goose` の関連 help を読む。実際の help が構文と機能の根拠。client/server の版や機能に差があれば、server が対応すると確認できない操作をしない。Herdr ID は server-scoped なので、対象 server・pane・cwd・foreground process と agent identity を照合する。`herdr` 単体で TUI を起動したり、未対応の `agent start` / Goose kind / prompt 機能を推測したりしない。
- Goose hook による状態検出、`agent wait`、`agent prompt` は別機能。過去の特定環境で Goose hook の idle 表示中に `agent prompt` が `agent_not_ready` となった例がある。これは `agent wait` の可否を示さない。実行時の help / status で各機能を個別に確認し、`agent get` の idle だけで prompt 送信可能と決めつけない。prompt が使えない場合は、専用 pane が期待する Goose session・cwd・入力待ちであることを画面で確認した後だけ raw pane で private task file の path を送る。
- 待機は固定 `sleep` を繰り返すポーリングを通常運用にせず、状態変化待ちには `herdr agent wait <pane-or-agent> --timeout <milliseconds>` を使う。実際の help に従い、settled state（通常 idle / done / blocked）または必要な状態を待つ。通常の timeout は 15000 ms、上限 30000 ms とする。出力文字列を待つ用途では同様に短い期限の `herdr pane wait-output <pane-id> --match ... --timeout ...` を選ぶ。短い timeout の失敗は状態変化を観測できなかっただけで、機能非対応・子の失敗・prompt 未送信の証拠ではない。timeout 後は pane/agent の状態、画面、process、cwd、作業差分を再確認し、送信済みか不明な指示を再送しない。長時間・無期限待機はユーザーが明示的に望む場合だけとし、それでも親が管理に戻る時点とブロッカー介入の計画を持つ。
- Hook の idle / done は turn 停止の観測であり、process 終了・成功・テスト合格ではない。blocked を報告しない hook もあるため pane の画面を確認する。Hook / detection がない、または所有や状態を確認できない場合は推測で進めず停止して相談する。
- Goose / Herdr の設定、認証、承認、server を無断変更・再起動しない。承認画面を自動で通さない。

## 実施フロー

1. **計画・分割する**: repo 指示、Git state、依存・共有範囲、受け入れ条件・テストを確認する。ユーザーの複数指示を成果物・変更範囲・検証単位に分解し、曖昧な点を確認して依存順を決める。共通ファイルを複数 worker に割り当てない。独立性を確認してから台帳の上限内で並列数を決め、残りは明示的な queue とする。大きな依頼は段階ごとに分割し、各 task に完了条件・停止点を定める。親が計画・queue・担当を台帳に記録する。
2. **作業先を準備する**: 新規作成が許可された場合のみ、固定 base SHA と安全で一意な branch を使い、help で確認した `herdr worktree create` 等を使う。既存 worktree / pane は所有者・path・branch・dirty 状態・稼働状況を照合し、再利用が許可された場合だけ開く。既存変更を stash / reset / checkout / clean しない。`--no-focus` が使えれば親の focus を保つ。
3. **指示・起動する**: task file は全 checkout と Git metadata の外にある private directory に置き、ディレクトリ・ファイルは適切に private にする。task file は一つの担当作業だけを含み、完了条件で停止して報告するよう明記する。実際の task に必要な情報だけを書く。親の私有会話、他 task の記録、private backup / deleted content、credentials や無関係な機密を不用意に読まず、子へ転載・送信しない。指示を作る際も、backup は明示的に必要かつ許可されている場合以外は開かず、含まれた秘密情報を task file / prompt にコピーしない。作業範囲、禁止事項、受け入れ条件、検証方法、明確な停止条件を明示する。Issue 本文を shell / branch / path に連結しない。子には担当外 checkout の編集、子への再委任、許可のない外部操作、queue 内の別 task への着手を禁止する。専用 root pane の ID / owner・cwd・foreground process・session・入力待ちを確認してから Goose session を開始し、その task の指示だけを一度送る。agent API を使う場合は実際の agent identity と対応 help を確認する。複数 task を並列実行する場合は各担当の指示を個別に投入してから監視する。
4. **短い wait を挟んで管理する**: pane / agent の実状態と台帳を照合し、進捗、依存、ブロッカー、次の行動を更新する。状態変化待ちには固定 sleep の反復でなく `agent wait` を使うが、既定の単回 timeout は 15 秒、最大でも 30 秒とする。長時間作業中でも親が管理を止めて 180 秒級・無期限の wait をしない。timeout のたびに状態、画面、foreground process、cwd / session、worktree の差分を確認し、観測内容と次の行動を台帳に記録する。続けて待つ前に、他 worker の状態確認、レビュー、依存・queue の見直し、ブロッカー解消、必要なユーザー報告など管理作業を行う。状態確認も管理作業もせず timeout だけを繰り返すポーリングに入らない。timeout / unknown は再送・再起動の根拠にしない。wait 結果だけで完了・成功扱いせず、blocked は実画面も確認する。子の質問・承認・ブロッカーを整理してユーザーへ確認し、全体進捗の質問には最新の実測と台帳から答える。
5. **レビューしてから次を割り当てる**: 子が停止条件に達したら実状態を再確認し、報告、diff、受け入れ条件、実行テストをレビューして台帳を更新する。idle / done は turn 停止の観測であり、成功・検証済みを意味しない。task が verified となってから依存する次工程を親が改めて計画し、queue から一つずつ新しい割当として dispatch する。子の完了後に同じ worker が自動で次 task を始める前提にしない。親は伝言係でなくマネージャーとして、指示の分割・優先順位・依存調整・dispatch・進捗観測・詰まりへの介入・成果レビューを継続する。親が実装を肩代わりせず、必要な追加作業は新しい bounded task として割り当てる。
6. **検証・終了する**: 親は各 branch / diff / dirty state と受け入れ条件、実測テストを確認して台帳で verified とする。統合依頼があれば成果を統合し、統合後も検証する。commit / push / PR / merge は別途許可された範囲だけ行う。完了報告には queue に残る作業、各 worker の状態、検証、ブロッカー、残した pane / session / worktree を含める。

台帳例: [templates/run-registry.json](templates/run-registry.json)。worker 指示例: [templates/worker-task.md](templates/worker-task.md)。台帳は coordinator の記録であり、Herdr / Goose の組み込み状態や lock ではない。

## 再開・cleanup

親が再開したら台帳だけを信頼せず、server/client 互換性、pane owner / foreground process / cwd、Goose session、worktree / branch / HEAD / dirty state を照合する。継続中の別 worktree・session・worker の変更に触れず、生存中または状態不明の子を重複起動しない。pane / process / 差分の所有が不明なら停止する。

cleanup はユーザーが明示した場合のみ、自分が作成した対象に限定する。process 停止、未コミット・未追跡・必要な ignored file、commit の保全先を確認し、残りがあれば削除せず相談する。worktree / workspace の削除はローカル help で確認した worktree-aware な方法を使い、`--force` / `git clean` / reset で確認を省略しない。branch、session、task file 等の削除は別リソースとして個別に許可を確認する。
