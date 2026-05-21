# dotfiles

[![BuildStatus](https://github.com/sh05/dotfiles/workflows/CI/badge.svg)](https://github.com/sh05/dotfiles/actions?query=workflow%3ACI)

macOS development environment managed with Nix Flakes + nix-darwin + home-manager.

[日本語版はこちら](README.ja.md)

## Setup

### 1. Install Xcode Command Line Tools

Required for `git` and `make` on a fresh macOS:

```bash
xcode-select --install
```

### 2. Install Nix

Use the [official installer](https://nixos.org/download/#nix-install-macos):

```bash
sh <(curl -L https://nixos.org/nix/install)
```

Open a new terminal afterwards so Nix is available on your `PATH`.

### 3. Enable Flakes

The official installer does not enable flakes. Enable them system-wide so both your user and `sudo` (used during bootstrap) can use them:

```bash
echo 'extra-experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
```

After the first `make bootstrap`, nix-darwin manages `/etc/nix/nix.conf`, so this manual edit is only needed for the initial setup.

### 4. Install Homebrew

nix-darwin manages Homebrew packages but does not install Homebrew itself:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 5. Clone and Bootstrap

```bash
git clone https://github.com/sh05/dotfiles.git ~/ghq/github.com/sh05/dotfiles
cd ~/ghq/github.com/sh05/dotfiles
make bootstrap NIXNAME=sh05MacMini
```

`make bootstrap` runs `darwin-rebuild` with `sudo`, so it will prompt for your macOS password.

If your hostname is not `sh05MacMini`, follow [Using on Different Machines](#using-on-different-machines) first to create a host config.

### 6. Configure Git (Required)

Create `~/.gitconfig.local` with your Git credentials:

```bash
cat > ~/.gitconfig.local << 'EOF'
[user]
    name = your-name
    email = your-email@example.com
EOF
```

### 7. Daily Usage

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
     };
   };
   ```

3. **Bootstrap**
   ```bash
   make bootstrap NIXNAME=YourHostName
   ```

## Requirements

- macOS (Apple Silicon)
- Nix (official installer)

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
