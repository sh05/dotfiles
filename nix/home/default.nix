{
  pkgs,
  lib,
  config,
  username,
  dotfilesRoot,
  gh-branch-pkg,
  gh-ghq-cd-pkg,
  ccstatusline-pkg,
  ...
}:
let
  # NOTE: no pathExists fallback — pure eval (darwin-rebuild switch --flake)
  # cannot read paths outside the store, so the check always returned false
  # and silently pinned every config to a read-only store copy.
  # mkOutOfStoreSymlink never validates its target at build time, so this
  # also evaluates fine in CI where the checkout path doesn't exist.
  mutableConfigSource = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/config/${path}";

  # Optional per-machine module. Put machine-private packages / overrides at
  # ~/.config/nix-local/home.nix on the target host; the file is git-ignored
  # and lives outside this repo. If absent, this hook is a no-op so the flake
  # builds anywhere.
  localHomeModule = "/Users/${username}/.config/nix-local/home.nix";

  # Status helper scripts (migrated from the pre-Nix ~/.mySetting).
  # get_context / get_cwd_from_grandparent are referenced by name from
  # config/ccstatusline/settings.json; status-glance is bound to prefix+i
  # in config/herdr/config.toml (herdr v1 has no status bar widgets, so the
  # old tmux status-line scripts live on as an on-demand overlay pane).
  statusScripts = rec {
    get-context = pkgs.writeShellScriptBin "get_context" ''
      echo "󱃾 $(${pkgs.yq-go}/bin/yq .current-context ~/.kube/config)"
    '';
    get-cwd-from-grandparent = pkgs.writeShellScriptBin "get_cwd_from_grandparent" ''
      cwd=$(pwd)
      c=$(basename "$cwd")
      p=$(basename "$(dirname "$cwd")")
      g=$(basename "$(dirname "$(dirname "$cwd")")")
      echo "$g/$p/$c"
    '';
    get-timestamp = pkgs.writeShellScriptBin "get_timestamp" ''
      date "+%Y%m%d%H%M%S"
    '';
    get-battery-status = pkgs.writeShellScriptBin "get_battery_status" ''
      battery_info=$(/usr/bin/pmset -g ps | awk 'NR==2 { print $3 " " $4 }' | tr -d ';%')
      [ -n "$battery_info" ] || exit 0
      quantity=''${battery_info%% *}
      case "$battery_info" in
        *discharging*) echo "$quantity%" ;;
        *) echo "⚡$quantity%" ;;
      esac
    '';
    get-vpn-status = pkgs.writeShellScriptBin "get_vpn_status" ''
      # VPN_CMD_PATH / OFFICE_SSID are machine-local; export them from
      # ~/.zshrc.local. Pick up just those two lines when running outside a
      # login shell (e.g. a herdr pane).
      if [ -z "''${VPN_CMD_PATH:-}" ] && [ -f "$HOME/.zshrc.local" ]; then
        eval "$(grep -E '^export (VPN_CMD_PATH|OFFICE_SSID)=' "$HOME/.zshrc.local")" || true
      fi
      if [ -z "''${VPN_CMD_PATH:-}" ] || [ -z "''${OFFICE_SSID:-}" ]; then
        echo "vpn: n/a"
        exit 0
      fi
      device=$(networksetup -listallhardwareports | awk '/Wi-Fi/ {getline; print $2}')
      ssid=$(networksetup -getairportnetwork "$device" | awk '{print $4}')
      if echo "$ssid" | grep -q "$OFFICE_SSID"; then
        echo "$ssid"
        exit 0
      fi
      vpn_state=$("$VPN_CMD_PATH" status | grep "state: " | tail -n 1 | awk '{print $4}')
      case "$vpn_state" in
        *接続中*) echo "VPN CONNECTED" ;;
        *切断*) echo "VPN DISCONNECTED" ;;
        *) echo "vpn: unknown" ;;
      esac
    '';
    status-glance = pkgs.writeShellScriptBin "status-glance" ''
      echo "  $(date "+%Y-%m-%d %H:%M:%S")"
      echo "  $(${get-battery-status}/bin/get_battery_status)"
      echo "  $(${get-vpn-status}/bin/get_vpn_status)"
      echo "  $(${get-context}/bin/get_context)"
      printf "\n  [press any key to close]"
      read -r -s -n 1
    '';
  };
