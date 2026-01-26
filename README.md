# dotfiles

[![BuildStatus](https://github.com/sh05/dotfiles/workflows/CI/badge.svg)](https://github.com/sh05/dotfiles/actions?query=workflow%3ACI)

macOS development environment managed with Nix Flakes + nix-darwin + home-manager.

## Setup

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Clone and Bootstrap

```bash
git clone https://github.com/sh05/dotfiles.git ~/ghq/github.com/sh05/dotfiles
cd ~/ghq/github.com/sh05/dotfiles
make bootstrap NIXNAME=sh05MacMini
```

### 3. Daily Usage

```bash
make switch    # Apply configuration changes
make update    # Update flake inputs and apply
make rollback  # Rollback to previous generation
```

## Testing

Verify configuration without applying to the system:

```bash
nix flake check                                          # Validate flake
nix build .#darwinConfigurations.sh05MacMini.system      # Build only (no apply)
```

### Rollback

```bash
darwin-rebuild --list-generations  # List generations
make rollback                      # Rollback to previous
```

---

## テスト

システムに適用せずに設定を検証:

```bash
nix flake check                                          # flakeの検証
nix build .#darwinConfigurations.sh05MacMini.system      # ビルドのみ（適用しない）
```

### ロールバック

```bash
darwin-rebuild --list-generations  # 世代一覧
make rollback                      # 前の世代に戻す
```

## Using on Different Machines

### Required Steps

1. **Create host config file** (`hosts/YourHostName.nix`)
   ```nix
   { pkgs, username, hostname, ... }:
   {
     networking = {
       hostName = "YourHostName";
       computerName = "YourHostName";
     };
   }
   ```

2. **Add host to flake.nix**
   ```nix
   darwinConfigurations = {
     "YourHostName" = mkDarwin "YourHostName" {
       username = "yourusername";
       gitUserName = "your-github-username";
       gitUserEmail = "your-email@example.com";
     };
   };
   ```

3. **Bootstrap**
   ```bash
   make bootstrap NIXNAME=YourHostName
   ```

---

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

2. **flake.nixにホストを追加**
   ```nix
   darwinConfigurations = {
     "YourHostName" = mkDarwin "YourHostName" {
       username = "yourusername";
       gitUserName = "your-github-username";
       gitUserEmail = "your-email@example.com";
     };
   };
   ```

3. **ブートストラップ**
   ```bash
   make bootstrap NIXNAME=YourHostName
   ```

---

## Requirements

- macOS (Apple Silicon)
- Nix (Determinate Systems installer)

## Features

- **Nix Flakes**: Reproducible package management
- **nix-darwin**: macOS system configuration
- **home-manager**: User environment management
- **Homebrew**: GUI apps and fonts (via nix-darwin)

## Structure

```
├── flake.nix           # Main entry point
├── lib/mkdarwin.nix    # Darwin system helper
├── hosts/              # Machine-specific configs
├── config/             # Application configs (nvim, zsh, etc.)
└── nix/
    ├── darwin/         # macOS settings + Homebrew
    ├── home/           # Packages + programs.*
    └── modules/        # Shared options
```
