{ ... }:
{
  # Verification host: the same physical machine as `sh05MacMini`, but the
  # darwinConfiguration targets the `test` account (see flake.nix).
  # Reuse the real host settings so the only difference is the `user`.
  imports = [ ../sh05MacMini ];
}
