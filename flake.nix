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
    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      tpm,
      ...
    }@inputs:
    let
      mkDarwin = import ./lib/mkdarwin.nix { inherit inputs; };
    in
    {
      darwinConfigurations = {
        "sh05MacMini" = mkDarwin "sh05MacMini" { };
      };
    };
}
