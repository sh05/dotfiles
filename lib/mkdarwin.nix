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

  # herdr ships its own flake exposing a `herdr` package (Rust source build).
  herdr-pkg = inputs.herdr.packages.${system}.herdr;

  # ccstatusline — Claude Code status line formatter, fetched from npm registry.
  # The npm tarball ships a pre-built Bun bundle at dist/ccstatusline.js.
  # To update: bump version, re-run nix-prefetch-url, update hash.
  ccstatusline-pkg = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "ccstatusline";
    version = "2.2.19";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
      hash = "sha256-ZECyfJStzolhs1EQrrbq6svXCtvcpj6YJRPjFIazLSw=";
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
    ../hosts/${name}
    ../nix/darwin
    ../nix/modules/shared.nix
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = specialArgs // {
          inherit gh-branch-pkg gh-ghq-cd-pkg ccstatusline-pkg herdr-pkg;
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
