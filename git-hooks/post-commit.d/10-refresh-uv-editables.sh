#!/bin/bash
# Refreshes the auto-generated [tool.uv.sources] block after each commit.
set -e

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
if [ -f "$repo_root/pyproject.toml" ]; then
    refresh-uv-editables "$repo_root/pyproject.toml" || true
fi
