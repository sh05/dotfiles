# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS development environment dotfiles managed with Nix Flakes + nix-darwin + home-manager.

## Setup Commands

```bash
# Install Nix (Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Initial setup
make bootstrap NIXNAME=sh05MacMini

# Apply changes
make switch

# Update flake inputs and apply
make update

# Rollback to previous generation
make rollback
```

## Architecture

### Directory Structure

```
dotfiles/
├── flake.nix                    # Main entry point
├── flake.lock                   # Auto-generated lock file
├── Makefile                     # bootstrap, switch, update commands
├── lib/
│   └── mkdarwin.nix             # darwinSystem helper function
├── hosts/
│   └── sh05MacMini.nix          # Machine-specific settings
├── config/                      # Source config files (symlinked via xdg.configFile)
│   ├── nvim/                    # Neovim config (lazy.nvim managed)
│   ├── karabiner/               # Karabiner-Elements config
│   ├── zsh/                     # Zsh custom scripts
│   └── ghostty/                 # Ghostty terminal config
└── nix/
    ├── modules/
    │   └── shared.nix           # Shared options (Nix settings)
    ├── darwin/
    │   └── default.nix          # macOS settings + Homebrew
    └── home/
        └── default.nix          # Packages + programs.* settings
```

### Package Management

- **Nix (home.packages)**: CLI tools, languages, LSP servers
- **Homebrew (homebrew.casks)**: GUI applications, fonts
- **programs.***: Shell, Git, Tmux, Starship, etc. (declarative config)

### Key Tools Configuration

| Tool | Managed By | Notes |
|------|-----------|-------|
| Neovim | xdg.configFile | lazy.nvim for plugins |
| Tmux | programs.tmux | Prefix: Ctrl-k, Vim-style keybinds, auto-start |
| Starship | programs.starship | akari-night theme |
| Zsh | programs.zsh | autosuggestion, syntax-highlighting |
| Git | programs.git | delta for diff |
| Ghostty | xdg.configFile | akari themes |
| lazygit | programs.lazygit | Git TUI |
| fzf | programs.fzf | Fuzzy finder |
| bat | programs.bat | cat alternative |
| eza | programs.eza | ls alternative |

### Symlink Strategy

Config files in `config/` are symlinked to `~/.config/` via `xdg.configFile`:

```nix
xdg.configFile = {
  "nvim".source = ../../config/nvim;
  "ghostty".source = ../../config/ghostty;
  # ...
};
```

This allows version-controlled configs while maintaining standard XDG paths.

### Tmux Keybindings

- Prefix: `Ctrl-k`
- Pane navigation: `h/j/k/l` (Vim-style)
- Horizontal split: `|`, Vertical split: `-`
- Window navigation: `Ctrl-]`/`Ctrl-[`

## Requirements

- Nix (Determinate Systems installer recommended)
- macOS (aarch64-darwin)
- Moralerspace font (installed via Homebrew casks)

## Zsh Behavior

- **Tmux auto-start**: Zsh automatically starts Tmux on terminal launch (skipped in VS Code terminal and existing Tmux sessions)
- **Local config**: `~/.zshrc.local` for machine-specific settings (gitignored)
