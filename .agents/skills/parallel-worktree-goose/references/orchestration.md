# Native Herdr / Goose 並行実行の手順

この文書は [SKILL.md](../SKILL.md) の詳細手順。Herdr の状態取得・操作は `HERDR_ENV=1` のときだけ行い、実際の構文と機能はインストール版の help を根拠にする。Goose / Herdr の設定・認証・server を無許可で変更・再起動しない。

## 実測された動作と境界

この Skill に含まれる移植元の内容は [MIT License](../LICENSE) に従う。

Herdr 0.9.5 / Goose 1.56.0 の環境では、`herdr agent` の kind に Goose はなかった。一方、専用 Herdr pane 上で `goose session --name <name>` を起動すると、ユーザーの Goose plugin hooks が状態を報告し、`herdr agent get <pane-id>` は Goose を idle として検出した。これは **hook による pane 状態の報告・検出**であり、Herdr の Goose kind / agent 操作のサポートを意味しない。

同じ環境で `herdr agent prompt <pane-id> <text>` は `agent_not_ready: agent ... is not an active named agent` を返し、agent rename 後も同じだった。従って `agent get` の idle 表示だけでは `agent prompt` が使えると判断できない。このときは task file の path を伝える raw pane fallback を使った。別 version でも prompt が使えるとは限らないため、毎回 help と実際の pane/session を確かめる。

確認したユーザー Goose plugin hooks は、SessionStart → idle、UserPromptSubmit → working、Stop → idle、SessionEnd → release を報告する。hook が受け取った session ID と resume command を Herdr に伝える場合もある。report は Herdr pane 環境が揃った場合に限られ、hook 自身は失敗を Goose に伝えない設計である。`sh05.goose` Herdr plugin action / link の登録と、Goose hooks の配置・動作は別経路であり、前者がないことだけで後者が動かないとは判断しない。

公開 dotfiles は pinned source から静的 plugin を配布する一方、Goose / Herdr の runtime config、認証、session、状態はユーザー所有である。hooks が無い・無効、Herdr server が古い、state detection ができない、または pane に期待する Goose session と通常の入力待ちが確認できない場合は、設定変更や推測で直そうとせず停止して説明・相談する。

## 1. 環境と機能を確認

まず Herdr を操作せず環境変数を確認する。

```bash
test "${HERDR_ENV:-}" = 1
```

通らなければ Herdr の状態取得も操作も行わず、「Herdr 内で親 Goose を起動してから再依頼してください」と伝える。通った場合だけ、インストール版の help に従って以下を確認する。

```bash
herdr --help
herdr status
herdr workspace --help
herdr worktree --help
herdr tab --help
herdr pane --help
herdr agent --help
goose session --help
```

コマンド group の help の表示方法はその版に従う。`herdr` 単体は TUI を開くため使わない。`herdr agent` が表示する kind と `agent prompt` が本当に対象 pane を操作できるかを別々に確認する。help にない `agent start --kind goose` などの構文を作らない。Herdr が古い・必要な操作が非対応の場合、勝手に server や package を更新しない。

## 2. タスク分割・台帳・task file

作業開始前に各 repo の指示と Git state を読み、タスク間の依存、同じファイルへの変更、受け入れ条件、テスト方法を確認する。同じ worktree を複数 worker に割り当てない。依存・強い競合がある箇所は直列化するか、一つの worker にまとめる。

親だけが管理する台帳に、固定 base SHA、担当と許可範囲、branch、task file の path、Herdr worktree / workspace / tab / pane の返却 ID、session name、判明した session ID / resume command、確認した process、状態、親の検証結果を記録する。この台帳は coordinator 独自の記録で、Herdr / Goose の公式状態でも自動 lock でもない。台帳と実物を起動前に照合し、二重割当を避ける。強制的な排他保証はなく、別 coordinator との競合を完全に防ぐ仕組みとして説明しない。

