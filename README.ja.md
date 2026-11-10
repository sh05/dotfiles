# dotfiles

[![BuildStatus](https://github.com/sh05/dotfiles/workflows/CI/badge.svg)](https://github.com/sh05/dotfiles/actions?query=workflow%3ACI)

Nix Flakes + nix-darwin + home-manager で管理する macOS 開発環境。

[English](README.md)

## セットアップ

### 1. Xcode Command Line Tools のインストール

まっさらな macOS では `git` と `make` のために必要:

```bash
xcode-select --install
```

### 2. Nix のインストール

[公式インストーラ](https://nixos.org/download/#nix-install-macos)を使用:

```bash
sh <(curl -L https://nixos.org/nix/install)
```

インストール後はターミナルを開き直し、Nix を `PATH` に反映させてください。

### 3. Flakes の有効化

公式インストーラは flakes を有効化しません。per-user の Nix 設定ファイルで有効化します。`/etc/nix/nix.conf` は **編集しないでください** — bootstrap 時に nix-darwin が引き継ぐファイルで、編集すると初回 activation が中断します。

```bash
# あなたのユーザー用（nix build / nix flake check で使用）
mkdir -p ~/.config/nix
echo 'extra-experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# root 用（make bootstrap の sudo 実行で使用）
sudo mkdir -p /var/root/.config/nix
echo 'extra-experimental-features = nix-command flakes' | sudo tee -a /var/root/.config/nix/nix.conf
```

初回 `make bootstrap` 以降は nix-darwin が `/etc/nix/nix.conf` を管理し flakes がシステム全体で有効になるため、この2ファイルは冗長になります（残しても削除しても無害）。

### 4. Homebrew のインストール

nix-darwin は Homebrew パッケージを管理しますが、Homebrew 自体はインストールしません:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 5. クローンとブートストラップ

```bash
git clone https://github.com/sh05/dotfiles.git ~/ghq/github.com/sh05/dotfiles
cd ~/ghq/github.com/sh05/dotfiles
```

多くの `xdg.configFile` は out-of-store symlink で `~/.config` にリンクされるため、NeoVim などのツールが直接更新できます。ただし、すべての設定がこの方式ではありません。Goose と Herdr の runtime config はユーザー所有としてこのリポジトリからリンクせず、Herdr には自動 seed はありません。別の場所へ clone する場合は、`mkDarwin` のホストエントリで `dotfilesRoot` を指定してください。

`darwinConfigurations` の各エントリは `(マシン, ユーザー)` の組です。既定の `sh05MacMini` エントリは作者アカウント `nakamotoshougo` 向けです。

> **重要:** `make switch` は、ホストエントリの `user` に指定されたアカウントにしか home 環境（Starship・gh 拡張・パッケージ・dotfiles の symlink など）を適用しません。別マシンでは macOS アカウント名が `nakamotoshougo` 以外になることがほとんどです。その場合は **自分用のホストエントリ（正しい `user`）を必ず追加**してください。怠ると `make switch` 自体は成功しても、設定はすべて `nakamotoshougo` 宛に適用され、自分のアカウントには何も反映されません。

自分の macOS アカウント名（`whoami` で確認）が `nakamotoshougo` でない場合は、先に[別マシン・別ユーザーでの利用](#別マシン別ユーザーでの利用)へ進んでください。

#### Full Disk Access の付与

nix-darwin の activation は `com.apple.universalaccess` など TCC 保護下の設定ドメインへ書き込みます。bootstrap を実行するターミナルアプリに **Full Disk Access** を付与し（System Settings → Privacy & Security → Full Disk Access）、付与後に**ターミナルを完全に終了して再起動**してください。付与しないと activation が次のエラーで中断します:

```
defaults[...] Could not write domain com.apple.universalaccess; exiting
```

> **tmux などのターミナルマルチプレクサ内で実行していませんか？** その場合、ターミナルを再起動しても付与は効きません。マルチプレクサのサーバープロセスが古い TCC コンテキストのまま生き残り、その中のシェルはすべてそれを継承するためです。`tmux kill-server` してから新しいターミナルで再実行してください。

#### bootstrap の実行

```bash
make bootstrap NIXNAME=sh05MacMini
```

`make bootstrap` は `darwin-rebuild` を `sudo` で実行するため、macOS のパスワード入力を求められます。

#### 初回 activation の「Unexpected files in /etc」

公式インストーラで Nix を入れたマシンでは、初回 activation が中断します。nix-darwin は自分が作成していないシステムファイルを上書きしないためです:

```
error: Unexpected files in /etc, aborting activation
  /etc/nix/nix.conf
  /etc/bashrc
  /etc/zshrc
```

これは想定どおりの挙動です。表示された各ファイルを `.before-nix-darwin` を付けてリネーム（退避バックアップ。nix-darwin が新しいものを生成します）し、bootstrap を再実行してください:

```bash
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/bashrc       /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc        /etc/zshrc.before-nix-darwin
make bootstrap NIXNAME=sh05MacMini
```

flakes は手順3で per-user 設定ファイルに有効化済みのため、`/etc/nix/nix.conf` をリネームしても安全です — 再実行時も flakes は使えます。

#### 既存の shell dotfiles: 「would be clobbered」

home-manager は自分が作成していない `~/.zshrc` / `~/.zshenv` を上書きしません。以前の dotfiles 環境が残した symlink も対象で、これは `backupFileExtension` ではバックアップされません:

```
Existing file '/Users/<you>/.zshrc' would be clobbered
```

表示されたファイルを退避（symlink なら削除するだけで安全 — リンク先の実体は残ります）して bootstrap を再実行してください。マシン固有の設定は `~/.zshrc.local` に置けば、生成される zshrc が末尾で source します。

#### TLS を復号する企業ネットワーク

ネットワークが企業 CA で HTTPS を再暗号化する環境（MITM プロキシ）では、ホストモジュールで CA bundle を設定し `/etc/nix/nix.conf` に載せてください:

```nix
nix.settings.ssl-cert-file = "/path/to/corporate-ca-bundle.pem";
```

シェルで `NIX_SSL_CERT_FILE` を export するだけでは**不十分**です。substitution（`.narinfo` / NAR のダウンロード）は nix-daemon が実行し、launchd 起動の daemon はユーザーのシェル環境変数を一切見ないためです。症状は紛らわしく、`curl` や `nix eval` は成功するのに `nix build` だけが `unable to get local issuer certificate` で失敗します。初回 bootstrap（nix-darwin が `nix.conf` を管理する前）は、daemon の launchd plist に一時的に環境変数を注入し、クライアント側には `sudo env` で渡してください。

#### cask の upgrade が Swift エラーで失敗する

activation 中の `brew bundle` が `redefinition of module 'SwiftBridging'` や `this SDK is not supported by the compiler` で失敗する場合、Xcode Command Line Tools と macOS SDK の不整合です（Homebrew は cask の upgrade 時に小さな Swift ヘルパーをコンパイルします。新規インストールは影響を受けません）。再インストールして再実行してください:

```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

### 6. Git の設定（必須）

`~/.gitconfig.local` に Git の認証情報を設定:

```bash
cat > ~/.gitconfig.local << 'EOF'
[user]
    name = your-name
    email = your-email@example.com
EOF
```

### 7. 日常の使い方

```bash
make switch    # 設定変更を適用
make update    # flake inputs を更新して適用
make rollback  # 前の世代にロールバック
```

- 基本はリポジトリ配下の `config/` や `nix/` を編集して、`make switch` で反映します。
- `xdg.configFile` で管理する `~/.config/<tool>` の多くは、リポジトリへ向いた out-of-store symlink です。リンク先を編集するとリポジトリのファイルが変わります。Goose と Herdr の runtime config はリンク・自動同期しません。
- `make switch` は宣言されたリンクを張り直しますが、リポジトリ側の元ファイルの内容は上書きしません。未コミット変更は再適用後も残りますが、`git checkout` や `git reset` で失われるため、忘れずにコミットしてください。
- `make switch` は「今の `flake.lock` を使って」現在ホストの設定を再ビルドして適用します（依存バージョンは更新しません）。
- `make update` は `nix flake update` で `flake.lock` を更新したうえで適用します（依存バージョン更新を含みます）。
- `make rollback` は現在ホストの **1つ前の darwin generation** に戻します。戻るのは nix-darwin / home-manager が管理する宣言的設定で、手動で作成したユーザーデータ（アプリ内データや任意ファイルなど）は戻りません。

> 注意: `~/.zshrc` は引き続き Home Manager 管理です。`~/.zshrc` へ直接追記するインストーラは失敗することがあります。マシン固有の追記先は `~/.zshrc.local`（この設定から source 済み）を使ってください。

## テスト

システムに適用せずに設定を検証:

```bash
nix flake check                                          # flake の検証
nix build .#darwinConfigurations.sh05MacMini.system      # ビルドのみ（適用しない）
```

### ロールバック

```bash
darwin-rebuild --list-generations  # 世代一覧
make rollback                      # 前の世代に戻す
```

## ツールの追加

新しいツールをどこに宣言するかで、バージョンをどこまで固定できるかが決まります。

| 宣言場所 | 例 | バージョン固定 | ロールバック |
|----------|-----|----------------|--------------|
| `home.packages`（nixpkgs から） | `kubectl` | ✅ `flake.lock` | ✅ |
| `home.packages`（`lib/mkdarwin.nix` の derivation から） | `ccstatusline`, `goose` | ✅ URL + hash | ✅ |
| `nix/darwin` の `homebrew.casks` | `ghostty`, `block-goose` | ❌ 常に最新 | ❌ |

3つとも宣言的で、`make switch` は flake の記述に収束します。違うのは Homebrew だけが
`flake.lock` に何も記録しない点です。cask は switch のたびに更新され、`make rollback`
では戻りません。まず nixpkgs を検討し、`.app` を自前でパッケージ化するのが割に合わない
場合に Homebrew を使ってください。

判断フローの全体 — flake registry ではなく**このリポジトリの** nixpkgs でバージョンを
確認する方法を含む — は CLAUDE.md の "Choosing where a new tool goes" にあります。

### 固定したビルド済みバイナリの更新

`ccstatusline` と `goose` は nixpkgs の追従が遅すぎるため、URL と hash で固定しています。
Renovate はこれを追跡しないので、更新は手動です。

```bash
v=1.56.0
nix store prefetch-file --json \
  "https://github.com/block/goose/releases/download/v$v/goose-aarch64-apple-darwin.tar.gz" \
  | jq -r .hash
```

新しい `version` と `hash` を `lib/mkdarwin.nix` に書き、適用前に検証します。

```bash
nix build .#darwinConfigurations.sh05MacminiM2.system
make switch
```

必ずバージョン付きのタグを固定してください。upstream は `stable` タグも公開していますが、
これはリリースのたびにアセットが上書きされるため、hash を固定しても後から壊れます。
しかも原因となるコミットが残りません。

### ホストごとの AI ツール方針

Claude Code と Antigravity はホスト単位の typed opt-in です。
`dotfiles.ai.claudeCode.enable` と `dotfiles.ai.antigravity.enable` はどちらも既定値が
`false` で、公開個人ホストは明示的に両方を有効化しています。他のホストはホストモジュールで
opt-in しない限り無効です。Claude Code は CLI/status-line integration を、Antigravity は
CLI と GUI cask を追加します。

`dotfiles.goose.configMode` は既定で `"unmanaged"` で、`"unmanaged"` または `"seed"` を取ります。
`dotfiles.goose.providerHelpers` は Goose YAML の設定ではなく Nix 側の選択リストで、既定値は
`[]` です。選択された provider-specific shell wrapper だけを生成します。`"claude-code"` を
選択するには Claude Code も有効である必要があり、Nix assertion で検査します。

これらの opt-in は、別手段でインストールしたアプリ、エディタ拡張、認証情報の撤去を保証しません。
Goose CLI と `block-goose` cask、Herdr、Codex はこれらの flag と独立した共通宣言として維持されます。
plugin の登録時に稼働中の Herdr server を自動再起動することもありません。

> **Homebrew cleanup はデータを削除する可能性があります。** 共通 Darwin 設定は
> `homebrew.onActivation.cleanup = "zap"` です。Antigravity を無効にするなど cask が未宣言になると、
> cleanup が cask を削除し、そのデータも消す可能性があります。cask/data 撤去を別途承認するまでは、
> 適用ホストで cleanup を `none` にし、適用前に有効な cask と cleanup 方針を確認してください。
>
> ```nix
> { lib, ... }:
> {
>   homebrew.onActivation.cleanup = lib.mkForce "none";
> }
> ```

### goose（実例）

goose は意図的に2つに分けてインストールしています。

- **CLI** — upstream のリリースバイナリを `lib/mkdarwin.nix` で固定し、`home.packages`
  に追加。nixpkgs にも `goose-cli` はありますが現在 1.28.0 で、upstream の 1.56.0 に対し
  週1リリースのペースに追従できず数ヶ月遅れています。
- **GUI** — `nix/darwin/default.nix` の `block-goose` cask。この cask は `Goose.app` だけを
  配布するので、`goose` コマンドは PATH に入りません。

cask は自動更新され CLI は固定なので、両者はいずれズレます。2つは同じ
`~/.config/goose/config.yaml` を読み、新しい方が読み込み時にこのファイルを移行するため、
古い方が読めなくなります。ズレの検出:

```bash
make goose-check
```

Goose の mutable runtime config は `~/.config/goose/config.yaml` です（公式の
[configuration-files guide](https://goose-docs.ai/docs/guides/config-files)）。これはユーザー所有で、
このリポジトリや Nix store からはリンクしません。公開リポジトリにある `config/goose/config.yaml` は
個人用の履歴ファイルであり、seed template として使わないでください。Goose の認証情報・secret・
session などの runtime state も公開 checkout や read-only store にリンクしません。
Home Manager のシェルセッションには `GOOSE_AUTO_COMPACT_THRESHOLD=0.9` を設定し、その環境を
引き継いだ Goose はモデルの context limit の90%（または先に達した token 上限）で自動圧縮を開始します。
環境変数は runtime config より優先されますが、
runtime config 自体は変更しません。共有の値は host module から上書きできます。既存プロセスには
新しい環境が必要です。Home Manager の環境変数を引き継がない環境（独立して起動した GUI アプリや
常駐サーバーなど）は対象外です。`goose info -v` は保存された設定を表示するため、このプロセス環境による
上書きは表示されません。モデルのコンテキスト上限に達した場合の処理は別に残ります。公式の
[context-management guide](https://goose-docs.ai/docs/guides/sessions/smart-context-management)も参照してください。

Goose config の typed Nix policy:

| Option | 既定値 | 意味 |
|--------|--------|------|
| `dotfiles.goose.configMode` | `"unmanaged"` | `"unmanaged"` または `"seed"` |
| `dotfiles.goose.providerHelpers` | `[]` | 選択した provider-specific shell helper だけを生成 |
| `dotfiles.goose.seedSource` | `null` | レビュー済み・非secretの template path。`"seed"` では必須 |

`unmanaged` は runtime config を変更しません。`seed` は target に filesystem entry がない場合だけ
`seedSource` をコピーし、writable な regular file を no-clobber で作成します。既存 file、symlink、
directory は保持されます。一度だけの seed で、以降の同期・上書きはしません。dry-run では directory
も file も作成しません。`seedSource` は明示的にレビューした非secret template に限ります。path 型の source は Nix が
world-readable な store へコピーする可能性があります。

read-only ownership preflight は Goose と Herdr の runtime config の両方について、古い
Home Manager generation link や checkout（移動済みを含む）への旧 link を検出すると停止し、
Home Manager cleanup による誤削除を防ぎます。checkout 以外でも同じパス末尾の link を安全側に
拒否する場合があります。自動削除・移行はせず、所有権の移行は別途承認が必要です。
`unmanaged` でも preflight は実行しますが対象ファイルを変更しません。

検査は Homebrew / Home Manager activation の前と HM write boundary の直前に実行します。
ただし `darwin-rebuild switch` を直接使うと activation 前に system profile が更新される場合があり、
検査失敗時にシステム状態が完全に不変とは限りません。適用前に確認してください。

静的 Goose integration source は flake revision に pin されます。`sh05-goose` plugin と
`parallel-worktree-goose` skill（公式の[plugin guide](https://goose-docs.ai/docs/guides/context-engineering/plugins)、
[skills guide](https://goose-docs.ai/docs/guides/context-engineering/using-skills)を参照）を配布します。
この Skill は Herdr の worktree と Goose session による並行作業、指示送信、復旧、cleanup を扱います。
原則は workspace / tab を使い、pane は分割しません。手順と評価ケースは
[`.agents/skills/parallel-worktree-goose/`](.agents/skills/parallel-worktree-goose/) にあります。
Codex CLI 用の `parallel-worktree-codex` Skill も追加しました。Codex の native subagent、
Codex 管理 worktree、Git worktree、必要な場合の Herdr 連携を扱います。subagent が自動的に
独立 worktree を持つとは仮定しません。両 Skill は Home Manager で `~/.agents/skills/` にリンクし、
Codex は repository 内の `.agents/skills/` も検出します。手順・template・eval は
[`.agents/skills/parallel-worktree-codex/`](.agents/skills/parallel-worktree-codex/) にあります。
plugin の lifecycle hooks は Skill とは別に維持します。provider-neutral な
`ask-pane` helper は `config/zsh/60_agents.zsh` で管理します。provider-specific wrapper は
`dotfiles.goose.providerHelpers` で選択されたものだけ生成します。`"claude-code"` wrapper を使うには
`dotfiles.ai.claudeCode.enable` も有効でなければならず、assertion が矛盾を拒否します。
Herdr の `~/.config/herdr/config.toml` もユーザー所有で、Nix はリンク・seed・同期しません。
公開 `config/herdr/config.toml` は必要な場合の手動 template です。logs/state/認証情報も Git や
store の外に置きます。pin された plugin の登録時に稼働中の Herdr server は自動再起動しません。

注意すべき罠が2つあります。

- **`brew install goose` を実行しないこと。** この formula は [pressly/goose](https://github.com/pressly/goose)
  というデータベースマイグレーションツールです。`/opt/homebrew/bin` は PATH 上で nix profile
  より先に来るため、本物を黙って隠してしまい、エラーの意味が分からなくなります。
- **curl インストーラも使わないこと。** `~/.local/bin` にバイナリを置きますが、これも
  PATH で勝ちます。

`make rollback` は固定 CLI を戻しますが Homebrew cask は戻しません。cask の撤去は別途レビューした
Homebrew の変更として扱ってください。

## 別マシン・別ユーザーでの利用

`darwinConfigurations` の各エントリは `(マシン, ユーザー)` の組です。別マシンでは macOS アカウント名が `nakamotoshougo` 以外になることがほとんどなので、その場合は自分専用のエントリが必要です。

### 新しいマシン／ユーザーを追加する

1. **ホスト設定ディレクトリを作成** (`hosts/<HostName>/default.nix`)
   ```nix
   { ... }:
   {
     networking = {
       hostName = "<HostName>";
       computerName = "<HostName>";
     };

     # 任意: 私用端末にだけ入れたい Mac App Store アプリ
     # homebrew.masApps = {
     #   "LINE" = 539883307;
     #   "Kindle" = 302584613;
     # };
   }
   ```

2. **flake.nix にエントリを追加**
   ```nix
   darwinConfigurations = {
     "<HostName>" = mkDarwin "<HostName>" {
       user = "<yourusername>"; # ホスト名と同じなら省略可
       # dotfilesRoot = "/Users/<yourusername>/path/to/dotfiles"; # 任意
     };
   };
   ```

   > **`user` は必ず `whoami` の出力と一致させてください。** `user` は `system.primaryUser`・home-manager の対象（`/Users/<user>`）・Homebrew の実行ユーザーを決定します。指定を省略するとホスト名にフォールバックします。不一致だと activation 中に `brew bundle` が失敗したり、home 環境が別アカウントへ適用されたりします。

3. **ブートストラップ**
   ```bash
   make bootstrap NIXNAME=<HostName>
   ```

### マシン情報を公開したくない場合（wrapper flake）

マシンのホスト名や設定をこの公開リポジトリに置きたくない場合（会社の PC など）は、ここにエントリを追加する代わりに、別リポジトリで**プライベートな wrapper flake** を作ってください。このリポジトリは `lib.mkDarwin` をエクスポートしており、`hostModule` 引数で外部からホスト設定を注入できます:

```nix
# flake.nix（プライベートリポジトリ側）
{
  inputs.dotfiles.url = "github:sh05/dotfiles";

  outputs = { self, dotfiles }: {
    darwinConfigurations."<HostName>" = dotfiles.lib.mkDarwin "<HostName>" {
      user = "<yourusername>";
      hostModule = ./hosts/<HostName>; # networking, masApps, 非公開パッケージ等
    };
  };
}
```

wrapper リポジトリから `sudo darwin-rebuild switch --flake '.#<HostName>'` を実行します。マシンに関する情報はこのリポジトリに一切残らず、共有設定の取り込みは input の再ロック（`nix flake update dotfiles`）で行います。hostModule は通常の nix-darwin モジュールなので、`home-manager.users.<user>.home.packages` によるマシン固有パッケージの追加もできます。

### 同一マシンの別ユーザーで検証する

このリポジトリには動作確認用に `sh05MacMini-test`（`user = "test"`）エントリがあります。`test` アカウントで検証するときは、そのアカウントにログインして:

```bash
make switch NIXNAME=sh05MacMini-test
```

検証後は本来の構成へ戻します:

```bash
make switch NIXNAME=sh05MacMini
```

macOS 上の nix-darwin システム構成は常に1つなので、`make switch` するたびに最後のエントリの `primaryUser` でシステムが上書きされる点に注意してください。

## 要件

- macOS (Apple Silicon)
- Nix (公式インストーラ)

## 機能

- **Nix Flakes**: 再現可能なパッケージ管理
- **nix-darwin**: macOS システム設定
- **home-manager**: ユーザー環境管理
- **Homebrew**: GUI アプリとフォント（nix-darwin 経由）

## 構造

```
├── flake.nix           # メインエントリーポイント
├── lib/mkdarwin.nix    # Darwin システムヘルパー
├── hosts/              # マシン固有の設定
├── config/             # アプリ設定 (nvim, zsh など)
└── nix/
    ├── darwin/         # macOS 設定 + Homebrew
    ├── home/           # パッケージ + programs.*
    └── modules/        # 共有オプション
```
