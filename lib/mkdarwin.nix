{ inputs }:
let
  inherit (inputs) nixpkgs nix-darwin home-manager tpm;
in
hostname:
{
  system ? "aarch64-darwin",
  username ? "nakamotoshougo",
}:
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = {
    inherit inputs username hostname tpm;
  };
  modules = [
    ../hosts/${hostname}.nix
    ../nix/darwin
    ../nix/modules/shared.nix
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs username hostname tpm;
        };
        users.${username} = import ../nix/home;
        backupFileExtension = "backup";
      };
    }
  ];
}
