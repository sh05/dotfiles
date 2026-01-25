{
  pkgs,
  lib,
  username,
  tpm,
  ...
}:
{
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
      nodejs_22
      bun
      uv

      # DevTools
      docker
      awscli2
      golangci-lint
      opentofu
      ko
      kubebuilder

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
      neofetch

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
      nodePackages.prettier
      nodePackages.typescript-language-server

      # Additional tools
      dyff
      alertmanager
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
    };

    # Session path
    sessionPath = [
      "$HOME/bin"
      "$HOME/.local/bin"
      "$HOME/.go/bin"
      "$HOME/.krew/bin"
      "$HOME/.cargo/bin"
      "$HOME/.rd/bin"
    ];
  };

  # XDG config file symlinks
  xdg.configFile = {
    "nvim".source = ../../config/nvim;
    "karabiner/karabiner.json".source = ../../config/karabiner/karabiner.json;
    "zsh/10_utils.zsh".source = ../../config/zsh/10_utils.zsh;
    "zsh/20_keybinds.zsh".source = ../../config/zsh/20_keybinds.zsh;
    "zsh/30_aliases.zsh".source = ../../config/zsh/30_aliases.zsh;
    "zsh/50_setopt.zsh".source = ../../config/zsh/50_setopt.zsh;
    "zsh/80_custom.zsh".source = ../../config/zsh/80_custom.zsh;
    "ghostty".source = ../../config/ghostty;
    "tmux/plugins/tpm" = {
      source = tpm;
      recursive = true;
    };
    "gh-ext-manage/config.json".source = ../../config/gh-ext-manage/config.json;
    "gh-dash/config.yml".source = ../../config/gh-dash/config.yml;
    "bat/themes".source = ../../config/bat/themes;
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

          # Source custom zsh configs
          for config_file in $XDG_CONFIG_HOME/zsh/*.zsh(N); do
            source "$config_file"
          done

          # Local configuration
          if [[ -f ~/.zshrc.local ]]; then
            source ~/.zshrc.local
          fi

          # Auto start tmux
          if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [[ $TERM_PROGRAM != "vscode" ]]; then
            exec tmux
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
      ];

      extraConfig = {
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
      };

      aliases = {
        st = "status";
        cm = "checkout main";
        graph = "log --graph --date-order -C -M --pretty=format:\"<%h> %ad [%an] %Cgreen%d%Creset %s\" --all --date=short";
        undo = "reset --soft HEAD^";
        np = "!git --no-pager";
      };
    };

    # Delta (git diff)
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
        dark = true;
        # Akari Night theme
        minus-style = "syntax \"#3F2A25\"";
        minus-emph-style = "syntax \"#5C3A32\"";
        plus-style = "syntax \"#2A3F25\"";
        plus-emph-style = "syntax \"#3A5C32\"";
        line-numbers-minus-style = "#D25046";
        line-numbers-plus-style = "#7FAF6A";
        line-numbers-zero-style = "#716A5F";
        hunk-header-style = "file line-number syntax";
        hunk-header-decoration-style = "box ul #3F4346";
        file-style = "#E26A3B bold";
        file-decoration-style = "none";
      };
    };

    # Tmux
    tmux = {
      enable = true;
      prefix = "C-k";
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "screen-256color";
      mouse = true;
      baseIndex = 1;
      escapeTime = 50;
      keyMode = "vi";
      historyLimit = 50000;

      extraConfig = ''
        # Default command for macOS
        set-option -g default-command "exec arch -arch arm64 /bin/zsh --login"
        set-option -g focus-events on
        set-option -ga terminal-overrides ",xterm-256color:Tc"

        # Split window from current path
        bind-key | split-window -h -c '#{pane_current_path}'
        unbind '"'
        bind-key - split-window -v -c '#{pane_current_path}'
        unbind '%'

        # New Window
        bind-key c new-window -c '#{pane_current_path}'

        # Equal layouts
        bind ^h select-layout even-horizontal
        bind ^v select-layout even-vertical

        # Move window in order
        bind-key C-] select-window -t +1
        bind-key C-[ select-window -t -1

        # Custom mouse settings
        unbind-key -T root MouseDown1Pane
        unbind-key -T root MouseDown3Pane

        # Pane Title
        bind-key C-k run 'zsh -c "arr=( top off ) && tmux setw pane-border-status \''${arr[\$(( \''${arr[(I)#{pane-border-status}]} % 2 + 1 ))]}"'
        bind-key : command-prompt -p "(rename-pane)" "select-pane -T %%"

        # Resize pane
        bind-key -r H resize-pane -L 5
        bind-key -r J resize-pane -D 5
        bind-key -r K resize-pane -U 5
        bind-key -r L resize-pane -R 5

        # Change active pane
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R

        # Reload config file
        bind-key r source-file ~/.config/tmux/tmux.conf\; display-message "[tmux] tmux.conf reloaded!"

        # sync
        bind a setw synchronize-panes \; display "synchronize-panes #{?pane_synchronized,on,off}"

        # Look up in a man-page
        bind-key m command-prompt -p "Man:" "split-window 'man %%'"

        # status bar
        set-option -g status-position top
        set -g status-keys vi

        # Copy mode like vim
        bind-key v copy-mode \; display "Copy mode!"
        bind-key p paste-buffer
        bind-key -T edit-mode-vi Up send-keys -X history-up
        bind-key -T edit-mode-vi Down send-keys -X history-down
        unbind-key -T copy-mode-vi Space
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi V send-keys -X select-line
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi c send-keys -X clear-selection
        bind-key -T copy-mode-vi H send-keys -X start-of-line
        bind-key -T copy-mode-vi L send-keys -X end-of-line
        bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

        set-environment -g PATH "/opt/homebrew/bin:/usr/local/bin:/bin:/usr/bin:$PATH"
        TMUX_FZF_SED="/usr/local/opt/gnu-sed/libexec/gnubin/sed"

        # List of plugins
        set -g @plugin 'tmux-plugins/tpm'
        set -g @plugin 'tmux-plugins/tmux-open'
        set -g @plugin 'sainnhe/tmux-fzf'
        set -g @plugin 'tmux-plugins/tmux-resurrect'
        set -g @plugin 'tmux-plugins/tmux-continuum'

        set -g @plugin 'cappyzawa/akari-tmux'
        set -g @akari_variant 'night'

        # Initialize TMUX plugin manager
        run -b '~/.config/tmux/plugins/tpm/tpm'
      '';
    };

    # Starship prompt
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        palette = "akari-night";
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

        "os.symbols" = {
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

        "env_var.ARCH" = {
          variable = "ARCH";
          default = "x86_64";
          style = "lantern";
        };

        "custom.nvimshell" = {
          command = "echo ";
          when = "test -n \"$NVIM\"";
          format = "in [$output]($style)";
          style = "bold life";
        };

        "palettes.akari-night" = {
          black = "#1E1C19";
          red = "#D25046";
          green = "#7FAF6A";
          yellow = "#D4A05A";
          blue = "#5A6F82";
          purple = "#8E7BA0";
          cyan = "#6F8F8A";
          white = "#E6DED3";
          bright-black = "#716A5F";
          bright-red = "#DE7F77";
          bright-green = "#A1C492";
          bright-yellow = "#E4C397";
          bright-blue = "#8195A8";
          bright-purple = "#B4A7C0";
          bright-cyan = "#9AB1AD";
          bright-white = "#EFEAE3";
          lantern = "#E26A3B";
          ember = "#D65A3A";
          life = "#7FAF6A";
          night = "#5A6F82";
          rain = "#6F8F8A";
          muted = "#8E7BA0";
        };
      };
    };

    # gh (GitHub CLI)
    gh = {
      enable = true;
      extensions = with pkgs; [
        gh-dash
      ];
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };

    # bat
    bat = {
      enable = true;
      config = {
        theme = "akari-night";
        pager = "less -FR";
      };
      themes = {
        akari-night = {
          src = ../../config/bat/themes;
          file = "akari-night.tmTheme";
        };
      };
    };

    # lazygit
    lazygit = {
      enable = true;
      settings = {
        gui = {
          theme = {
            # Akari Night theme
            activeBorderColor = [ "#E26A3B" "bold" ];
            inactiveBorderColor = [ "#3F4346" ];
            optionsTextColor = [ "#E6DED3" ];
            selectedLineBgColor = [ "#51422E" ];
            cherryPickedCommitBgColor = [ "#3F2A25" ];
            cherryPickedCommitFgColor = [ "#E26A3B" ];
            unstagedChangesColor = [ "#D25046" ];
            defaultFgColor = [ "#E6DED3" ];
            searchingActiveBorderColor = [ "#D4A05A" ];
          };
        };
      };
    };

    # direnv
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # fzf
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        # Akari Night theme
        "--color=fg:#E6DED3,bg:#25231F,hl:#E26A3B"
        "--color=fg+:#E6DED3,bg+:#51422E,hl+:#E26A3B"
        "--color=border:#3F4346,header:#9BABB9,gutter:#25231F"
        "--color=spinner:#E26A3B,info:#7A8FA2"
        "--color=pointer:#E26A3B,marker:#7FAF6A,prompt:#E26A3B"
        "--height 40%"
        "--reverse"
        "--border"
      ];
    };

    # eza (modern ls)
    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      git = true;
    };

    # Neovim (minimal - plugins managed by lazy.nvim)
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
