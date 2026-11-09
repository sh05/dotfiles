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

The official installer does not enable flakes. Enable them in per-user Nix config files. Do **not** edit `/etc/nix/nix.conf` — nix-darwin takes that file over during bootstrap, and editing it makes the first activation abort.

```bash
# For your user (used by `nix build` / `nix flake check`)
mkdir -p ~/.config/nix
echo 'extra-experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# For root (used by `sudo` during `make bootstrap`)
sudo mkdir -p /var/root/.config/nix
echo 'extra-experimental-features = nix-command flakes' | sudo tee -a /var/root/.config/nix/nix.conf
```

After the first `make bootstrap`, nix-darwin manages `/etc/nix/nix.conf` with flakes enabled system-wide, so these two files become redundant (harmless to keep or remove).

### 4. Install Homebrew

nix-darwin manages Homebrew packages but does not install Homebrew itself:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 5. Clone and Bootstrap

```bash
git clone https://github.com/sh05/dotfiles.git ~/ghq/github.com/sh05/dotfiles
cd ~/ghq/github.com/sh05/dotfiles
```

Many `xdg.configFile` entries use out-of-store symlinks so tools like Neovim can update files under `~/.config` directly. Not every config follows that rule: Goose and Herdr runtime configs are user-owned and are not linked from this repo; Herdr has no automatic seed mode. Keep the clone path above (or set `dotfilesRoot` in your `mkDarwin` host entry if you use a different location).

Each `darwinConfigurations` entry is a `(machine, user)` pair. The default `sh05MacMini` entry targets the author's account `nakamotoshougo`.

> **Important:** `make switch` only applies the home environment (Starship, gh extensions, packages, dotfile symlinks, …) to the account named by the host entry's `user`. On a different machine your macOS account name is almost certainly not `nakamotoshougo`, so you **must add your own host entry with the correct `user`**. If you skip this, `make switch` still succeeds but every setting is applied to `nakamotoshougo` and nothing reaches your account.