指示は親が自己完結した task file に書き、repo 本体、全 worktree と Git metadata の外にある private directory（例: mode 700）に置く。必要に応じ file も mode 600 にする。安全な単純 path を選び、Issue 本文や task file の内容を shell command に連結しない。子には割り当て範囲以外の worktree / checkout の編集、さらなる委任、設定変更、許可されていない commit / push / PR / merge を禁止する。

## 3. 許可済み worktree / workspace / tab の準備

レイアウトは原則 **1 タスク = 1 worktree = 1 workspace、各 tab は分割しない 1 画面**とする。`herdr worktree create` が返す root pane は tab の実行単位であり、ID を使った Goose 起動・出力確認は必要な操作である。`herdr pane split` などで画面を分割したり追加 pane を作ったりすることは、ユーザーから pane 分割の明示指定がある場合を除き行わない。Herdr の汎用 Skill が pane 分割を既定にしていても、この並行作業では本方針を優先する。ユーザーが分割を明示し、位置・対象も確認できた場合に限り例外とし、独立実装では worktree 分離と親の focus 維持を守る。

1. repo に `cd` する。`AGENTS.md` 等の指示、`git status --short --branch`、`git worktree list --porcelain` を確認する。既存の dirty / untracked / ignored file を記録・保全し、stash / reset / checkout / clean しない。親の未コミット変更は新しい worktree には自動で入らず、その変更に依存するタスクはユーザーと扱いを確認する。
2. 一意な安全な branch 名と固定 base SHA を決め、`git check-ref-format --branch "$branch"` で名前を検証する。既存 branch / path / worktree / pane / process がある場合は owner と実物を照合し、上書きしたり二重起動したりしない。
3. 新しい topology はユーザーが許可した場合だけ作る。Herdr 0.9.5 で確認された `herdr worktree create` は linked worktree と専用 workspace / tab / root pane をまとめて作る。各 worker 用に repo の **絶対 path**、一意 branch、固定 base と label を指定し、`--no-focus` で親の focus を保つ。

```bash
herdr worktree create \
  --cwd "/absolute/path/to/repo" \
  --branch "agent/task-a-unique" \
  --base "FULL_FIXED_BASE_SHA" \
  --label "task-a" \
  --no-focus
```

既に別の topology が明示されている場合はその指定を優先し、worktree や workspace を二重に作らない。pane 分割は明示指定がある場合だけ例外とし、どの workspace / tab / 位置を対象にするか確認する。help でこの構文・機能を確認できない場合は作成を推測せず相談する。

### 既存 worktree の再利用

作成前に `git worktree list --porcelain` と `herdr worktree list --cwd <source-checkout>` で branch、path、workspace の実物を照合する。候補が存在する場合は所有者、branch、base / HEAD、dirty / untracked / ignored file、稼働中 process を確認する。ユーザーが再利用を許可し、他の作業と衝突しない場合だけ `herdr worktree open --cwd <source-checkout> --path <existing-worktree> --no-focus`（または help で確認した `--branch`）を使用する。返却 ID と path を記録し、既に開かれている workspace は重複作成しない。不明な所有者や dirty 状態は保全し、勝手に reset・remove しない。

### 同一 worktree に複数の会話を開く場合

ユーザーが明示した場合のみ、既存の workspace に `herdr tab create --workspace <workspace-id> --cwd <worktree-path> --label <label> --no-focus` で tab を追加し、返却された root pane から別 Goose session を起動できる。各 tab は分割しない 1 画面のままにする。これは会話の分離であってファイル・index の分離ではない。**同じ checkout で複数 worker を同時に編集させない。** 独立した実装タスクは別の worktree にする。

Herdr 0.9.5 では返却 JSON の `.result.worktree.path`、`.result.workspace.workspace_id`、`.result.tab.tab_id`、`.result.root_pane.pane_id` から実際の値を読み、台帳へ保存できる。別 version では実際の応答を確認する。予想で ID / path を組み立てない。返却された path に `cd` して repo root、`HEAD`、branch、dirty / untracked / ignored state を調べる。返却された **root pane** の cwd、foreground process / command と画面も Herdr の `pane get` / `pane process-info` / `pane read` など、help で確認した読み取り手段で調べ、期待する path と実際に利用中の process が一致するか確認する。JSON の field 名を help / 応答にない形で仮定しない。

