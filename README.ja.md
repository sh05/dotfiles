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

公式インストーラは flakes を有効化しません。bootstrap 時の `sudo` 実行でも root が flakes を使えるよう、システム全体で有効化します:

```bash
echo 'extra-experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
```

初回 `make bootstrap` 以降は nix-darwin が `/etc/nix/nix.conf` を管理するため、この手動編集は初期セットアップ時のみ必要です。

### 4. Homebrew のインストール

nix-darwin は Homebrew パッケージを管理しますが、Homebrew 自体はインストールしません:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 5. クローンとブートストラップ

```bash
git clone https://github.com/sh05/dotfiles.git ~/ghq/github.com/sh05/dotfiles
cd ~/ghq/github.com/sh05/dotfiles
make bootstrap NIXNAME=sh05MacMini
```

`make bootstrap` は `darwin-rebuild` を `sudo` で実行するため、macOS のパスワード入力を求められます。

ホスト名が `sh05MacMini` 以外の場合は、先に[別マシンでの利用](#別マシンでの利用)に従ってホスト設定を作成してください。

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
