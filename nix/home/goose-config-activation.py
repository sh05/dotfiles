#!/usr/bin/env python3
"""Mutable config ownership checks and one-time Goose seed creation.

Unmanaged mode never modifies the Goose config target. Seed mode creates a
writable regular file only when the target has no filesystem entry at all.
Seed-mode parent traversal is descriptor-relative and rejects symlinks; the
final install uses a same-directory hard link for atomic, no-clobber creation.
"""

from __future__ import annotations

import argparse
import errno
import os
import secrets
import shutil
import stat
import sys
from pathlib import PurePath


class UnsafeState(RuntimeError):
    """The filesystem is not in a state this activation may safely change."""


DIR_FLAGS = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
NOFOLLOW = getattr(os, "O_NOFOLLOW", 0)
CLOEXEC = getattr(os, "O_CLOEXEC", 0)


def _require_safe_platform() -> None:
    if not getattr(os, "O_DIRECTORY", 0) or not NOFOLLOW:
        raise UnsafeState("directory no-follow opens are unavailable on this platform")
    if os.link not in os.supports_dir_fd:
        raise UnsafeState("descriptor-relative hard links are unavailable on this platform")


def _absolute_without_parent_refs(value: str, label: str) -> str:
    if not os.path.isabs(value):
        raise UnsafeState(f"{label} must be an absolute path: {value!r}")
    if ".." in PurePath(value).parts:
        raise UnsafeState(f"{label} must not contain '..': {value!r}")
    return os.path.normpath(value)


def _target_parts(home: str, target: str) -> tuple[str, list[str], str, str]:
    home = _absolute_without_parent_refs(home, "home")
    target = _absolute_without_parent_refs(target, "target")
    try:
        if os.path.commonpath((home, target)) != home:
            raise UnsafeState(f"target is not below home: {target!r}")
    except ValueError as exc:
        raise UnsafeState(f"target and home are on incompatible paths: {exc}") from exc

    relative = os.path.relpath(target, home)
    if relative == ".":
        raise UnsafeState("target must name a file below home")
    parts = relative.split(os.sep)
    if any(part in ("", ".", "..") for part in parts):
        raise UnsafeState(f"target contains an unsafe relative path: {relative!r}")
    return home, parts[:-1], parts[-1], target


def _open_absolute_directory(path: str) -> int:
    """Open every component without following symlinks; return the final fd."""
    path = _absolute_without_parent_refs(path, "directory")
    fd = os.open(os.sep, DIR_FLAGS | CLOEXEC)
    try:
        for component in PurePath(path).parts[1:]:
            if component in ("", os.sep):
                continue
            next_fd = os.open(component, DIR_FLAGS | CLOEXEC, dir_fd=fd)
            os.close(fd)
            fd = next_fd
        return fd
    except OSError as exc:
        os.close(fd)
        if exc.errno in (errno.ELOOP, errno.ENOTDIR):
            raise UnsafeState(f"directory path contains a symlink or non-directory: {path!r}") from exc
        raise


def _is_writable_directory(fd: int) -> bool:
    try:
        return os.access(".", os.W_OK | os.X_OK, dir_fd=fd)
    except (NotImplementedError, TypeError):
        info = os.fstat(fd)
        mode = info.st_mode
        if info.st_uid == os.geteuid():
            return bool(mode & stat.S_IWUSR and mode & stat.S_IXUSR)
        return bool(mode & stat.S_IWGRP and mode & stat.S_IXGRP)


def _open_parent(
    home: str,
    parent_parts: list[str],
    *,
    create: bool,
    dry_run: bool = False,
) -> tuple[int, list[int], str | None]:
    """Open target parent safely, optionally creating missing directories.

    Returns (parent_fd, all_open_fds, first_missing_component). In dry-run mode
    it never creates components and returns the first missing component.
    """
    opened: list[int] = []
    try:
        current_fd = _open_absolute_directory(home)
        opened.append(current_fd)
        missing: str | None = None

        for index, component in enumerate(parent_parts):
            try:
                next_fd = os.open(component, DIR_FLAGS | CLOEXEC, dir_fd=current_fd)
            except FileNotFoundError:
                if not create or dry_run:
                    missing = os.path.join(*parent_parts[index:]) if parent_parts[index:] else component
                    return current_fd, opened, missing
                if not _is_writable_directory(current_fd):
                    raise UnsafeState(f"parent directory is not writable: {home}")
                try:
                    os.mkdir(component, mode=0o700, dir_fd=current_fd)
                except FileExistsError:
                    # A concurrent creator may have installed the directory.
                    pass
                try:
                    next_fd = os.open(component, DIR_FLAGS | CLOEXEC, dir_fd=current_fd)
                except OSError as exc:
                    if exc.errno in (errno.ELOOP, errno.ENOTDIR):
                        raise UnsafeState(
                            f"parent path was replaced by a symlink or non-directory: {component!r}"
                        ) from exc
                    raise
            except OSError as exc:
                if exc.errno in (errno.ELOOP, errno.ENOTDIR):
                    raise UnsafeState(
                        f"parent path contains a symlink or non-directory: {component!r}"
                    ) from exc
                raise
            opened.append(next_fd)
            current_fd = next_fd

        return current_fd, opened, missing
    except Exception:
        for fd in reversed(opened):
            try:
                os.close(fd)
            except OSError:
                pass
        raise


