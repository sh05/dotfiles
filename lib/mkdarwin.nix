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
}:

let
  inherit (inputs) nixpkgs nix-darwin home-manager tpm;
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

  specialArgs = {
    inherit inputs tpm;
    configName = name;
    currentUser = user;
    username = user; # backward compatibility
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
          inherit gh-branch-pkg gh-ghq-cd-pkg;
        };
        users.${user} = import ../nix/home;
      };
    }
  ];
}