If your macOS account name (`whoami`) is not `nakamotoshougo`, go to [Using on Different Machines](#using-on-different-machines) first.

#### Grant Full Disk Access

nix-darwin's activation writes TCC-protected preference domains such as `com.apple.universalaccess`. Grant **Full Disk Access** to the terminal app you run bootstrap from (System Settings → Privacy & Security → Full Disk Access), then **quit and reopen** the terminal so the grant takes effect. Without it, activation aborts with:

```
defaults[...] Could not write domain com.apple.universalaccess; exiting
```

> **Running inside tmux (or another terminal multiplexer)?** The grant will *not* take effect even after reopening the terminal: the multiplexer's server process keeps running with its old TCC context, and every shell inside it inherits that context. Run `tmux kill-server`, open a fresh terminal, and retry.

#### Run bootstrap

```bash
make bootstrap NIXNAME=sh05MacMini
```

`make bootstrap` runs `darwin-rebuild` with `sudo`, so it will prompt for your macOS password.

#### First activation: "Unexpected files in /etc"

On a machine where Nix was installed with the official installer, the first activation aborts because nix-darwin will not overwrite system files it did not create:

```
error: Unexpected files in /etc, aborting activation
  /etc/nix/nix.conf
  /etc/bashrc
  /etc/zshrc
```

This is expected. Rename each listed file with a `.before-nix-darwin` suffix (a backup — nix-darwin generates fresh ones), then re-run bootstrap:

```bash
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/bashrc       /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc        /etc/zshrc.before-nix-darwin
make bootstrap NIXNAME=sh05MacMini
```

Because flakes were enabled in the per-user config files (step 3), renaming `/etc/nix/nix.conf` is safe — flakes stay available for the re-run.

#### Existing shell dotfiles: "would be clobbered"

home-manager refuses to overwrite `~/.zshrc` / `~/.zshenv` files it did not create — including symlinks left behind by a previous dotfiles setup, which `backupFileExtension` does not cover:

```
Existing file '/Users/<you>/.zshrc' would be clobbered
```

Move the listed files aside (for symlinks, simply delete them — the targets stay intact) and re-run bootstrap. Machine-local settings belong in `~/.zshrc.local`, which the generated zshrc sources at the end.

#### Corporate networks with TLS interception

If your network re-encrypts HTTPS with a corporate CA (a MITM proxy), set the CA bundle in your host module so it lands in `/etc/nix/nix.conf`:

```nix
nix.settings.ssl-cert-file = "/path/to/corporate-ca-bundle.pem";
```

Exporting `NIX_SSL_CERT_FILE` in your shell is *not* enough: substitutions (`.narinfo`/NAR downloads) are performed by the nix-daemon, a launchd service that never sees your shell environment. The symptom is confusing — `curl` and `nix eval` succeed while `nix build` fails with `unable to get local issuer certificate`. For the very first bootstrap (before nix-darwin manages `nix.conf`), temporarily inject the variable into the daemon's launchd plist, and pass it via `sudo env` for the client side.

#### Cask upgrades failing with Swift errors

If `brew bundle` fails during activation with `redefinition of module 'SwiftBridging'` or `this SDK is not supported by the compiler`, the Xcode Command Line Tools are out of sync with the macOS SDK (Homebrew compiles a small Swift helper when upgrading casks; fresh installs are unaffected). Reinstall them and re-run:

```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

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

- Edit files under `config/` and `nix/` in this repository, then run `make switch` to apply them.
- Most `~/.config/<tool>` entries managed through `xdg.configFile` are out-of-store symlinks into this repo, so editing through those links edits the repo file directly. Goose and Herdr runtime configs are intentionally not linked or synchronized.
- `make switch` re-creates declared links; it does not overwrite the contents of their repo sources, so uncommitted edits there survive a re-run. Commit them to avoid losing them on a `git checkout` or `git reset`.
- `make switch` rebuilds and applies the current host configuration using the current `flake.lock` (it does not update dependency versions).
- `make update` runs `nix flake update` first, then applies the configuration (it includes dependency version updates in `flake.lock`).
- `make rollback` moves the current host back to the **previous darwin generation**. It rolls back declarative settings managed by nix-darwin / home-manager, but not manually created user data (app data, arbitrary files, etc.).

> Note: Home Manager still manages `~/.zshrc`, so installers that append directly to `~/.zshrc` can fail. Put machine-local script output in `~/.zshrc.local` (already sourced from this config).

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

## Adding a tool

Where a new tool is declared decides how well it can be pinned:

| Where | Example | Version-pinned | Rollback |
|-------|---------|----------------|----------|
| `home.packages`, from nixpkgs | `kubectl` | ✅ via `flake.lock` | ✅ |
| `home.packages`, from a derivation in `lib/mkdarwin.nix` | `ccstatusline`, `goose` | ✅ via URL + hash | ✅ |
| `homebrew.casks` in `nix/darwin` | `ghostty`, `block-goose` | ❌ always latest | ❌ |

All three are declarative, and `make switch` converges to whatever the flake
says. Homebrew is the one that records nothing in `flake.lock`: casks upgrade on
every switch and `make rollback` will not bring one back. Prefer nixpkgs, and
reach for Homebrew when packaging a `.app` yourself isn't worth it.

The full decision flow — including how to check a package's version in *this*
repo's nixpkgs rather than the flake registry — is in CLAUDE.md under
"Choosing where a new tool goes".

### Updating a pinned prebuilt binary

`ccstatusline` and `goose` are pinned by URL and hash because nixpkgs lags too
far behind them. Renovate does not track these, so bumps are manual:

```bash
v=1.56.0
nix store prefetch-file --json \
  "https://github.com/block/goose/releases/download/v$v/goose-aarch64-apple-darwin.tar.gz" \
  | jq -r .hash
```

Put the new `version` and `hash` in `lib/mkdarwin.nix`, then verify before
applying:

```bash
nix build .#darwinConfigurations.sh05MacminiM2.system
make switch
```

Always pin a versioned tag. Upstream also publishes a `stable` tag whose assets
are overwritten in place on each release — pinning a hash against that breaks
later, with no commit to blame.

### Host-level AI tool policy

Claude Code and Antigravity are typed per-host opt-ins: `dotfiles.ai.claudeCode.enable`
and `dotfiles.ai.antigravity.enable` both default to `false`. The public personal
host explicitly enables both; other hosts remain opted out unless their host
module opts in. Claude Code adds its CLI/status-line integration, while
Antigravity adds its CLI and GUI cask.

`dotfiles.goose.configMode` is `"unmanaged"` by default and accepts `"unmanaged"`
or `"seed"`. `dotfiles.goose.providerHelpers` is a Nix-only selection list,
defaulting to `[]`; it generates only the selected provider-specific shell
wrappers. Selecting `"claude-code"` requires Claude Code to be enabled (a Nix
assertion). This is host distribution policy, not a Goose YAML setting.

These opt-ins do not promise to remove apps installed by other means, editor
extensions, or authentication. The Goose CLI and `block-goose` cask, Herdr, and
Codex remain common declarations regardless of these flags. Plugin registration
does not automatically restart an already-running Herdr server.

> **Homebrew cleanup can remove data.** The shared Darwin configuration sets
> `homebrew.onActivation.cleanup = "zap"`. When a cask becomes undeclared—for
> example, when Antigravity is turned off—Homebrew cleanup can uninstall it and
> remove its data. Until cask/data removal has separate approval, set cleanup to
> `none` in the applying host and review the effective casks and cleanup policy
> before applying:
>
> ```nix
> { lib, ... }:
> {
>   homebrew.onActivation.cleanup = lib.mkForce "none";
> }
> ```

### goose (worked example)

goose is installed in two halves, on purpose:

- **CLI** — the upstream release binary, pinned in `lib/mkdarwin.nix` and added
  to `home.packages`. nixpkgs carries `goose-cli` but currently at 1.28.0, so
  this pin tracks the GUI cask's current 1.56.0 release.
- **GUI** — the `block-goose` cask in `nix/darwin/default.nix`. The cask ships
  `Goose.app` and nothing else, so it puts no `goose` on your `PATH`.

The cask auto-upgrades while the CLI is pinned, so the two drift apart. Both read
the same `~/.config/goose/config.yaml`, and the newer one migrates that file in
place on read — which the older one then cannot parse. Check for drift with:

```bash
make goose-check
```

Goose's mutable runtime config is `~/.config/goose/config.yaml` (see the upstream
[configuration-files guide](https://goose-docs.ai/docs/guides/config-files)). It
is user-owned, not linked from this repository or the Nix store. In particular,
the checked-in `config/goose/config.yaml` is a historical personal config and
must not be used as a seed template. Goose credentials/secrets, sessions, and
other runtime state are not linked into the public checkout or read-only store.
Home Manager exports `GOOSE_AUTO_COMPACT_THRESHOLD=0.0` to its shell sessions,
which disables proactive auto-compaction in Goose processes inheriting that
variable. Environment variables take precedence over the runtime config, which
is not modified. This shared value can be overridden in a host module. Existing
processes need a new environment; independently launched GUI apps and
long-running servers that do not inherit Home Manager session variables are not
covered. `goose info -v` displays the stored configuration rather than this
process environment override. Goose may still use a context-limit strategy
when the model's limit is reached; see the upstream
[context-management guide](https://goose-docs.ai/docs/guides/sessions/smart-context-management).

The typed Nix policy for Goose config is:

| Option | Default | Meaning |
|--------|---------|---------|
| `dotfiles.goose.configMode` | `"unmanaged"` | `"unmanaged"` or `"seed"` |
| `dotfiles.goose.providerHelpers` | `[]` | Selected provider-specific shell helpers; generate only selected helpers |
| `dotfiles.goose.seedSource` | `null` | A reviewed, non-secret template path; required for `"seed"` |

`unmanaged` does not modify the runtime config. `seed` copies `seedSource` only
when the target has no filesystem entry; it creates a writable regular file and
uses no-clobber creation, so an existing file, symlink, or directory is preserved.
It is a one-time seed, not ongoing synchronization. In dry-run mode no directory
or file is created. `seedSource` must be explicitly reviewed and non-secret: Nix can copy a path-typed source into its world-readable store.

A read-only preflight checks both `~/.config/goose/config.yaml` and
`~/.config/herdr/config.toml`. It fails closed on old Home Manager generation
links or legacy links into a checkout (including relocated checkouts), so
Home Manager cleanup cannot silently remove them. Stop and arrange a separately
approved one-time ownership migration; activation never removes or migrates
these links automatically. The conservative checkout-path check can also
reject similarly named links outside this checkout. In unmanaged mode it still
runs but does not modify any target.

The check runs before Homebrew and Home Manager activation, then again at the
Home Manager write boundary. Direct `darwin-rebuild switch` can nevertheless
update the system profile before activation starts; a failed check is not a
promise that no system profile changed. Review before any apply.

Static Goose integration sources are pinned to this flake revision: the
`sh05-goose` plugin and `parallel-worktree-goose` skill (see the upstream
[plugin guide](https://goose-docs.ai/docs/guides/context-engineering/plugins)
and [skills guide](https://goose-docs.ai/docs/guides/context-engineering/using-skills)).
The skill coordinates separate Herdr worktrees and Goose sessions, including
safe prompt submission, recovery, and cleanup. It defaults to workspaces/tabs
without split panes. Guidance and eval scenarios are in
[`.agents/skills/parallel-worktree-goose/`](.agents/skills/parallel-worktree-goose/).
The plugin's lifecycle hooks remain separate from the skill. The
`parallel-worktree-codex` skill is also available for Codex CLI, covering native
subagents, Codex-managed worktrees, isolated Git worktrees, and optional Herdr
coordination. It does not assume that native subagents automatically have
separate worktrees. Both skills are linked to `~/.agents/skills/` by Home
Manager; Codex also discovers repository-local skills under `.agents/skills/`.
Guidance is in [`.agents/skills/parallel-worktree-codex/`](.agents/skills/parallel-worktree-codex/).
The provider-neutral `ask-pane` helper is source-controlled in
`config/zsh/60_agents.zsh`; provider-specific wrappers are generated only when
selected in `dotfiles.goose.providerHelpers`. The `"claude-code"` wrapper requires
`dotfiles.ai.claudeCode.enable`; an assertion rejects the inconsistent policy.
Herdr's `~/.config/herdr/config.toml` is also user-owned: it is not linked,
seeded, or synchronized by Nix. The tracked `config/herdr/config.toml` is an
optional manual template, not a live runtime file. Herdr logs, state, and
credentials remain outside Git and the store. Registering the pinned static
plugin does not automatically restart an already-running Herdr server.

Two installation traps are worth knowing:

- **Do not `brew install goose`.** That formula is [pressly/goose](https://github.com/pressly/goose),
  a database migration tool. Since `/opt/homebrew/bin` precedes the nix profile
  on `PATH`, it silently shadows the real binary and the errors make no sense.
- **Do not use the curl installer.** It drops a binary in `~/.local/bin`, which
  also wins on `PATH`.

`make rollback` restores the pinned CLI but not the Homebrew cask. Cask removal
is a separately reviewed Homebrew change.

## Using on Different Machines

Each `darwinConfigurations` entry is a `(machine, user)` pair. On a different machine your macOS account name is almost always something other than `nakamotoshougo`, so you need your own entry.

### Add a new machine / user

1. **Create the host config directory** (`hosts/<HostName>/default.nix`)
   ```nix
   { ... }:
   {
     networking = {
       hostName = "<HostName>";
       computerName = "<HostName>";
     };

     # Optional: install personal-only Mac App Store apps on this host
     # homebrew.masApps = {
     #   "LINE" = 539883307;
     #   "Kindle" = 302584613;
     # };
   }
   ```

2. **Add an entry to flake.nix**
   ```nix
   darwinConfigurations = {
     "<HostName>" = mkDarwin "<HostName>" {
       user = "<yourusername>"; # may be omitted if it equals the host name
       # dotfilesRoot = "/Users/<yourusername>/path/to/dotfiles"; # optional
     };
   };
   ```

   > **`user` must equal your macOS account name (`whoami`).** It sets `system.primaryUser`, the home-manager target (`/Users/<user>`), and the user Homebrew runs as. If omitted it falls back to the host name. A mismatch makes `brew bundle` fail during activation, or applies the home environment to the wrong account.

3. **Bootstrap**
   ```bash
   make bootstrap NIXNAME=<HostName>
   ```

### Keep a machine private (wrapper flake)

If a machine's hostname or configuration should not appear in this public repository (e.g. a work laptop), create a *private wrapper flake* in a separate repository instead of adding an entry here. This repo exports `lib.mkDarwin`, and its `hostModule` argument lets the wrapper inject the host config from outside:

```nix
# flake.nix (private repository)
{
  inputs.dotfiles.url = "github:sh05/dotfiles";

  outputs = { self, dotfiles }: {
    darwinConfigurations."<HostName>" = dotfiles.lib.mkDarwin "<HostName>" {
      user = "<yourusername>";
      hostModule = ./hosts/<HostName>; # networking, masApps, private packages, …
    };
  };
}
```

Run `sudo darwin-rebuild switch --flake '.#<HostName>'` from the wrapper repository. Nothing about the machine ever touches this repo; shared configuration is picked up by re-locking the input (`nix flake update dotfiles`). The host module is a regular nix-darwin module, so it can also carry machine-private packages via `home-manager.users.<user>.home.packages`.

### Verifying with another user on the same machine

This repo ships a `sh05MacMini-test` entry (`user = "test"`) for verification. To verify under the `test` account, log in as that user and run:

```bash
make switch NIXNAME=sh05MacMini-test
```

Switch back to the real configuration afterwards:

```bash
make switch NIXNAME=sh05MacMini
```

A Mac has a single nix-darwin system configuration, so each `make switch` overwrites the system with the `primaryUser` of the last entry applied.

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
