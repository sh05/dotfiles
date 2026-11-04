{
  lib,
  config,
  pkgs,
  username,
  dotfilesRoot,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.dotfiles;
  home = config.home-manager.users.${username}.home.homeDirectory;
  gooseTarget = "${config.home-manager.users.${username}.xdg.configHome}/goose/config.yaml";
  herdrTarget = "${config.home-manager.users.${username}.xdg.configHome}/herdr/config.toml";
  ownershipPreflight = pkgs.writeShellScript "dotfiles-ai-ownership-preflight" ''
    set -e
    ${pkgs.python3}/bin/python3 ${../home/goose-config-activation.py} preflight \
      --home ${lib.escapeShellArg home} \
      --target ${lib.escapeShellArg gooseTarget} \
      --store-dir ${lib.escapeShellArg builtins.storeDir} \
      --legacy-source ${lib.escapeShellArg "${dotfilesRoot}/config/goose/config.yaml"}
    ${pkgs.python3}/bin/python3 ${../home/goose-config-activation.py} preflight \
      --home ${lib.escapeShellArg home} \
      --target ${lib.escapeShellArg herdrTarget} \
      --store-dir ${lib.escapeShellArg builtins.storeDir} \
      --legacy-source ${lib.escapeShellArg "${dotfilesRoot}/config/herdr/config.toml"} \
      --label herdr
  '';
in
{
  options.dotfiles = {
    ai = {
      claudeCode.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this host installs Claude Code and its status-line integration.";
      };

      antigravity.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this host installs the Antigravity CLI and GUI cask.";
      };
    };

    goose = {
      configMode = mkOption {
        type = types.enum [ "unmanaged" "seed" ];
        default = "unmanaged";
        description = ''
          Ownership policy for ~/.config/goose/config.yaml. unmanaged leaves it
          alone; seed copies seedSource once, only when no directory entry exists.
        '';
      };

      providerHelpers = mkOption {
        type = types.listOf (types.enum [ "claude-code" "chatgpt_codex" ]);
        default = [ ];
        description = ''
          Goose provider-specific shell helpers to generate. This is a Nix
          distribution policy, not a Goose configuration field.
        '';
      };

      seedSource = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Reviewed, non-secret template copied by configMode = "seed" when the
          runtime config path has no directory entry. Nix may copy this path
          to the store; never use runtime state, credentials, or secrets.
        '';
      };
    };
  };

  # Home Manager runs in postActivation, after Homebrew and other system
  # changes. Check mutable Goose and Herdr configs before those effects, then
  # repeat before HM's write boundary. darwin-rebuild may already have set
  # the system profile before this activation script starts.
  config.system.build.aiOwnershipPreflight = ownershipPreflight;
  config.system.activationScripts.preActivation.text = lib.mkBefore ''
    echo "Checking Goose and Herdr config ownership before system activation" >&2
    /usr/bin/sudo -u ${lib.escapeShellArg username} --set-home ${ownershipPreflight}
  '';

  config.assertions = [
    {
      assertion = cfg.goose.configMode != "seed" || cfg.goose.seedSource != null;
      message = "dotfiles.goose.seedSource is required when dotfiles.goose.configMode = \"seed\".";
    }
    {
      assertion = !(builtins.elem "claude-code" cfg.goose.providerHelpers) || cfg.ai.claudeCode.enable;
      message = ''
        dotfiles.goose.providerHelpers includes "claude-code", but
        dotfiles.ai.claudeCode.enable is false. Enable Claude Code explicitly
        or remove the Claude Code Goose helper.
      '';
    }
  ];
}
