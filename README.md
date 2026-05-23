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

`xdg.configFile` is linked with out-of-store symlinks so tools like Neovim can update files under `~/.config` directly. Keep the clone path above (or set `dotfilesRoot` in your `mkDarwin` host entry if you use a different location).

Each `darwinConfigurations` entry is a `(machine, user)` pair. The default `sh05MacMini` entry targets the author's account `nakamotoshougo`.

> **Important:** `make switch` only applies the home environment (Starship, gh extensions, packages, dotfile symlinks, …) to the account named by the host entry's `user`. On a different machine your macOS account name is almost certainly not `nakamotoshougo`, so you **must add your own host entry with the correct `user`**. If you skip this, `make switch` still succeeds but every setting is applied to `nakamotoshougo` and nothing reaches your account.

If your macOS account name (`whoami`) is not `nakamotoshougo`, go to [Using on Different Machines](#using-on-different-machines) first.

#### Grant Full Disk Access

nix-darwin's activation writes TCC-protected preference domains such as `com.apple.universalaccess`. Grant **Full Disk Access** to the terminal app you run bootstrap from (System Settings → Privacy & Security → Full Disk Access), then **quit and reopen** the terminal so the grant takes effect. Without it, activation aborts with:

```
defaults[...] Could not write domain com.apple.universalaccess; exiting
```

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
