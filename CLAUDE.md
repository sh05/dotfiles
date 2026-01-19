# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

macOS開発環境用のdotfilesリポジトリ。25種類以上のツール設定を一元管理し、ワンコマンドでセットアップ可能。

## セットアップコマンド

```bash
# 新規インストール（リモートから）
curl -sL https://raw.githubusercontent.com/sh05/dotfiles/master/etc/install | bash

# ローカルでの操作
make deploy    # ホームディレクトリへシンボリックリンク作成
make init      # 環境設定実行（etc/setup/配下のスクリプト）
make update    # リポジトリ更新とサブモジュール同期
make install   # update + deploy + init を順次実行
make clean     # ドットファイルとリポジトリ削除
make list      # リポジトリ内のドットファイル一覧表示
```

## アーキテクチャ

### ディレクトリ構成

- **ルートレベル**: Zsh設定（`.zshrc`, `.zshenv`, `.zprofile`）、Tmux設定（`.tmux.conf`）
- **`.config/`**: XDG標準に準拠した各ツールの設定ファイル群
- **`etc/`**: セットアップスクリプト
  - `etc/install` - メインインストールスクリプト
  - `etc/setup/brew.sh` - Homebrewインストール
  - `etc/setup/formula.sh` - 基本パッケージインストール
  - `etc/setup/rust.sh` - Rustツールチェーン

### パッケージ管理

- **afx** (`.config/afx/`): CLIツール管理の統合レイヤー
- **Aqua** (`.config/aqua/`): CLIツールのバージョン管理

### 主要ツール設定

| ツール | 設定場所 | 備考 |
|--------|---------|------|
| Neovim | `.config/nvim/` | LazyVimベース、Lua設定 |
| Tmux | `.tmux.conf` | プレフィックス: Ctrl-k、Vim風キーバインド |
| Starship | `.config/starship/` | akari-nightテーマ |
| Alacritty | `.config/alacritty/` | Moralerspace Argon NFフォント |
| Git | `.config/git/` | グローバル除外設定 |

### Zsh設定の読み込み順序

1. `.zshenv` - 環境変数（全シェル共通）
2. `.zprofile` - PATH設定、ログインシェル初期化
3. `.zshrc` - 対話的設定、afx自動インストール、Tmux自動起動

### Tmuxキーバインド

- プレフィックス: `Ctrl-k`
- ペイン移動: `h/j/k/l`（Vim風）
- 水平分割: `|`、垂直分割: `-`
- ウィンドウ移動: `Ctrl-]`/`Ctrl-[`

## 必要要件

- git
- tmux 3.2以上
- Moralerspaceフォント（Monaspace + IBM Plex Sans JP合成）
- Alacrittyまたは対応ターミナル

## ローカル設定

`~/.zshrc.local` でマシン固有の設定を追加可能（gitignore対象）。
