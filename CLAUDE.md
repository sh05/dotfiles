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
- `lib/mkdarwin.nix` — assembles all of the above; also packages the tools nixpkgs doesn't carry (or carries too far behind): `gh-branch` (a shell script, from a `flake = false` input), `gh-ghq-cd` (from the upstream flake's own package), `ccstatusline` (npm tarball, hash pinned), `goose` and `herdr` (upstream release binaries, hash pinned — herdr because nixpkgs' 0.9.0 lacks the `report-agent -- <resume argv>` that `sh05.goose` needs, which arrived in 0.9.2).

### Package management split

| Where | Manages | Version-pinned | Rollback |
|-------|---------|----------------|----------|
| `home.packages` (`nix/home`), from nixpkgs | CLI tools, language toolchains, LSP servers | ✅ via `flake.lock` | ✅ |
| `home.packages`, from a derivation in `lib/mkdarwin.nix` | Tools nixpkgs lacks or lags badly on | ✅ via URL + hash | ✅ |
| `homebrew.casks` (`nix/darwin`) | GUI apps, fonts | ❌ always latest | ❌ |
| `homebrew.masApps` (`hosts/<name>`) | Personal Mac App Store apps — host-specific | ❌ always latest | ❌ |
| `programs.*` (`nix/home`) | Declarative config for zsh/git/starship/etc. | — | ✅ |
| `xdg.configFile` (`nix/home`) | Symlinks from `config/<tool>/` to `~/.config/<tool>/` | — | ✅ |

Every row is declarative — the flake is the source of truth and `make switch`
converges to it. The last two columns are what actually separates them: Homebrew
records nothing in `flake.lock`, `onActivation.upgrade` bumps casks on every
switch, and `make rollback` does not bring a cask back. Two machines built from
the same `flake.lock` can therefore end up with different versions of a cask.
That is the reason GUI apps live in Homebrew rather than the reverse: it is a
trade of pinning for not having to package `.app` bundles by hand.

#### Choosing where a new tool goes

Work down the list; the first "yes" decides it.

1. **Is it a GUI `.app`, a font, or a Mac App Store purchase?** → `homebrew.casks`
   in `nix/darwin` (or `masApps` in `hosts/<name>` when it is tied to a personal
   Apple ID). Accept that it will not be version-pinned and will not roll back.

2. **Must it be absent from the work host?** → `hosts/<name>/default.nix`, but do not treat an opt-out as an uninstall plan. The shared `nix/darwin/default.nix` currently sets `homebrew.onActivation.cleanup = "zap"`; this can uninstall undeclared casks and remove their data, including when a host turns an opt-in cask off. Until cask/data removal is separately approved, the applying host must override cleanup to `none` (against the shared definition, use `lib.mkForce "none"`) and review the effective cask/cleanup changes before applying. Feature flags do not guarantee removal of manually installed apps, editor extensions, or authentication.

3. **Is it in nixpkgs at a version you can live with?** → add it to
   `home.packages`, one line, done. Check the version against *our* nixpkgs:

   ```bash
   nix eval --raw .#darwinConfigurations.sh05MacminiM2.pkgs.<name>.version
   ```

   Do **not** use `nix eval nixpkgs#<name>.version` — that reads the flake
   registry, not this repo's locked nixpkgs, and the two drift apart by months.
   (`goose-cli` reads 1.28.0 here while upstream ships 1.56.0.)

4. **Does upstream ship its own flake?** → add a flake input and pass its
   package through `extraSpecialArgs` (pattern: `gh-ghq-cd`). Reject this if the
   flake pulls in a second nixpkgs it cannot `follows` (this repo keeps a single
   nixpkgs throughout), runs tests that cannot pass in the Nix sandbox, or has
   no binary cache behind an expensive build — CI builds every darwin config on
   every push, so an uncached Rust workspace lands squarely on the critical path.

5. **Does upstream publish a prebuilt aarch64-darwin artifact?** → `pkgs.fetchurl`
   plus `stdenvNoCC.mkDerivation` in `lib/mkdarwin.nix` (patterns: `gh-branch`, `herdr`,
   `ccstatusline`, `goose`). Pin a **versioned, immutable URL** — never a rolling
   tag like `stable` or `latest`, whose assets are overwritten in place, so a
   pinned hash breaks with no warning and no commit to blame. Renovate does not
   track these (the repo enables neither the `nix` manager nor
   `lockFileMaintenance`), so leave the update recipe in a comment.

6. Otherwise build from source with `buildRustPackage` / `buildGoModule`, or
   reconsider whether the tool earns its keep.

### Config ownership and symlink strategy

Most `xdg.configFile` entries in `nix/home/default.nix` are out-of-store symlinks, so editing through those links edits the repository source. Do not infer that every tool config is linked. Goose and Herdr runtime configuration is user-owned and is not linked or synchronized by Nix. `make switch` recreates declared links but does not overwrite their repository sources.

To add a mutable source-controlled config, first verify that the target contains no secrets, session state, or other user-owned runtime data. For ordinary configs, add an entry using `mutableConfigSource`:

```nix
xdg.configFile."<tool>".source = mutableConfigSource "<tool>";
```

The helper must NOT gate on `builtins.pathExists` (or otherwise read the checkout path at eval time): `darwin-rebuild switch --flake` evaluates in pure mode, where store-external absolute paths are unreadable, so such a check silently falls back for every tool and pins configs to a read-only store copy. `mkOutOfStoreSymlink` does not validate its target at build time, so evaluation also succeeds where the checkout is absent (e.g. CI) — the link is simply dangling there.

`config/nvim/` is a full LazyVim setup managed by lazy.nvim — Nix only installs the `neovim` binary and LSP servers; plugins are managed inside Neovim. Ghostty and gh-dash are configured declaratively via `programs.ghostty.settings` / `programs.gh-dash.settings` so the akari module can layer its theme settings on top.

### AI tools and Goose ownership

`dotfiles.ai.claudeCode.enable` and `dotfiles.ai.antigravity.enable` are typed per-host Boolean opt-ins, both defaulting to `false`. The public personal host opts into both. Claude Code's CLI/status-line integration and Antigravity's CLI/GUI cask are gated by their respective options; the common Goose CLI/cask, Herdr, and Codex remain installed independently. These flags do not remove manually installed applications, editor extensions, or authentication state. A provider-specific Goose helper is generated only when selected via `dotfiles.goose.providerHelpers` (default `[]`); selecting `"claude-code"` while Claude Code is disabled is an asserted configuration error.

Goose uses `~/.config/goose/config.yaml` as mutable runtime configuration. Never symlink Goose runtime config, credentials/secrets, sessions, or other mutable state into this public checkout or the read-only Nix store. The existing public `config/goose/config.yaml` is a personal config, not a template. Typed policy:

- `dotfiles.goose.configMode`: `"unmanaged"` (default) or `"seed"`. `unmanaged` leaves the runtime target untouched. `seed` copies only on absence, creates a writable regular file with no-clobber semantics, and never synchronizes later edits. Dry-run is a no-op: it creates no directories or file.
- `dotfiles.goose.seedSource`: `null` by default; required for `"seed"`. It must name a reviewed, non-secret template; Nix may copy the path into the world-readable store.
- `dotfiles.goose.providerHelpers`: list defaulting to `[]`; only listed provider wrappers are generated.

A read-only preflight checks both Goose and Herdr configs and fails closed on Home Manager generation symlinks or legacy links into a checkout, including relocated checkouts. The conservative path check can reject similarly named user links too. This protects data from Home Manager generation cleanup; stop for a separately approved one-shot ownership migration, never auto-remove or rewrite links. The check runs before Homebrew and Home Manager activation and again before HM writes, but direct `darwin-rebuild switch` can update the system profile before activation starts. Static Goose plugin/skill sources are pinned to the flake revision, and provider-neutral `ask-pane` remains in `config/zsh/60_agents.zsh`. Herdr's runtime config, logs, and state remain user-owned; the tracked Herdr TOML is an optional manual template. Plugin registration does not restart a running server.

Homebrew's shared `onActivation.cleanup = "zap"` may uninstall undeclared casks and remove their data when an opt-in is turned off. Until cask/data removal is separately approved, set cleanup to `none` on the host being applied (use `lib.mkForce "none"` against the shared setting) and review the effective cask/cleanup plan before applying. The feature flags do not guarantee removal of apps installed by other means, editor extensions, or authentication.

Only link a single config file rather than its parent directory when a tool writes unrelated logs, sockets, or sessions beside it. Never link runtime data or anything a tool writes credentials into. Check the application's actual write behavior before adding any link.

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

- Installed as `herdr-pkg` from `lib/mkdarwin.nix` (prebuilt release, pinned); runtime config is user-owned at `~/.config/herdr/config.toml` and `config/herdr/config.toml` is an optional manual template.
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
- Goose integration: `config/herdr/plugins/sh05.goose/` is pinned from the flake source and registered with Herdr via `home.activation.herdrGoosePlugin`. Goose discovers the static plugin under `~/.agents/plugins/sh05-goose`; no runtime config is linked into the checkout. Its hooks report session state to Herdr when available. A too-old running Herdr server may reject registration; it is not restarted automatically.
- The `parallel-worktree-goose` skill is maintained in `.agents/skills/parallel-worktree-goose/`; its references, worker templates and evals are part of the same pinned Home Manager source. It defaults to workspaces/tabs without split panes and is separate from the `sh05-goose` hook plugin.
- `ask-pane` is provider-neutral and pinned from `config/zsh/60_agents.zsh`. Only provider wrappers listed in `dotfiles.goose.providerHelpers` are generated (`g-claude` or `g-openai`); the Claude wrapper requires the Claude opt-in.
- After bumping herdr, the running server keeps the old binary until restarted (`herdr status`
  shows `server_binary_stale: yes`). If the plugin's `min_herdr_version` is newer than that old
  server, plugin registration can fail; review a separate restart before re-running activation.
- Sessions persist via herdr's background server (replaces tmux-resurrect/continuum); detach with prefix + `q`

## CI

`.github/workflows/ci.yml` validates the flake on push/PR. Renovate (`.github/renovate.json`) keeps flake inputs updated.

## Gotchas for first-time bootstrap

These are not relevant for day-to-day work but matter when applying on a fresh machine — full details in `README.md`:

- nix-darwin owns `/etc/nix/nix.conf` after bootstrap; first activation aborts on pre-existing `/etc/{nix/nix.conf,bashrc,zshrc}` and they must be renamed to `*.before-nix-darwin`.
- The terminal running `make bootstrap` needs Full Disk Access (nix-darwin writes TCC-protected preference domains like `com.apple.universalaccess`).
