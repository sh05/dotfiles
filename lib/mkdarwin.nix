{ inputs }:

# Build a darwinSystem for a (machine, user) pair.
#   name : the darwinConfiguration / host name (used for `hosts/<name>`)
#   user : the macOS account name. Defaults to `name`; pass it explicitly
#          whenever the account name differs from the host name. There is no
#          hardcoded fallback, so a missing/wrong user surfaces immediately
#          instead of silently configuring the wrong account.
name:
{
  system ? "aarch64-darwin",
  user ? name,
  dotfilesRoot ? "/Users/${user}/ghq/github.com/sh05/dotfiles",
  hostModule ? ../hosts/${name},
}:

let
  inherit (inputs) nixpkgs nix-darwin home-manager;
  pkgs = nixpkgs.legacyPackages.${system};

  # gh extensions that are not in nixpkgs, packaged from flake inputs.
  # gh-branch is a single shell script (the input is `flake = false`).
  gh-branch-pkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "gh-branch";
    version = "unstable";
    src = inputs.gh-branch;
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      install -Dm755 gh-branch $out/bin/gh-branch
    '';
  };

  # gh-ghq-cd ships its own flake exposing a `gh-ghq-cd` package.
  gh-ghq-cd-pkg = inputs.gh-ghq-cd.packages.${system}.gh-ghq-cd;

  # ccstatusline — Claude Code status line formatter, fetched from npm registry.
  # The npm tarball ships a pre-built Bun bundle at dist/ccstatusline.js.
  # To update: bump version, re-run nix-prefetch-url, update hash.
  ccstatusline-pkg = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "ccstatusline";
    version = "2.2.22";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
      hash = "sha256-FKDBeocIjiP4xXxNycTAJFlr7s+I8zm+gNv9IchcsQA=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontConfigure = true;
    dontBuild = true;
    unpackPhase = ''
      tar xzf $src
      cd package
    '';
    installPhase = ''
      mkdir -p $out/lib/ccstatusline $out/bin
      cp -r . $out/lib/ccstatusline/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/ccstatusline \
        --add-flags "$out/lib/ccstatusline/dist/ccstatusline.js"
    '';
  };

  # goose — AI agent CLI (github.com/block/goose). Upstream ships a prebuilt
  # aarch64-darwin binary, so we just unpack it.
  #
  # Why not pkgs.goose-cli: our locked nixpkgs has 1.28.0 — goose releases
  # weekly, so nixpkgs runs ~5 months behind while the GUI cask tracks latest.
  # The gap matters: CLI and GUI share ~/.config/goose/config.yaml, and the
  # newer one migrates it in place on read, which the older one cannot parse.
  #
  # Why not the upstream flake: it sets doCheck = true with no skip list
  # (nixpkgs needs ~90 --skip flags for its dbus/keychain/network tests), drags
  # in rust-overlay plus a second nixpkgs that cannot `follows` ours, and has
  # no binary cache — CI builds every darwin config, so that would mean a full
  # v8 + tree-sitter + candle build on every push.
  #
  # The tarball holds exactly one file: ./goose (a ~273MB self-contained
  # binary), already signed by upstream — do not strip or re-sign it.
  #
  # NOTE: pin the versioned tag, never `stable`. `stable` is a rolling tag
  # whose assets are overwritten in place on each release, so a pinned hash
  # against it breaks without warning.
  #
  # To update (keep in sync with the block-goose cask — see `make goose-check`):
  #   v=1.51.0
  #   nix store prefetch-file --json \
  #     "https://github.com/block/goose/releases/download/v$v/goose-aarch64-apple-darwin.tar.gz" \
  #     | jq -r .hash
  goose-pkg = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "goose";
    version = "1.50.0";
    src = pkgs.fetchurl {
      url = "https://github.com/block/goose/releases/download/v${version}/goose-aarch64-apple-darwin.tar.gz";
      hash = "sha256-bx8ftWhomWryZS6LUzTSn5cOVoNuIAxP9X6S3iSW/Ms=";
    };
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    # The archive unpacks to ./goose with no wrapping directory, so the
    # default "cd into the single source dir" heuristic has nothing to find.
    unpackPhase = ''
      tar xzf $src
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 goose $out/bin/goose
      runHook postInstall
    '';
    meta = {
      description = "Open-source, extensible AI agent (prebuilt upstream release)";
      homepage = "https://github.com/block/goose";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "goose";
      platforms = [ "aarch64-darwin" ];
    };
  };

  specialArgs = {
    inherit inputs;
    configName = name;
    currentUser = user;
    username = user; # backward compatibility
    inherit dotfilesRoot;
  };
in
nix-darwin.lib.darwinSystem {
  inherit system specialArgs;

  modules = [
    hostModule
    ../nix/darwin
    ../nix/modules/shared.nix
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = specialArgs // {
          inherit
            gh-branch-pkg
            gh-ghq-cd-pkg
            ccstatusline-pkg
            goose-pkg
            ;
        };
        users.${user} = {
          imports = [
            ../nix/home
            inputs.akari-theme.homeModules.akari
          ];
        };
      };
    }
  ];
}
