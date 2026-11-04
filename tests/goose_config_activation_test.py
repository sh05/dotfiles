#!/usr/bin/env python3
"""Disposable-filesystem tests for nix/home/goose-config-activation.py.

Run with Python 3.10+ (the locked nixpkgs Python is suitable):
  python3 tests/goose_config_activation_test.py

Every filesystem fixture, including HOME and the source template, lives below
/private/tmp. No Goose process or real user configuration is accessed.
"""

import os
import pathlib
import stat
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True

REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
ACTIVATION_HELPER = REPO_ROOT / "nix/home/goose-config-activation.py"
HOME_MODULE = REPO_ROOT / "nix/home/default.nix"
PYTHON = os.environ.get("GOOSE_TEST_PYTHON", sys.executable)


class GooseConfigActivationTests(unittest.TestCase):
    def setUp(self):
        if sys.version_info < (3, 10):
            self.skipTest("the activation helper uses Python 3.10+ syntax")
        self._tmp = tempfile.TemporaryDirectory(
            prefix="goose-config-activation-", dir="/private/tmp"
        )
        self.root = pathlib.Path(self._tmp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.target = self.home / ".config/goose/config.yaml"
        self.source = self.root / "seed.yaml"
        self.source.write_bytes(b"goose:\n  providers: []\n")
        self.source.chmod(0o644)
        self.store_dir = self.root / "nix/store"
        self.store_dir.mkdir(parents=True)
        self.legacy_source = self.root / "checkout/config/goose/config.yaml"
        self.legacy_source.parent.mkdir(parents=True)
        self.legacy_source.write_bytes(b"historical public checkout config\n")

    def tearDown(self):
        if hasattr(self, "_tmp"):
            self._tmp.cleanup()

    def _argv(
        self,
        command,
        *,
        home=None,
        target=None,
        source=None,
        store_dir=None,
        legacy_source=None,
    ):
        argv = [PYTHON, str(ACTIVATION_HELPER), command]
        argv += ["--home", str(home if home is not None else self.home)]
        argv += ["--target", str(target if target is not None else self.target)]
        if command == "preflight":
            argv += [
                "--store-dir",
                str(store_dir if store_dir is not None else self.store_dir),
                "--legacy-source",
                str(legacy_source if legacy_source is not None else self.legacy_source),
            ]
        else:
            argv += ["--source", str(source if source is not None else self.source)]
        return argv

    def invoke(self, command, *, env=None, **kwargs):
        child_env = os.environ.copy()
        child_env.pop("DRY_RUN", None)
        child_env["HOME"] = str(kwargs.get("home", self.home))
        child_env["TMPDIR"] = "/private/tmp"
        if env:
            child_env.update(env)
        return subprocess.run(
            self._argv(command, **kwargs),
            cwd=str(REPO_ROOT),
            env=child_env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            check=False,
        )

    def assert_cli_ok(self, result, message=None):
        self.assertEqual(
            result.returncode,
            0,
            message or "stdout={!r}, stderr={!r}".format(result.stdout, result.stderr),
        )

    def test_preflight_missing_target_is_a_noop(self):
        result = self.invoke("preflight")
        self.assert_cli_ok(result)
        self.assertFalse(os.path.lexists(self.target))

    def test_preflight_regular_file_is_a_noop(self):
        self.target.parent.mkdir(parents=True)
        self.target.write_bytes(b"user-owned config\n")
        self.target.chmod(0o640)
        before = self.target.stat()

        result = self.invoke("preflight")

        self.assert_cli_ok(result)
        after = self.target.stat()
        self.assertEqual(self.target.read_bytes(), b"user-owned config\n")
        self.assertEqual(stat.S_IMODE(after.st_mode), stat.S_IMODE(before.st_mode))
        self.assertEqual(after.st_ino, before.st_ino)

    def test_preflight_directory_target_is_a_noop(self):
        self.target.mkdir(parents=True)
        sentinel = self.target / "keep"
        sentinel.write_text("do not touch", encoding="utf-8")

        result = self.invoke("preflight")

        self.assert_cli_ok(result)
        self.assertTrue(self.target.is_dir())
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "do not touch")

    def test_preflight_valid_unmanaged_symlink_is_a_noop(self):
        self.target.parent.mkdir(parents=True)
        referent = self.root / "user-config.yaml"
        referent.write_bytes(b"valid referent\n")
        self.target.symlink_to(referent)
        before_link = os.readlink(self.target)
        before_referent = referent.read_bytes()

        result = self.invoke("preflight")

        self.assert_cli_ok(result)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), before_link)
        self.assertEqual(referent.read_bytes(), before_referent)

    def test_preflight_dangling_unmanaged_symlink_is_a_noop(self):
        self.target.parent.mkdir(parents=True)
        missing = self.root / "not-created.yaml"
        self.target.symlink_to(missing)
        before_link = os.readlink(self.target)

        result = self.invoke("preflight")

        self.assert_cli_ok(result)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), before_link)
        self.assertFalse(missing.exists())

    def test_preflight_allows_symlinked_parent_without_writing_through_it(self):
        external = self.root / "external-config"
        external_goose = external / "goose"
        external_goose.mkdir(parents=True)
        external_target = external_goose / "config.yaml"
        external_target.write_bytes(b"outside referent\n")
        config_parent = self.home / ".config"
        config_parent.symlink_to(external, target_is_directory=True)
        before = external_target.read_bytes()
        before_link = os.readlink(config_parent)

        result = self.invoke("preflight")

        self.assert_cli_ok(result)
        self.assertTrue(config_parent.is_symlink())
        self.assertEqual(os.readlink(config_parent), before_link)
        self.assertEqual(external_target.read_bytes(), before)

    def test_preflight_rejects_direct_legacy_checkout_symlink_fail_closed(self):
        self.target.parent.mkdir(parents=True)
        self.target.symlink_to(self.legacy_source)
        before_link = os.readlink(self.target)
        before_source = self.legacy_source.read_bytes()

        result = self.invoke("preflight")

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("public checkout", result.stderr)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), before_link)
        self.assertEqual(self.legacy_source.read_bytes(), before_source)

    def test_preflight_rejects_home_manager_generation_symlink_fail_closed(self):
        generation = self.store_dir / "abc123-home-manager-files"
        managed_file = generation / ".config/goose/config.yaml"
        managed_file.parent.mkdir(parents=True)
        managed_file.write_bytes(b"old HM generation content\n")
        self.target.parent.mkdir(parents=True)
        self.target.symlink_to(managed_file)
        before_link = os.readlink(self.target)

        result = self.invoke("preflight")

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("Home Manager generation symlink", result.stderr)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), before_link)
        self.assertEqual(managed_file.read_bytes(), b"old HM generation content\n")

    def test_preflight_rejects_relocated_legacy_checkout_link(self):
        relocated = self.root / "other-checkout/config/goose/config.yaml"
        relocated.parent.mkdir(parents=True)
        relocated.write_text("relocated settings", encoding="utf-8")
        self.target.parent.mkdir(parents=True)
        self.target.symlink_to(relocated)
        result = self.invoke("preflight")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(relocated.read_text(encoding="utf-8"), "relocated settings")

    def test_preflight_rejects_target_outside_home(self):
        outside = self.root / "outside.yaml"
        outside.write_text("unchanged", encoding="utf-8")

        result = self.invoke("preflight", target=outside)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("not below home", result.stderr)
        self.assertEqual(outside.read_text(encoding="utf-8"), "unchanged")

    def test_seed_missing_target_creates_mode_0600_regular_file(self):
        result = self.invoke("seed")

        self.assert_cli_ok(result)
        info = self.target.lstat()
        self.assertTrue(stat.S_ISREG(info.st_mode))
        self.assertEqual(stat.S_IMODE(info.st_mode), 0o600)
        self.assertEqual(self.target.read_bytes(), self.source.read_bytes())
        self.assertTrue(self.target.parent.is_dir())

    def test_seed_preserves_existing_regular_file(self):
        self.target.parent.mkdir(parents=True)
        self.target.write_bytes(b"existing user config\n")
        self.target.chmod(0o640)
        before = self.target.stat()

        result = self.invoke("seed")

        self.assert_cli_ok(result)
        after = self.target.stat()
        self.assertEqual(self.target.read_bytes(), b"existing user config\n")
        self.assertEqual(stat.S_IMODE(after.st_mode), 0o640)
        self.assertEqual(after.st_ino, before.st_ino)

    def test_seed_preserves_existing_directory(self):
        self.target.mkdir(parents=True)
        sentinel = self.target / "keep"
        sentinel.write_text("not a config file", encoding="utf-8")

        result = self.invoke("seed")

        self.assert_cli_ok(result)
        self.assertTrue(self.target.is_dir())
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "not a config file")

    def test_seed_preserves_valid_symlink_and_referent(self):
        self.target.parent.mkdir(parents=True)
        referent = self.root / "linked-user-config.yaml"
        referent.write_bytes(b"symlink referent\n")
        self.target.symlink_to(referent)
        before_link = os.readlink(self.target)

        result = self.invoke("seed")

        self.assert_cli_ok(result)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), before_link)
        self.assertEqual(referent.read_bytes(), b"symlink referent\n")

    def test_seed_preserves_dangling_symlink(self):
        self.target.parent.mkdir(parents=True)
        referent = self.root / "missing-user-config.yaml"
        self.target.symlink_to(referent)
        before_link = os.readlink(self.target)

        result = self.invoke("seed")

        self.assert_cli_ok(result)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), before_link)
        self.assertFalse(referent.exists())

    def test_seeded_config_survives_unmanaged_preflight(self):
        seeded = self.invoke("seed")
        self.assert_cli_ok(seeded)
        before = self.target.stat()
        content = self.target.read_bytes()

        unmanaged_preflight = self.invoke("preflight")

        self.assert_cli_ok(unmanaged_preflight)
        after = self.target.stat()
        self.assertEqual(self.target.read_bytes(), content)
        self.assertEqual(after.st_ino, before.st_ino)
        self.assertEqual(stat.S_IMODE(after.st_mode), 0o600)

    def test_seed_is_idempotent_after_source_changes(self):
        first = self.invoke("seed")
        self.assert_cli_ok(first)
        original = self.target.read_bytes()
        first_info = self.target.stat()

        self.source.write_bytes(b"new template must not replace config\n")
        second = self.invoke("seed")

        self.assert_cli_ok(second)
        second_info = self.target.stat()
        self.assertEqual(self.target.read_bytes(), original)
        self.assertEqual(second_info.st_ino, first_info.st_ino)
        self.assertEqual(stat.S_IMODE(second_info.st_mode), 0o600)

    def test_seed_dry_run_with_existing_parent_does_not_create_target(self):
        self.target.parent.mkdir(parents=True)

        result = self.invoke("seed", env={"DRY_RUN": "1"})

        self.assert_cli_ok(result)
        self.assertIn("dry-run: would seed", result.stdout)
        self.assertFalse(os.path.lexists(self.target))

    def test_seed_dry_run_with_missing_parent_does_not_create_directories(self):
        result = self.invoke("seed", env={"DRY_RUN": "1"})

        self.assert_cli_ok(result)
        self.assertIn("dry-run: would create", result.stdout)
        self.assertFalse((self.home / ".config").exists())
        self.assertFalse(os.path.lexists(self.target))

    def test_seed_dry_run_preserves_existing_entry(self):
        self.target.parent.mkdir(parents=True)
        self.target.write_bytes(b"existing\n")
        before = self.target.stat()

        result = self.invoke("seed", env={"DRY_RUN": "1"})

        self.assert_cli_ok(result)
        after = self.target.stat()
        self.assertIn("preserving existing", result.stdout)
        self.assertEqual(self.target.read_bytes(), b"existing\n")
        self.assertEqual(after.st_ino, before.st_ino)

    def test_seed_competing_processes_install_exactly_one_no_clobber_file(self):
        self.target.parent.mkdir(parents=True)
        sources = []
        contents = set()
        for number in range(8):
            source = self.root / "competitor-{}.yaml".format(number)
            content = ("source-{}\n".format(number).encode("ascii")) + bytes([number]) * 65536
            source.write_bytes(content)
            source.chmod(0o644)
            sources.append(source)
            contents.add(content)

        children = []
        base_env = os.environ.copy()
        base_env.pop("DRY_RUN", None)
        base_env["HOME"] = str(self.home)
        base_env["TMPDIR"] = "/private/tmp"
        for source in sources:
            children.append(
                subprocess.Popen(
                    self._argv("seed", source=source),
                    cwd=str(REPO_ROOT),
                    env=base_env,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
            )

        outcomes = [child.communicate(timeout=60) for child in children]
        returncodes = [child.returncode for child in children]
        self.assertEqual(returncodes, [0] * len(children), repr(outcomes))
        self.assertTrue(self.target.is_file())
        self.assertIn(self.target.read_bytes(), contents)
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)
        self.assertEqual(
            sum("created writable regular file" in stdout for stdout, _ in outcomes), 1
        )
        self.assertEqual(list(self.target.parent.glob(".config.yaml.seed-*")), [])

    def test_seed_rejects_symlinked_target_parent_without_following_it(self):
        external = self.root / "external-parent"
        external.mkdir()
        config_parent = self.home / ".config"
        config_parent.symlink_to(external, target_is_directory=True)
        before_entries = sorted(path.name for path in external.iterdir())

        result = self.invoke("seed")

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("symlink", result.stderr)
        self.assertTrue(config_parent.is_symlink())
        self.assertEqual(sorted(path.name for path in external.iterdir()), before_entries)
        self.assertFalse((external / "goose/config.yaml").exists())

    def test_seed_rejects_symlinked_home_directory(self):
        real_home = self.root / "real-home"
        real_home.mkdir()
        symlink_home = self.root / "symlink-home"
        symlink_home.symlink_to(real_home, target_is_directory=True)
        target = symlink_home / ".config/goose/config.yaml"

        result = self.invoke("seed", home=symlink_home, target=target)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("symlink", result.stderr)
        self.assertFalse((real_home / ".config").exists())

    def test_historical_checkout_config_is_not_a_seed_template(self):
        result = self.invoke("seed", source=self.legacy_source)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not a seed template", result.stderr)
        self.assertFalse(os.path.lexists(self.target))
        self.assertEqual(self.legacy_source.read_bytes(), b"historical public checkout config\n")

    def test_seed_missing_source_fails_before_creating_parent(self):
        missing = self.root / "missing-seed.yaml"

        result = self.invoke("seed", source=missing)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertFalse((self.home / ".config").exists())

    def test_seed_rejects_directory_source(self):
        source_dir = self.root / "source-directory"
        source_dir.mkdir()

        result = self.invoke("seed", source=source_dir)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("regular file", result.stderr)
        self.assertFalse((self.home / ".config").exists())

    def test_seed_rejects_symlink_source(self):
        linked_source = self.root / "linked-seed.yaml"
        linked_source.symlink_to(self.source)

        result = self.invoke("seed", source=linked_source)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("cannot open", result.stderr)
        self.assertFalse((self.home / ".config").exists())

    def test_seed_rejects_source_path_with_parent_reference(self):
        unsafe_source = str(self.root) + "/nested/../seed.yaml"

        result = self.invoke("seed", source=unsafe_source)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("must not contain '..'", result.stderr)
        self.assertFalse((self.home / ".config").exists())

    def test_seed_rejects_source_without_read_permission_bits(self):
        self.source.chmod(0o200)
        try:
            result = self.invoke("seed")
        finally:
            self.source.chmod(0o644)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("seed source", result.stderr)
        self.assertFalse((self.home / ".config").exists())

    @unittest.skipIf(hasattr(os, "geteuid") and os.geteuid() == 0,
                     "root can bypass ordinary directory write permissions")
    def test_seed_rejects_non_writable_existing_parent(self):
        self.target.parent.mkdir(parents=True)
        self.target.parent.chmod(0o500)
        try:
            result = self.invoke("seed")
        finally:
            self.target.parent.chmod(0o700)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("not writable", result.stderr)
        self.assertFalse(os.path.lexists(self.target))

    @unittest.skipIf(hasattr(os, "geteuid") and os.geteuid() == 0,
                     "root can bypass ordinary directory write permissions")
    def test_seed_does_not_create_missing_parent_below_non_writable_home(self):
        self.home.chmod(0o500)
        try:
            result = self.invoke("seed")
        finally:
            self.home.chmod(0o700)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("not writable", result.stderr)
        self.assertFalse((self.home / ".config").exists())

    def test_seed_rejects_target_outside_home(self):
        outside = self.root / "outside.yaml"

        result = self.invoke("seed", target=outside)

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("not below home", result.stderr)
        self.assertFalse(outside.exists())


class HerdrConfigOwnershipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="herdr-config-ownership-", dir="/private/tmp")
        self.root = pathlib.Path(self.tmp.name)
        self.home = self.root / "home"
        self.target = self.home / ".config/herdr/config.toml"
        self.target.parent.mkdir(parents=True)
        self.store = self.root / "nix/store"
        self.store.mkdir(parents=True)
        self.legacy = self.root / "checkout/config/herdr/config.toml"
        self.legacy.parent.mkdir(parents=True)
        self.legacy.write_text("template", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def preflight(self):
        return subprocess.run(
            [PYTHON, str(ACTIVATION_HELPER), "preflight", "--home", str(self.home),
             "--target", str(self.target), "--store-dir", str(self.store),
             "--legacy-source", str(self.legacy), "--label", "herdr"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30,
        )

    def test_generation_link_is_rejected_without_removal(self):
        referent = self.store / "abc-home-manager-files/.config/herdr/config.toml"
        referent.parent.mkdir(parents=True)
        referent.write_text("settings", encoding="utf-8")
        self.target.symlink_to(referent)
        result = self.preflight()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("herdr config ownership", result.stderr)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(referent.read_text(encoding="utf-8"), "settings")

    def test_legacy_checkout_and_relocated_checkout_are_rejected(self):
        for referent in (self.legacy, self.root / "other/config/herdr/config.toml"):
            referent.parent.mkdir(parents=True, exist_ok=True)
            referent.write_text("settings", encoding="utf-8")
            self.target.symlink_to(referent)
            result = self.preflight()
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(self.target.is_symlink())
            self.assertEqual(referent.read_text(encoding="utf-8"), "settings")
            self.target.unlink()

    def test_user_owned_file_is_preserved(self):
        self.target.write_text("local settings", encoding="utf-8")
        before = self.target.stat().st_ino
        self.assertEqual(self.preflight().returncode, 0)
        self.assertEqual(self.target.read_text(encoding="utf-8"), "local settings")
        self.assertEqual(self.target.stat().st_ino, before)


class HomeManagerDagTests(unittest.TestCase):
    def test_preflight_is_before_write_boundary_and_seed_is_after_link_generation(self):
        source = HOME_MODULE.read_text(encoding="utf-8")
        preflight_marker = "home.activation.gooseConfigPreflight ="
        seed_marker = "home.activation.gooseConfigSeed ="
        self.assertIn(preflight_marker, source)
        self.assertIn(seed_marker, source)
        self.assertLess(source.index(preflight_marker), source.index(seed_marker))

        preflight = source.split(preflight_marker, 1)[1].split(seed_marker, 1)[0]
        seed = source.split(seed_marker, 1)[1].split("# Programs configuration", 1)[0]
        self.assertIn('entryBefore [ "writeBoundary" ]', preflight)
        self.assertIn('entryAfter [ "linkGeneration" ]', seed)
        self.assertIn("aiOwnershipPreflight", preflight)
        self.assertIn("goose-config-activation.py} seed", seed)

    def test_seed_hook_is_guarded_by_seed_mode(self):
        source = HOME_MODULE.read_text(encoding="utf-8")
        seed = source.split("home.activation.gooseConfigSeed =", 1)[1].split(
            "# Programs configuration", 1
        )[0]
        self.assertIn('configMode}" = seed', seed)


if __name__ == "__main__":
    unittest.main(verbosity=2)
