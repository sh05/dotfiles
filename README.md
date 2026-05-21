# dotfiles

[![BuildStatus](https://github.com/sh05/dotfiles/workflows/CI/badge.svg)](https://github.com/sh05/dotfiles/actions?query=workflow%3ACI)

macOS development environment managed with Nix Flakes + nix-darwin + home-manager.

[日本語版はこちら](README.ja.md)

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

### 3. Configure Git (Required)

Create `~/.gitconfig.local` with your Git credentials:

```bash
cat > ~/.gitconfig.local << 'EOF'
[user]
    name = your-name
    email = your-email@example.com
EOF
```

### 4. Daily Usage

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