def _close_all(fds: list[int]) -> None:
    for fd in reversed(fds):
        try:
            os.close(fd)
        except OSError:
            pass


def _entry_stat(parent_fd: int, name: str) -> os.stat_result | None:
    try:
        return os.stat(name, dir_fd=parent_fd, follow_symlinks=False)
    except FileNotFoundError:
        return None


def _link_destination(target: str, link_text: str) -> str:
    if os.path.isabs(link_text):
        return os.path.normpath(link_text)
    return os.path.normpath(os.path.join(os.path.dirname(target), link_text))


def _is_home_manager_generation_link(destination: str, store_dir: str) -> bool:
    store_dir = os.path.normpath(store_dir)
    try:
        if os.path.commonpath((store_dir, destination)) != store_dir:
            return False
        relative = os.path.relpath(destination, store_dir)
    except ValueError:
        return False
    components = relative.split(os.sep)
    return (
        len(components) >= 2
        and components[0] not in ("", ".", "..")
        and components[0].endswith("-home-manager-files")
    )


def preflight(args: argparse.Namespace) -> int:
    # This preflight is read-only. In particular, do not reject or repair a
    # symlinked parent directory in unmanaged mode: the target is user-owned,
    # and no path component is opened for writing here.
    home = _absolute_without_parent_refs(args.home, "home")
    target = _absolute_without_parent_refs(args.target, "target")
    try:
        if os.path.commonpath((home, target)) != home:
            raise UnsafeState(f"target is not below home: {target!r}")
    except ValueError as exc:
        raise UnsafeState(f"target and home are on incompatible paths: {exc}") from exc

    try:
        info = os.lstat(target)
        link_text = os.readlink(target) if stat.S_ISLNK(info.st_mode) else None
    except (FileNotFoundError, NotADirectoryError):
        return 0

    if link_text is None:
        return 0

    destination = _link_destination(target, link_text)
    if _is_home_manager_generation_link(destination, args.store_dir):
        print(
            f"{args.label} config ownership check: refusing activation because "
            f"{target} is a Home Manager generation symlink. Home Manager "
            "would remove it during generation cleanup. Preserve it and "
            "perform a separately approved one-shot ownership migration first.",
            file=sys.stderr,
        )
        return 1

    legacy_source = os.path.normpath(os.path.abspath(args.legacy_source))
    legacy_canonical = os.path.realpath(legacy_source)
    # Also catch a relocated checkout: mkDarwin's current dotfilesRoot may
    # differ from the checkout used when the legacy link was installed.
    # A suffix match is intentionally conservative; it fails closed without
    # reading or modifying either the link or its destination.
    canonical_destination = os.path.realpath(destination)
    legacy_suffix = f"/config/{args.label}/{'config.yaml' if args.label == 'goose' else 'config.toml'}"
    relocated_checkout = canonical_destination.endswith(legacy_suffix)
    if destination == legacy_source or canonical_destination == legacy_canonical or relocated_checkout:
        print(
            f"{args.label} config ownership check: refusing activation because "
            f"{target} still points to the public checkout's runtime config "
            f"({legacy_source}). The no-touch policy will not rewrite it; "
            "perform a separately approved one-shot ownership migration first.",
            file=sys.stderr,
        )
        return 1
    return 0


def _open_seed_source(source: str) -> int:
    source = _absolute_without_parent_refs(source, "seed source")
    # This tracked file is a historical personal runtime config, never a
    # portable template. Reject both a checkout path and the Nix store copy
    # that result from explicitly supplying it as a path-typed seedSource.
    if source.endswith("/config/goose/config.yaml"):
        raise UnsafeState("the historical config/goose/config.yaml is not a seed template")
    try:
        fd = os.open(source, os.O_RDONLY | NOFOLLOW | CLOEXEC)
    except OSError as exc:
        raise UnsafeState(f"cannot open Goose seed source {source!r}: {exc}") from exc
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            raise UnsafeState(f"Goose seed source must be a regular file: {source!r}")
        return fd
    except Exception:
        os.close(fd)
        raise


