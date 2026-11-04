#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
command -v nix >/dev/null || { echo "error: nix is required" >&2; exit 127; }

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-policy-eval.XXXXXX")
# macOS exposes /tmp and /var through symlinks; Nix path inputs require a
# canonical physical path, so resolve it before constructing the fixture URI.
tmp_dir=$(cd "$tmp_dir" && pwd -P)
trap 'rm -rf "$tmp_dir"' EXIT
fixture="$tmp_dir/source"
mkdir -p "$fixture"

# Build a local path-source fixture: Nix's git flake source omits untracked
# modules, and this deliberately avoids git add or changing the caller's tree.
while IFS= read -r -d '' file; do
  mkdir -p "$fixture/$(dirname "$file")"
  cp "$file" "$fixture/$file"
done < <(git ls-files -z)
for file in \
  nix/modules/ai-tools.nix \
  nix/home/goose-config-activation.py \
  tests/policy-eval.nix; do
  if [[ ! -f "$file" ]]; then
    echo "error: required fixture source is missing: $file" >&2
    exit 1
  fi
  mkdir -p "$fixture/$(dirname "$file")"
  cp "$file" "$fixture/$file"
done

# A harmless, non-secret path-typed seed fixture; never read the public
# historical Goose runtime config or any ignored/private host files.
cat > "$fixture/tests/seed.yaml" <<'EOF'
# Synthetic Nix policy-eval seed fixture.
{}
EOF

expr="import (builtins.toPath \"$fixture/tests/policy-eval.nix\") { flakeRoot = \"path:$fixture\"; sourceRoot = \"$fixture\"; seedSource = \"$fixture/tests/seed.yaml\"; testUser = \"goose-policy-eval\"; }"
nix eval \
  --extra-experimental-features 'nix-command flakes' \
  --impure \
  --no-update-lock-file \
  --no-write-lock-file \
  --json \
  --expr "$expr"
