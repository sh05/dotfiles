#!/bin/bash
# Run locked Home Manager activation DAG entries against a disposable HOME.
# This is not a nix-darwin activation, switch, uninstall, or GC operation.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
helper="$repo_root/nix/home/goose-config-activation.py"
hm_out="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./. )).inputs.home-manager.outPath')"
nixpkgs_out="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./. )).inputs.nixpkgs.outPath')"
python="$(nix eval --impure --raw --expr 'let f = builtins.getFlake (toString ./.); in f.inputs.nixpkgs.legacyPackages.aarch64-darwin.python3.interpreter')"

root="$(mktemp -d /private/tmp/hm-goose-transition.XXXXXX)"
cleanup() {
  rm -rf "$root"
}
trap cleanup EXIT

export GOOSE_TEST_ROOT="$root"
export GOOSE_TEST_HOME="$root/home"
export GOOSE_TEST_SOURCE="$root/seed.yaml"
export GOOSE_TEST_LEGACY="$root/checkout/config/goose/config.yaml"
export GOOSE_TEST_HELPER="$helper"
export GOOSE_TEST_PYTHON="$python"
mkdir -p "$GOOSE_TEST_HOME" "$(dirname "$GOOSE_TEST_LEGACY")"
printf 'goose:\n  providers: []\n' > "$GOOSE_TEST_SOURCE"
printf 'historical checkout content\n' > "$GOOSE_TEST_LEGACY"
chmod 0644 "$GOOSE_TEST_SOURCE" "$GOOSE_TEST_LEGACY"

python3 - "$repo_root" "$hm_out" "$nixpkgs_out" "$python" <<'PY'
import json
import os
import pathlib
import shutil
import subprocess
import sys
import unittest

repo_root, hm_path, nixpkgs_path, nix_python = map(pathlib.Path, sys.argv[1:])
repo_root = repo_root.resolve()
hm_path = str(hm_path)
nixpkgs_path = str(nixpkgs_path)
nix_python = str(nix_python)
root = pathlib.Path(os.environ["GOOSE_TEST_ROOT"])
home = pathlib.Path(os.environ["GOOSE_TEST_HOME"])
source = pathlib.Path(os.environ["GOOSE_TEST_SOURCE"])
legacy = pathlib.Path(os.environ["GOOSE_TEST_LEGACY"])
helper = pathlib.Path(os.environ["GOOSE_TEST_HELPER"])

if not pathlib.Path("/private/tmp").is_dir():
    raise SystemExit("/private/tmp is required for the disposable HOME")
if not pathlib.Path(nix_python).is_file():
    raise SystemExit("locked nixpkgs Python is unavailable: " + nix_python)

# Read all dynamic paths from the explicitly supplied process environment.
# No host home or Goose runtime configuration is imported by this module.
config_path = root / "hm-transition.nix"
config_path.write_text(
    r'''{ pkgs, lib, ... }:
    let
      helper = builtins.getEnv "GOOSE_TEST_HELPER";
      nix_python = builtins.getEnv "GOOSE_TEST_PYTHON";
      home = builtins.getEnv "GOOSE_TEST_HOME";
      source = builtins.getEnv "GOOSE_TEST_SOURCE";
      legacy = builtins.getEnv "GOOSE_TEST_LEGACY";
      generation = builtins.getEnv "GOOSE_TEST_GENERATION";
      mode = builtins.getEnv "GOOSE_TEST_MODE";
      preflightEnabled = builtins.getEnv "GOOSE_TEST_PREFLIGHT" != "0";
      storeDir = builtins.storeDir;
      nixStubs = pkgs.runCommand "hm-goose-test-nix-stubs" { } ''
        mkdir -p "$out/bin"
        for name in nix-build nix-env nix-store; do
          printf '#!/bin/sh\\nexit 0\\n' > "$out/bin/$name"
          chmod 0755 "$out/bin/$name"
        done
      '';
    in {
      home.username = "goose-test";
      home.homeDirectory = home;
      home.stateVersion = "24.11";
      home.packages = [ ];
      home.extraActivationPath = [ nixStubs ];
      home.activationGenerateGcRoot = false;

      home.file = lib.mkIf (generation == "old") {
        ".config/goose/config.yaml".source = pkgs.writeText "old-hm-goose-config.yaml" "managed-by-old-generation";
      };

      home.activation.gooseConfigPreflight =
        if preflightEnabled then
          lib.hm.dag.entryBefore [ "writeBoundary" ] ''
            "${nix_python}" "${helper}" preflight --home "${home}" --target "${home}/.config/goose/config.yaml" --store-dir "${storeDir}" --legacy-source "${legacy}"
          ''
        else
          lib.hm.dag.entryBefore [ "writeBoundary" ] " : ";

      home.activation.gooseConfigSeed = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ "${mode}" = seed ]; then
          "${nix_python}" "${helper}" seed --home "${home}" --target "${home}/.config/goose/config.yaml" --source "${source}"
        fi
      '';

      # Keep the real writeBoundary (driver version 1 makes it a no-op), but
      # prevent Home Manager from installing packages or updating user profiles.
      home.activation.installPackages = lib.mkForce (lib.hm.dag.entryAfter [ "writeBoundary" ] " : ");
    }
    '''
    ,
    encoding="utf-8",
)