def _seed(args: argparse.Namespace) -> int:
    _require_safe_platform()
    home, parent_parts, target_name, target = _target_parts(args.home, args.target)
    source_fd = _open_seed_source(args.source)
    source_stat = os.fstat(source_fd)
    if not (source_stat.st_mode & (stat.S_IRUSR | stat.S_IRGRP | stat.S_IROTH)):
        os.close(source_fd)
        raise UnsafeState(f"Goose seed source is not readable: {args.source!r}")

    dry_run = "DRY_RUN" in os.environ
    parent_fd = -1
    opened: list[int] = []
    temporary_name: str | None = None
    temporary_created = False
    try:
        parent_fd, opened, missing = _open_parent(
            home, parent_parts, create=not dry_run, dry_run=dry_run
        )
        if missing is not None:
            if dry_run:
                if not _is_writable_directory(parent_fd):
                    raise UnsafeState(f"parent directory is not writable: {home}")
                print(f"dry-run: would create {missing} below {home} and seed {target}")
                return 0
            raise UnsafeState(f"could not create Goose config parent below {home}: {missing}")

        info = _entry_stat(parent_fd, target_name)
        if info is not None:
            print(f"goose config seed: preserving existing filesystem entry at {target}")
            return 0

        if not _is_writable_directory(parent_fd):
            raise UnsafeState(f"Goose config parent is not writable: {os.path.dirname(target)}")
        if dry_run:
            print(f"dry-run: would seed a writable regular file at {target}")
            return 0

        temporary_name = f".{target_name}.seed-{os.getpid()}-{secrets.token_hex(8)}"
        temporary_fd = os.open(
            temporary_name,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | NOFOLLOW | CLOEXEC,
            0o600,
            dir_fd=parent_fd,
        )
        temporary_created = True
        with os.fdopen(source_fd, "rb", closefd=True) as source, os.fdopen(
            temporary_fd, "wb", closefd=True
        ) as destination_file:
            source_fd = -1
            shutil.copyfileobj(source, destination_file)
            destination_file.flush()
            os.fchmod(destination_file.fileno(), 0o600)
            os.fsync(destination_file.fileno())

        try:
            os.link(
                temporary_name,
                target_name,
                src_dir_fd=parent_fd,
                dst_dir_fd=parent_fd,
                follow_symlinks=False,
            )
        except FileExistsError:
            print(f"goose config seed: preserving concurrently created entry at {target}")
            return 0
        os.unlink(temporary_name, dir_fd=parent_fd)
        temporary_created = False

        installed = os.stat(target_name, dir_fd=parent_fd, follow_symlinks=False)
        if not stat.S_ISREG(installed.st_mode) or not (installed.st_mode & stat.S_IWUSR):
            raise UnsafeState(f"seeded Goose config is not a writable regular file: {target}")
        print(f"goose config seed: created writable regular file at {target}")
        return 0
    finally:
        if source_fd >= 0:
            os.close(source_fd)
        if temporary_created and temporary_name is not None and parent_fd >= 0:
            try:
                os.unlink(temporary_name, dir_fd=parent_fd)
            except FileNotFoundError:
                pass
        _close_all(opened)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    preflight_parser = subparsers.add_parser("preflight")
    preflight_parser.add_argument("--home", required=True)
    preflight_parser.add_argument("--target", required=True)
    preflight_parser.add_argument("--store-dir", required=True)
    preflight_parser.add_argument("--legacy-source", required=True)
    preflight_parser.add_argument("--label", choices=("goose", "herdr"), default="goose")

    seed_parser = subparsers.add_parser("seed")
    seed_parser.add_argument("--home", required=True)
    seed_parser.add_argument("--target", required=True)
    seed_parser.add_argument("--source", required=True)

    args = parser.parse_args()
    if args.command == "preflight":
        args.store_dir = _absolute_without_parent_refs(args.store_dir, "store directory")
        args.legacy_source = _absolute_without_parent_refs(args.legacy_source, "legacy source")
    return args


def main() -> int:
    args = parse_args()
    try:
        if args.command == "preflight":
            return preflight(args)
        return _seed(args)
    except (OSError, UnsafeState) as exc:
        label = getattr(args, "label", "goose")
        print(f"{label} config ownership check: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
