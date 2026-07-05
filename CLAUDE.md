# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS (Apple Silicon, `aarch64-darwin`) development environment managed with Nix Flakes + nix-darwin + home-manager.

## Common Commands

```bash
make switch              # Apply current configuration
make update              # nix flake update + apply
make rollback            # Roll back to previous generation
make check               # nix flake check (validate without applying)
make gc                  # Garbage collect old generations
make list-generations    # List generations
make switch-generation GEN=N   # Switch to specific generation

# Build only, no activation (useful for verifying a change before applying):
nix build .#darwinConfigurations.sh05MacminiM2.system
```

`NIXNAME` is read from `~/.config/nix/host` (written during `make bootstrap`). To target a different host, pass `NIXNAME=<host>` on the command line.

## Architecture

### Host model: `(machine, user)` pairs

`flake.nix` declares one `darwinConfigurations.<name>` entry per host via `mkDarwin name { user = "..."; }` from `lib/mkdarwin.nix`. The current entry is `sh05MacminiM2` (user `sh05`).

Critical invariants enforced by `lib/mkdarwin.nix`:

- `user` MUST equal the macOS account name (`whoami`) of whoever runs `make switch`. It sets `system.primaryUser`, the home-manager target (`/Users/<user>`), and the user Homebrew runs as. Mismatch means activation silently configures the wrong account or `brew bundle` fails.
- There is no fallback default — a missing/wrong `user` surfaces immediately.
- A Mac has a single nix-darwin system config. Each `make switch` overwrites the system with the most recently applied entry's `primaryUser`.

When adding a new host, create `hosts/<name>/default.nix` and add a `mkDarwin` entry in `flake.nix`. Personal-only Mac App Store apps belong in `hosts/<name>/default.nix` (`homebrew.masApps`), NOT in `nix/darwin/default.nix` — this is how personal vs work hosts are separated.

### Module layout