## 4. Goose session の起動と指示送信

新しく作った自分所有の workspace / tab の **root pane** が空きの shell prompt で、対応 worktree を cwd としていることを確認する。pane は増やさない。インストール版 `goose session --help` を根拠に一意の session name で Goose の interactive session を起動する。確認済み環境の例では、`root_pane_id` は作成応答から得た ID、`session_name` は英数字・ハイフン・アンダースコアだけの短い安全な値とする。shell 上で実行されるので外部入力を使わない。

```bash
herdr pane run "$root_pane_id" "goose session --name $session_name"
```

Herdr 側の `pane run` の引数形式もローカル help に合わせる。起動後、pane の foreground process、cwd、Goose session、画面が通常の入力待ちであること、hooks による state detection を照合する。repository trust や他の承認画面を自動承認せず、`--trust-repository` を自動指定しない。

全 worker 分の task file と session を用意してから prompt を投入し、**全員に投入した後で**監視を始める。送る内容は task file の private absolute path を読むよう伝える短い一行の prompt に限り、指示本文や Issue 題名を shell に埋め込まない。Goose の file / shell 読み取り機能と承認設定を確認し、子が task file を読めない場合はそのまま作業を始めさせず停止・相談する。拡張機能を無断で有効化したり承認を緩めたりしない。

`herdr agent prompt` は次の条件を満たすときだけ使用する。

- インストール版 help にその形式がある。
- `agent get` の表示だけに頼らず、その pane が active named agent として prompt を受け付けることを確認できる。
- pane / session / cwd が割り当てたものと一致し、権限承認待ちではない。

Herdr 0.9.5 では hooks により idle と検出された pane に対する `agent prompt` が `agent_not_ready` を返し、rename も解決にならなかった。こうした場合は同じ内容を名前違いで繰り返さず、まず pane と session を読み、入力が届いた可能性がないことを確認する。

raw pane fallback を使う場合は、対象が自分の専用 pane で、foreground process が期待する Goose session、cwd / session が担当と一致し、画面が通常の Goose 入力待ちであることを先に確認する。そのうえで `herdr pane run <pane-id> <single-line-prompt>` に task file の安全な path を読むよう指示する一行だけを渡す。`pane run` はテキストと Enter を送る機能であり、受信先が shell なら実行される。**Goose の入力欄と確認できた場合だけ** prompt を送る。たとえば事前に安全な private path を変数に入れ、引用した変数展開で prompt を作って一引数として渡す (`prompt="Read and follow the task instructions in ${task_file}."; herdr pane run "$pane_id" "$prompt"`)。`eval` や Issue 題名・task 本文の shell 展開はしない。権限・認証・承認画面への入力はしない。pane が通常の入力待ちでない、owner が不明、または内容が届いたか不明なら送らず停止する。

送信後は hook の working や pane の出力を確認する。`pane run` の成功は入力の送信であって作業開始の証明ではない。timeout / stalled / error も未送信の証拠ではない。`agent get` / `agent read` と pane の画面を読み、実際の session と task file の指示が既に届いていないかを照合する。送信済みか不明な状態では再送しない。

## 5. 監視と再開

利用可能な形式を help で確認したうえで、`herdr agent get` / `agent read` および `herdr pane get` / `pane read` から状態と画面を読む。pane の recent output は古い prompt や表示を含むことがあるため、現在の foreground process、session、cwd と合わせて解釈する。Goose session history は、その環境で履歴の存在と対象 session ID を確認できた場合だけ使う。Herdr の pane / agent read と Goose の実在する session history の範囲を超えるログや記録形式を前提にしない。

状態表示は観測値であり完了証明ではない。

