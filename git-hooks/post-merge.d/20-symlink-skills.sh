#!/bin/bash
# Offers to symlink any new skills/ or agent-skills/ folders into Claude's global
# skills folder. See shell_scripts/symlink-skills for the logic.
set -e
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
symlink-skills "$repo_root"