in
{
  imports = lib.optional (builtins.pathExists localHomeModule) localHomeModule;

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.11";

    # Packages (migrated from aqua.yaml)
    packages = with pkgs; [
      # Cloud/Kubernetes
      kubectl
      kubernetes-helm
      kind
      kustomize
      stern
      kyverno
      kubectx

      # Languages
      go
      nodejs_24
      bun
      uv

      # DevTools
      docker
      awscli2
      golangci-lint
      opentofu
      ko
      kubebuilder
      mise
      lefthook

      # Utils
      fzf
      jq
      yq-go
      bat
      eza
      ripgrep
      fd
      ghq
      direnv
      lazygit
      lazydocker
      tree
      wget
      curl
      htop
      fastfetch

      # Formatters/Linters
      shellcheck
      yamlfmt
      shfmt

      # LSP (for Neovim)
      gopls
      lua-language-server
      nil
      yaml-language-server
      stylua
      prettier
      typescript-language-server

      # Additional tools
      dyff
      ollama
      step-cli
      colordiff
      gnused

      # Static site / Content
      hugo

      # Rust toolchain
      rustup

      # CLI utilities
      watch
      procs
      unrar
      p7zip
      coreutils
      gawk

      # Media processing
      imagemagick
      ffmpeg

      # Claude Code
      ccstatusline-pkg
      claude-code

      # Status helper scripts (defined in the let block above)
      statusScripts.get-context
      statusScripts.get-cwd-from-grandparent
      statusScripts.get-timestamp
      statusScripts.get-battery-status
      statusScripts.get-vpn-status
      statusScripts.status-glance

      # Codex CLI
      codex

      # Terminal multiplexer (tmux replacement)
      herdr

      # Secret CLI
      _1password-cli
    ];

    # Session variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      GOPATH = "$HOME/.go";
      KUBECTL_EXTERNAL_DIFF = "colordiff -u";
      GOEXPERIMENT = "synctest";
      # npm global install を書き込み可能な prefix へ（Nix管理のnodeと共存）
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    # Session path
    sessionPath = [
      "$HOME/bin"
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.go/bin"
      "$HOME/.krew/bin"
      "$HOME/.cargo/bin"
      "$HOME/.rd/bin"
      "$HOME/.lmstudio/bin"
    ];

    # Plain dotfiles in $HOME (tool configs that don't live under ~/.config)
    file = {
      ".markdownlint-cli2.yaml".text = ''
        config:
          MD025: false
          MD033: false
          MD045: false
      '';
      ".yamlfmt".text = ''
        formatter:
          type: basic
          indentless_arrays: true
          retain_line_breaks: true
          max_line_length: 100
          drop_merge_tag: true
        doublestar: true
        include:
        - '**/*.{yaml,yml}'
      '';
    };
  };

  # Akari theme — centralised theme/palette management via the upstream
  # home-manager module (cappyzawa/akari-theme). Covers bat, delta, fzf,
  # gh-dash, ghostty, lazygit, starship, and zsh-syntax-highlighting.
  # herdr is NOT covered by the module — its akari-night palette is
  # hand-written in config/herdr/config.toml (candidate for an upstream PR).
  akari = {
    enable = true;
    variant = "night";
  };

  # XDG config file symlinks
  xdg.configFile = {
    "nvim".source = mutableConfigSource "nvim";
    "ccstatusline".source = mutableConfigSource "ccstatusline";
    "karabiner/karabiner.json".source = mutableConfigSource "karabiner/karabiner.json";
    "zsh/10_utils.zsh".source = mutableConfigSource "zsh/10_utils.zsh";
    "zsh/20_keybinds.zsh".source = mutableConfigSource "zsh/20_keybinds.zsh";
    "zsh/30_aliases.zsh".source = mutableConfigSource "zsh/30_aliases.zsh";
    "zsh/50_setopt.zsh".source = mutableConfigSource "zsh/50_setopt.zsh";
    "zsh/80_custom.zsh".source = mutableConfigSource "zsh/80_custom.zsh";
    # herdr writes logs and session state into ~/.config/herdr/, so only the
    # config file is linked — never the whole directory. herdr rewrites the
    # file in place (no rename), so the out-of-store symlink survives writes
    # from its onboarding flow / settings UI.
    "herdr/config.toml".source = mutableConfigSource "herdr/config.toml";
  };

  # Programs configuration
  programs = {
    home-manager.enable = true;

    # Zsh
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      # compaudit（fpath 全ファイルのパーミッション監査、~250ms）は dump が
      # 24時間より古いときだけ実行し、それ以外は -C でキャッシュをそのまま読む。
      # glob 修飾子 .mh-24 = 「24時間以内に更新された plain ファイル」。
      completionInit = ''
        autoload -U compinit
        if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh-24) ]]; then
          compinit -C
        else
          compinit
          # compinit は fpath が変わらない限り dump を書き直さず mtime も
          # 更新しないので、touch しないと24時間経過後は毎回フル実行になる
          touch ''${ZDOTDIR:-$HOME}/.zcompdump
        fi
      '';

      plugins = [
        {
          name = "fzf-tab";
          src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        }
      ];

      history = {
        size = 1000000;
        save = 1000000;
        path = "$HOME/.zsh_history";
        ignoreDups = true;
        share = true;
      };

      shellAliases = {
        vim = "nvim";
        ktx = "kubectx";
        kns = "kubens";
        p = "print -l";
        ".." = "cd ..";
        l = "ls -l";
        lla = "ls -lAF";
        ll = "ls -lF";
        la = "ls -AF";
        lx = "ls -lXB";
        lk = "ls -lSr";
        lc = "ls -ltcr";
        lu = "ls -ltur";
        lt = "ls -ltr";
        lr = "ls -lR";
        du = "du -h";
        job = "jobs -l";
        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";
        flushdns = "sudo killall -HUP mDNSResponder";
        arm = "exec arch -arch arm64 /bin/zsh --login";
        x64 = "exec arch -arch x86_64 /bin/zsh --login";
      };

      initContent = lib.mkMerge [
        (lib.mkOrder 500 ''
          # Word split characters
          export WORDCHARS='*?[]~&;!#$%^(){}<>'

          export ARCH=$(uname -m)

          # Source custom zsh configs
          for config_file in $XDG_CONFIG_HOME/zsh/*.zsh(N); do
            source "$config_file"
          done

          # Append non-theme fzf flags to FZF_DEFAULT_OPTS (akari sets --color=*)
          export FZF_DEFAULT_OPTS="''${FZF_DEFAULT_OPTS:-} --height 40% --reverse --border"

          # Local configuration
          if [[ -f ~/.zshrc.local ]]; then
            source ~/.zshrc.local
          fi

          if command -v mise &> /dev/null; then
            eval "$(mise activate zsh)"
          fi

          # Auto start herdr (HERDR_ENV=1 is set inside herdr panes)
          if command -v herdr &> /dev/null && [ -z "$HERDR_ENV" ] && [[ $TERM_PROGRAM != "vscode" ]]; then
            exec herdr
          fi
        '')
      ];
    };

    # Git
    git = {
      enable = true;
      # userName, userEmail は ~/.gitconfig.local から読み込み

      includes = [
        { path = "~/.gitconfig.local"; }
      ];

      ignores = [
        ".idea/*"
        ".envrc"
        ".go-version"
        ".node-version"
        ".DS_Store"
        "**/.claude/settings.local.json"
      ];

      settings = {
        core = {
          ignorecase = false;
          editor = "nvim";
        };
        ghq = {
          root = "~/ghq";
        };
        merge = {
          conflictstyle = "diff3";
        };
        pull = {
          rebase = true;
        };
        init = {
          defaultBranch = "main";
        };
        credential = {
          helper = "cache --timeout=3600";
        };
        alias = {
          st = "status";
          cm = "checkout main";
          graph = "log --graph --date-order -C -M --pretty=format:\"<%h> %ad [%an] %Cgreen%d%Creset %s\" --all --date=short";
          undo = "reset --soft HEAD^";
          np = "!git --no-pager";
        };
      };
    };

    # Delta (git diff). Theme-related options are provided by the akari module.
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };

    # Starship prompt
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        # palette and palette definitions are injected by the akari module.
        add_newline = true;
        command_timeout = 2000;

        aws.symbol = "  ";

        battery.disabled = false;

        character = {
          success_symbol = "[\\$](white)";
          error_symbol = "[\\$](muted)";
          vicmd_symbol = "[\\$](ember)";
        };

        cmd_duration.style = "yellow";

        directory = {
          truncation_length = 2;
          style = "life";
          home_symbol = "HOME";
        };

        docker_context.disabled = true;
        dotnet.disabled = true;

        elixir.symbol = " ";
        elm.symbol = " ";

        git_branch = {
          symbol = " ";
          style = "muted";
        };

        git_commit = {
          disabled = false;
          commit_hash_length = 4;
          style = "muted";
        };

        git_state = {
          disabled = true;
          style = "muted";
        };

        git_status = {
          conflicted = "=\${count}";
          ahead = "⇡\${count}";
          behind = "⇣\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          untracked = "?\${count}";
          stashed = "\\$\${count}";
          modified = "!\${count}";
          staged = "+\${count}";
          renamed = "»\${count}";
          deleted = "✘\${count}";
          style = "muted";
        };

        gcloud.disabled = true;

        golang.symbol = " ";

        kubernetes = {
          symbol = "󱃾 ";
          disabled = false;
          style = "bright-blue";
        };

        line_break.disabled = false;

        lua = {
          symbol = " ";
          lua_binary = "luajit";
        };

        nix_shell.disabled = true;
        memory_usage.disabled = true;

        java.symbol = " ";
        julia.symbol = " ";
        nim.symbol = " ";
        nodejs.symbol = " ";

        os.disabled = true;

        os.symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = "󰍲 ";
        };

        package.symbol = "󰏗 ";

        php.symbol = " ";
        python.symbol = " ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";

        terraform = {
          symbol = " ";
          format = "via [$symbol$version]($style)";
        };

        time.disabled = true;
        username.disabled = false;

        env_var.ARCH = {
          variable = "ARCH";
          style = "lantern";
        };

        custom.nvimshell = {
          command = "echo ";
          when = "test -n \"$NVIM\"";
          format = "in [$output]($style)";
          style = "bold life";
        };
      };
    };

    # gh (GitHub CLI)
    gh = {
      enable = true;
      # gh-dash は nixpkgs、gh-branch / gh-ghq-cd は flake input から
      # パッケージ化したものを lib/mkdarwin.nix 経由で受け取る。
      extensions = [
        pkgs.gh-dash
        gh-branch-pkg
        gh-ghq-cd-pkg
      ];
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        aliases = {
          cd = "ghq-cd"; # `gh cd` で gh-ghq-cd を起動
        };
      };
    };

    # gh-dash — theme is provided by the akari module; sections/layout below.
    gh-dash = {
      enable = true;
      settings = {
        prSections = [
          {
            title = "My Pull Requests";
            filters = "is:open author:@me";
          }
          {
            title = "Needs My Review";
            filters = "is:open review-requested:@me";
          }
          {
            title = "Involved";
            filters = "is:open involves:@me -author:@me";
          }
        ];
        issuesSections = [
          {
            title = "My Issues";
            filters = "is:open author:@me";
          }
          {
            title = "Assigned";
            filters = "is:open assignee:@me";
          }
        ];
        defaults = {
          prsLimit = 20;
          issuesLimit = 20;
          view = "prs";
          layout = {
            prs = {
              repoName.width = 20;
              author.width = 15;
            };
          };
        };
      };
    };

    # bat — theme is provided by the akari module.
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
      };
    };

    # lazygit — theme is layered in by the akari module via LG_CONFIG_FILE.
    lazygit.enable = true;

    # direnv
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # fzf — colours are injected via FZF_DEFAULT_OPTS by the akari module.
    # Leaving defaultOptions empty so we don't define the same env var twice;
    # the non-colour flags (height/reverse/border) are appended in zsh init below.
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
    };

    # eza (modern ls)
    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      git = true;
    };

    # Ghostty — theme is supplied by the akari module; remaining options below.
    # The Ghostty app itself is installed via Homebrew (no aarch64-darwin pkg
    # in nixpkgs), so we null the home-manager package and only generate the
    # config + theme files under $XDG_CONFIG_HOME/ghostty/.
    ghostty = {
      enable = true;
      package = null;
      settings = {
        macos-titlebar-style = "hidden";
        desktop-notifications = true;
        font-family = [
          "Moralerspace Argon NF"
          "Hack Nerd Font Mono"
          "Hiragino Kaku Gothic ProN"
        ];
        font-family-bold = "Moralerspace Argon NF";
        font-family-italic = "Moralerspace Argon NF";
        font-family-bold-italic = "Moralerspace Argon NF";
        keybind = [ "command+k=text:\\x0c" ];
      };
    };

    # Neovim (minimal - plugins managed by lazy.nvim)
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      # home-manager auto-generates an init.lua (provider toggles), which
      # collides with the whole-directory config/nvim symlink. Sideload it
      # via wrapper args so the repo's init.lua stays the only one.
      sideloadInitLua = true;
      withPython3 = false;
      withRuby = false;
    };
  };
}