- `working`: hook / agent が作業中を報告した状態。
- `blocked`: 承認・質問など介入待ち。画面を読み、ユーザーに確認する。勝手に承認しない。
- `unknown`: 判定不能。画面・session・実際の process を確認する。
- `idle` / `done`: turn が停止または入力待ちという観測。Goose process 終了、成功、テスト合格を意味しない。

Stop hook は idle を報告するが Goose process は続いている場合がある。また hooks が blocked を必ず報告するとは限らないため、state のみで判断せず pane 画面を読む。

親が再起動・中断から復帰したら、新規 worker を起動する前に台帳と実物を照合する。確認可能な PID / process command・子 process、Goose session ID と resume command、pane ID と owner、foreground process、cwd、worktree path / branch / HEAD / dirty state を突き合わせる。PID だけで同一 process と判断しない。生きている worker を重複起動せず、他人の pane に送信しない。session を再開する場合は Goose session history とインストール版 help で同一 session・同一担当であることを確認し、hook などで実際に得られた resume command を検証して使う。session / process の所有や状態が確かめられなければ停止・相談する。

## 6. 差分レビュー、外部操作、cleanup

子の最終報告だけでなく、親が各 worktree の branch / HEAD / diff、変更範囲、dirty / untracked / ignored file、受け入れ条件、実際に実行したテストと結果を確認する。state が idle であることだけで `verified` にしない。worker 間に依存や競合が見つかったら担当を調整し、起動中 worker の branch を親が書き換えない。

統合を依頼された場合は worker の作業終了後に、合意した場所でレビュー済みの変更を取り込み、統合後のテストを再実行する。作業中の branch は書き換えない。実装の依頼だけから commit / push / PR / merge / 削除の許可を推測しない。明示された範囲だけを行い、GitHub 操作は repo の規約と関連 Skill に従う。merge と cleanup は別の許可を要する。

### ユーザーが cleanup を依頼した場合

1. 生きている workspace / tab / pane / path / branch と所有者を Herdr と Git から再確認する。自分が作成したリソースだけを対象にし、ID を推測しない。
2. PR / branch の統合、またはユーザーが明示した破棄を確認する。worker と関連 process を停止し、`git status --short` と untracked / 必要な ignored file、commit の保全先を調べる。変更が残る場合は保全してユーザーに相談し、そのまま削除しない。
3. インストール版の help で worktree-aware な削除を確認し、`herdr worktree remove --workspace <workspace-id>` で対象を削除する。`--force` / `--trust-repository` を安易に追加せず、削除結果、`herdr worktree list --cwd <source-checkout>`、`herdr workspace list` で Git と Herdr の両方が片付いたことを確認する。
4. 追加 tab が残った場合は再確認し、他人の作業を含まない、自分で作成した tab だけを明示許可の範囲で閉じる。元の checkout や別 task の pane / workspace は閉じない。
5. worktree、branch、session、task file、ログは別々のリソース。各削除の許可を確認し、`--force`、`git reset --hard`、`git clean -fd` で確認を省略しない。

## 終了時の確認

- [ ] 明示的な pane 分割の依頼がない場合、workspace / tab を使い画面を分割していない
- [ ] 担当、固定 base、branch、worktree、workspace / tab / pane ID が親台帳と実物で一致
- [ ] 同じ worktree の重複割当なし。全 worker の状態・blocked / unknown の理由を確認
- [ ] 親が差分、保全対象ファイル、受け入れ条件、実テスト結果を確認し、完了を判断
- [ ] 許可のない commit / push / PR / merge / cleanup / 設定変更をしていない
- [ ] 残した pane / session / worktree / task file と未解決事項を報告

## 検証元

- [Goose CLI Commands](https://goose-docs.ai/docs/guides/goose-cli-commands) / [Session Management](https://goose-docs.ai/docs/guides/sessions/session-management)
- [Goose Hooks](https://goose-docs.ai/docs/guides/context-engineering/hooks) / [Plugins](https://goose-docs.ai/docs/guides/context-engineering/plugins)
- Herdr はインストール版 help と Herdr Skill を参照する。実際の対応は version や user hook に依存する。
