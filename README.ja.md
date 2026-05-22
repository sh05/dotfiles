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

このリポジトリは作者のマシン（`sh05MacMini`・ユーザー `nakamotoshougo`）向けの設定です。macOS のアカウント名とホスト名の**両方**が一致しない限り、先に[別マシンでの利用](#別マシンでの利用)に従ってホストエントリを追加してください。`username` は自分の macOS アカウント名（`whoami`）と一致させる必要があります — 一致しないと、Homebrew (`/opt/homebrew`) が自分のアカウント所有のため `brew bundle` が失敗します。

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

## 別マシンでの利用

### 必要な手順

1. **ホスト設定ファイルを作成** (`hosts/YourHostName.nix`)
   ```nix
   { pkgs, username, hostname, ... }:
   {
     networking = {
       hostName = "YourHostName";
       computerName = "YourHostName";
     };
   }
   ```

2. **flake.nix にホストを追加**
   ```nix
   darwinConfigurations = {
     "YourHostName" = mkDarwin "YourHostName" {
       username = "yourusername";
     };
   };
   ```

   `username` は実際の macOS アカウント名（`whoami` で確認）と**必ず**一致させてください。`system.primaryUser`・home-manager の対象（`/Users/<username>`）・Homebrew を実行するユーザーを決定します。不一致だと activation 中に `brew bundle` が失敗します。

3. **ブートストラップ**
   ```bash
   make bootstrap NIXNAME=YourHostName
   ```

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
