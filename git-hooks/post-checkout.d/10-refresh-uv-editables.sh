#!/bin/bash
# On a fresh clone (previous HEAD is all zeros), registers the repo in the
# local-packages registry if it's one of your own (jasper-tms/NeLy-EPFL).
# Always refreshes the auto-generated [tool.uv.sources] block.
set -e

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

if [ "$1" = "0000000000000000000000000000000000000000" ]; then
    refresh-uv-editables --fresh-clone "$repo_root" || true
fi

if [ -f "$repo_root/pyproject.toml" ]; then
    refresh-uv-editables "$repo_root/pyproject.toml" || true
fi