expression = '''let
  pkgs = import __NIXPKGS__ { system = "aarch64-darwin"; };
  hm = import (__HM__ + "/modules") {
    inherit pkgs;
    configuration = import __CONFIG__;
    extraSpecialArgs = { };
  };
in hm.activationPackage'''
expression = (
    expression.replace("__NIXPKGS__", json.dumps(nixpkgs_path))
    .replace("__HM__", json.dumps(hm_path))
    .replace("__CONFIG__", json.dumps(str(config_path)))
)

build_cache = {}
def build_generation(generation, mode="unmanaged", preflight=True):
    key = (generation, mode, preflight)
    if key in build_cache:
        return build_cache[key]
    env = os.environ.copy()
    env.update({
        "GOOSE_TEST_GENERATION": generation,
        "GOOSE_TEST_MODE": mode,
        "GOOSE_TEST_PREFLIGHT": "1" if preflight else "0",
    })
    result = subprocess.run(
        ["nix", "build", "--impure", "--no-link", "--print-out-paths", "--expr", expression],
        cwd=str(repo_root),
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=300,
        check=False,
    )
    if result.returncode:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise RuntimeError("failed to build locked HM activation package for " + repr(key))
    output = pathlib.Path(result.stdout.strip().splitlines()[-1])
    if not (output / "activate").is_file():
        raise RuntimeError("activation package has no activate script: " + str(output))
    build_cache[key] = output
    return output

# Build each exact locked HM generation configuration once, before running any
# activation. These builds only produce store outputs; activation HOME paths
# remain in /private/tmp.
old_generation = build_generation("old")
new_generation = build_generation("new")
new_unchecked_generation = build_generation("new", preflight=False)
seed_generation = build_generation("new", mode="seed")

class HomeManagerTransitionTests(unittest.TestCase):
    def setUp(self):
        self.state_home = root / "xdg-state"
        self.nix_state = root / "nix-state"
        self.reset_home()

    def reset_home(self):
        for path in (home, self.state_home, self.nix_state):
            if path.is_symlink() or path.is_file():
                path.unlink()
            elif path.exists():
                shutil.rmtree(path)
        home.mkdir(parents=True)
        (self.state_home / "nix/profiles").mkdir(parents=True)
        (self.nix_state / "profiles/per-user/goose-test").mkdir(parents=True)

    def mark_current_generation(self, generation):
        gc_roots = self.state_home / "home-manager/gcroots"
        gc_roots.mkdir(parents=True, exist_ok=True)
        current = gc_roots / "current-home"
        if current.is_symlink() or current.exists():
            current.unlink()
        current.symlink_to(generation)

    def activate(self, generation):
        env = os.environ.copy()
        env.update({
            "HOME": str(home),
            "USER": "goose-test",
            "TMPDIR": "/private/tmp",
            "XDG_STATE_HOME": str(self.state_home),
            "NIX_STATE_DIR": str(self.nix_state),
            "SKIP_SANITY_CHECKS": "1",
        })
        # Do not set DRY_RUN: real locked linkGeneration cleanup/link and the
        # seed helper must run, all confined to the throwaway HOME.
        env.pop("DRY_RUN", None)
        return subprocess.run(
            [str(generation / "activate"), "--driver-version", "1"],
            cwd=str(home),
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=90,
            check=False,
        )

    def test_two_generations_fail_closed_before_hm_removes_old_config_link(self):
        old = self.activate(old_generation)
        self.assertEqual(old.returncode, 0, old.stdout + old.stderr)
        target = home / ".config/goose/config.yaml"
        self.assertTrue(target.is_symlink())
        old_link = os.readlink(target)
        self.assertIn("home-manager-files", old_link)
        old_generation_file = pathlib.Path(old_link)
        self.assertTrue(old_generation_file.is_file())
        self.mark_current_generation(old_generation)

        new = self.activate(new_generation)
        self.assertNotEqual(new.returncode, 0, new.stdout + new.stderr)
        self.assertIn("Home Manager generation symlink", new.stderr)
        # Preflight precedes writeBoundary/linkGeneration, so the old HM link
        # is still there; without the guard, locked cleanup below removes it.
        self.assertTrue(target.is_symlink())
        self.assertEqual(os.readlink(target), old_link)
        self.assertTrue(old_generation_file.is_file())

    def test_locked_hm_cleanup_without_preflight_removes_old_generation_link(self):
        old = self.activate(old_generation)
        self.assertEqual(old.returncode, 0, old.stdout + old.stderr)
        target = home / ".config/goose/config.yaml"
        self.assertTrue(target.is_symlink())
        self.mark_current_generation(old_generation)

        new = self.activate(new_unchecked_generation)
        self.assertEqual(new.returncode, 0, new.stdout + new.stderr)
        self.assertFalse(os.path.lexists(target))
        self.assertFalse((home / ".config/goose").exists())

    def test_real_hm_seed_then_unmanaged_keeps_regular_config(self):
        seeded = self.activate(seed_generation)
        self.assertEqual(seeded.returncode, 0, seeded.stdout + seeded.stderr)
        target = home / ".config/goose/config.yaml"
        self.assertTrue(target.is_file())
        self.assertFalse(target.is_symlink())
        expected = source.read_bytes()
        self.assertEqual(target.read_bytes(), expected)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        self.mark_current_generation(seed_generation)

        unmanaged = self.activate(new_generation)
        self.assertEqual(unmanaged.returncode, 0, unmanaged.stdout + unmanaged.stderr)
        self.assertTrue(target.is_file())
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_bytes(), expected)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)

suite = unittest.defaultTestLoader.loadTestsFromTestCase(HomeManagerTransitionTests)
result = unittest.TextTestRunner(verbosity=2).run(suite)
sys.exit(not result.wasSuccessful())
PY