- `nix/darwin/default.nix` — macOS `system.defaults` (Dock/Finder/trackpad/Rectangle plist), Homebrew `casks`/`brews`/`masApps` shared across hosts, system fonts.
- `nix/home/default.nix` — home-manager: `home.packages` (CLI/LSP/languages), `programs.*` declarative tool config (zsh, git, starship, delta, gh, bat, lazygit, direnv, fzf, eza, neovim), `xdg.configFile` symlinks.
- `nix/modules/shared.nix` — `nix` daemon settings, `nixpkgs.config.allowUnfree`, `system.stateVersion`.
- `hosts/<name>/default.nix` — `networking.hostName`, `networking.computerName`, host-specific `homebrew.masApps`.
- `lib/mkdarwin.nix` — assembles all of the above; also packages `gh-branch` (shell script from flake input), `gh-ghq-cd`, and `herdr` (flake inputs' own packages) since they aren't in nixpkgs.

### Package management split

| Where | Manages |
|-------|---------|
| `home.packages` (`nix/home`) | CLI tools, language toolchains, LSP servers |
| `homebrew.casks` (`nix/darwin`) | GUI apps, fonts |
| `homebrew.masApps` (`hosts/<name>`) | Personal Mac App Store apps — host-specific |
| `programs.*` (`nix/home`) | Declarative config for zsh/git/starship/etc. |
| `xdg.configFile` (`nix/home`) | Symlinks from `config/<tool>/` to `~/.config/<tool>/` |

### Config symlink strategy

Files in `config/` are version-controlled and symlinked into `~/.config/` by `xdg.configFile` in `nix/home/default.nix`. The symlinks are **out-of-store** (via `config.lib.file.mkOutOfStoreSymlink`), so `~/.config/<tool>` points directly to the repo's `config/<tool>/` — editing through the symlink IS editing the repo file, no copy-back step needed. `make switch` re-creates the symlink but does not overwrite file contents, so uncommitted repo edits survive a re-run.

To add a new tool's config: drop files into `config/<tool>/` and add an entry using the `mutableConfigSource` helper (defined at the top of `nix/home/default.nix`):

```nix
xdg.configFile."<tool>".source = mutableConfigSource "<tool>";
```

The helper must NOT gate on `builtins.pathExists` (or otherwise read the checkout path at eval time): `darwin-rebuild switch --flake` evaluates in pure mode, where store-external absolute paths are unreadable, so such a check silently falls back for every tool and pins configs to a read-only store copy. `mkOutOfStoreSymlink` doesn't validate its target at build time, so evaluation also succeeds where the checkout is absent (e.g. CI) — the link is simply dangling there.

`config/nvim/` is a full LazyVim setup managed by lazy.nvim — Nix only installs the `neovim` binary and LSP servers; plugins are managed inside Neovim. Ghostty and gh-dash used to live in `config/` as raw files but are now configured declaratively via `programs.ghostty.settings` / `programs.gh-dash.settings` so the akari module can layer its theme settings on top.

`config/herdr/config.toml` is linked as a single file (not the whole `herdr/` directory) because herdr writes logs and session state into `~/.config/herdr/`. herdr rewrites the config in place (no atomic rename), so the out-of-store symlink survives writes from its onboarding flow / settings UI and those edits land in the repo file.

### Theme

Akari Night is applied centrally via the [`cappyzawa/akari-theme`](https://github.com/cappyzawa/akari-theme) home-manager module. The flake input `akari-theme` is composed into the home configuration in `lib/mkdarwin.nix`, and `nix/home/default.nix` enables it with `akari = { enable = true; variant = "night"; };`. The module owns the theme for `bat`, `delta`, `fzf`, `gh-dash`, `ghostty`, `lazygit`, `starship`, and `zsh-syntax-highlighting`, so per-tool blocks in `nix/home/default.nix` must **not** redefine palettes or theme colours — doing so will collide with the module's settings.

Out of scope for the module (managed differently or not managed):

- **herdr** is not supported by the module. Its Akari Night palette is hand-written in `config/herdr/config.toml` (`[theme] name = "terminal"` follows Ghostty's akari ANSI palette; `[theme.custom]` overrides UI tokens with values taken from the upstream `dist/` generated themes). This block is the reference implementation for a future herdr template PR to `cappyzawa/akari-theme`.
- **Neovim** uses the `cappyzawa/akari-nvim` plugin loaded by lazy.nvim in `config/nvim/lua/plugins/ui.lua`.
- **Helix / Zellij / Alacritty** are unused in this setup.
- **VSCode / macOS Terminal / Slack / Chrome** are intentionally not centralised — install/import their Akari themes manually from the upstream repo if desired.

To bump to a newer Akari release: `nix flake update akari-theme` then `make switch`.

## Required local files (gitignored)

- `~/.gitconfig.local` — `[user] name = ... / email = ...`. Included by `programs.git.includes`; activation works without it but commits will be unattributed.
- `~/.zshrc.local` — sourced at the end of zsh init for machine-specific overrides.

## Herdr (terminal multiplexer, replaced tmux)

- Installed from the `herdr` flake input (`github:ogulcancelik/herdr`, Rust source build); config lives in `config/herdr/config.toml`
- Prefix: `Ctrl-k` (not the default `Ctrl-b`)
- Vim-style pane nav: prefix + `h/j/k/l` (herdr default); splits: prefix + `|` (side-by-side), prefix + `-` (stacked)
- Tab cycle: prefix + `n`/`p` (herdr default) or prefix + `Ctrl-]`/`Ctrl-[` (tmux-era)
- Copy mode: prefix + `v` (tmux-era) or prefix + `[` (herdr default). Inside it herdr is
  vim-style out of the box — `v`/Space select, `y`/Enter yank (to system clipboard),
  `h/j/k/l` + `w/b/e` movement. Copy-mode internals are not configurable; paste is Cmd+V
  (there is no tmux-style `prefix p` paste buffer — that key cycles tabs).
- Resize: prefix + `r` enters resize mode (replaces tmux's repeatable prefix + `H/J/K/L`);
  zoom: prefix + `z`; swap panes: prefix + `Shift-h/j/k/l` (all herdr defaults)
- Not carried over from tmux (no herdr equivalent): synchronize-panes, even-horizontal/vertical
  layouts, pane-border title toggle
- Auto-starts from zsh on terminal launch, except inside VS Code or an existing herdr pane (guarded by `HERDR_ENV`)
- Sessions persist via herdr's background server (replaces tmux-resurrect/continuum); detach with prefix + `q`

## CI

`.github/workflows/ci.yml` validates the flake on push/PR. Renovate (`.github/renovate.json`) keeps flake inputs updated.

## Gotchas for first-time bootstrap

These are not relevant for day-to-day work but matter when applying on a fresh machine — full details in `README.md`:

- nix-darwin owns `/etc/nix/nix.conf` after bootstrap; first activation aborts on pre-existing `/etc/{nix/nix.conf,bashrc,zshrc}` and they must be renamed to `*.before-nix-darwin`.
- The terminal running `make bootstrap` needs Full Disk Access (nix-darwin writes TCC-protected preference domains like `com.apple.universalaccess`).
