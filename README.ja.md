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

`darwinConfigurations` の各エントリは `(マシン, ユーザー)` の組です。既定の `sh05MacMini` エントリは作者アカウント `nakamotoshougo` 向けです。

> **重要:** `make switch` は、ホストエントリの `user` に指定されたアカウントにしか home 環境（Starship・gh 拡張・パッケージ・dotfiles の symlink など）を適用しません。別マシンでは macOS アカウント名が `nakamotoshougo` 以外になることがほとんどです。その場合は **自分用のホストエントリ（正しい `user`）を必ず追加**してください。怠ると `make switch` 自体は成功しても、設定はすべて `nakamotoshougo` 宛に適用され、自分のアカウントには何も反映されません。

自分の macOS アカウント名（`whoami` で確認）が `nakamotoshougo` でない場合は、先に[別マシン・別ユーザーでの利用](#別マシン別ユーザーでの利用)へ進んでください。

#### Full Disk Access の付与

nix-darwin の activation は `com.apple.universalaccess` など TCC 保護下の設定ドメインへ書き込みます。bootstrap を実行するターミナルアプリに **Full Disk Access** を付与し（System Settings → Privacy & Security → Full Disk Access）、付与後に**ターミナルを完全に終了して再起動**してください。付与しないと activation が次のエラーで中断します:

```
defaults[...] Could not write domain com.apple.universalaccess; exiting
```

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
- `~/.config/...` を直接編集した場合は、その差分をリポジトリ側の `config/...` に反映してから `make switch` を実行してください。
- home-manager 管理下の `~/.config` ファイルは `make switch` 時に再生成されるため、リポジトリに戻していない直接編集は次回適用時に失われます。

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
     };
   };
   ```

   > **`user` は必ず `whoami` の出力と一致させてください。** `user` は `system.primaryUser`・home-manager の対象（`/Users/<user>`）・Homebrew の実行ユーザーを決定します。指定を省略するとホスト名にフォールバックします。不一致だと activation 中に `brew bundle` が失敗したり、home 環境が別アカウントへ適用されたりします。

3. **ブートストラップ**
   ```bash
   make bootstrap NIXNAME=<HostName>
   ```

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
