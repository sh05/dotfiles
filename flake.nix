{
  description = "sh05's dotfiles with Nix Flakes + nix-darwin + home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # gh extensions (not in nixpkgs) — packaged via flake inputs.
    # gh-ghq-cd ships its own flake; gh-branch is a single shell script.
    gh-ghq-cd = {
      url = "github:cappyzawa/gh-ghq-cd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gh-branch = {
      url = "github:mislav/gh-branch";
      flake = false;
    };

    # Akari theme — centralised palette/theme management for supported tools.
    akari-theme = {
      url = "github:cappyzawa/akari-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }@inputs:
    let
      mkDarwin = import ./lib/mkdarwin.nix { inherit inputs; };
    in
    {
      darwinConfigurations = {
        # Each entry is a (machine, user) pair. `user` MUST match the macOS
        # account name (`whoami`) of whoever runs `make switch` for that host.
        "sh05MacminiM2" = mkDarwin "sh05MacminiM2" { user = "sh05"; };

        # Verification host: same machine, applied to the `test` account.
        # "sh05MacMini-test" = mkDarwin "sh05MacMini-test" { user = "test"; };
        "shogonakamotoubie-partnerscoms-MacBook-Pro" = mkDarwin "shogonakamotoubie-partnerscoms-MacBook-Pro" { user = "shogo.nakamoto"; };
      };
    };
}
