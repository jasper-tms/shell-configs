#!/usr/bin/env python3
"""
Validate the frontmatter of every skill the global skill listing knows about.

The Agent Skills spec makes both `name:` and `description:` mandatory in a
SKILL.md's frontmatter, and requires each skill's `name:` to match its parent
directory name. This script enforces all three across every skill named in a
`_SKILL_LISTING.md`, reading the folder set straight from that listing so no
hardcoded folder list can drift out of date: a skill added anywhere the listing
covers gets checked automatically. It reuses the frontmatter parser from
`build_index.py`, which sits alongside this file.

Usage
-----
    validate_skill_frontmatter.py [LISTING]

LISTING defaults to
`~/repos/jasper-tms/raspberry-pi/agent-skills/_SKILL_LISTING.md`. Problems are
printed one per line (or `all listed skills valid` when there are none), and the
exit status is 1 when any problem is found, else 0.

Folders that are absent (repos not cloned on this machine) are skipped. A
`listed but no SKILL.md on disk` line means the listing itself is stale.
"""
import re
import sys
from pathlib import Path

from build_index import read_frontmatter  # reuse the same frontmatter parser

DEFAULT_LISTING = Path(
    '~/repos/jasper-tms/raspberry-pi/agent-skills/_SKILL_LISTING.md'
).expanduser()


def listed_skill_pairs(listing: Path) -> list[tuple[Path, str]]:
    """
    Return every (folder, skill-name) pair named in a `_SKILL_LISTING.md`.

    A header naming an absolute path sets the current folder (and the base for
    relative sub-folder headers like the swiss repo's `### agent-skills/`);
    bullets beneath it are that folder's skills.
    """
    pairs: list[tuple[Path, str]] = []
    base: Path | None = None
    folder: Path | None = None
    for line in listing.read_text(encoding='utf-8').splitlines():
        header = re.match(r'^#+\s+(.*)$', line)
        if header:
            text = header.group(1).strip().strip('`').rstrip('/')
            if text.startswith(('~', '/')):
                base = folder = Path(text).expanduser()
            elif re.fullmatch(r'[\w.-]+', text) and base is not None:
                folder = base / text
            else:
                folder = None  # prose header, not a folder
            continue
        bullet = re.match(r'^-\s+(\S+)', line)
        if bullet and folder is not None:
            pairs.append((folder, bullet.group(1).strip('`')))
    return pairs


def validate(listing: Path) -> list[str]:
    """Return a list of human-readable problem strings, empty when all valid."""
    problems = []
    for folder, name in listed_skill_pairs(listing):
        if not folder.is_dir():
            continue  # repo not cloned on this machine; nothing to check here
        skill_md = folder / name / 'SKILL.md'
        if not skill_md.is_file():
            problems.append(f'{folder / name}: listed but no SKILL.md on disk')
            continue
        fields = read_frontmatter(skill_md)
        fm_name = fields.get('name', '').strip()
        description = fields.get('description', '').strip()
        if not fm_name:
            problems.append(f'{skill_md}: missing mandatory name:')
        elif fm_name != name:
            problems.append(f"{skill_md}: name '{fm_name}' != folder '{name}'")
        if not description:
            problems.append(f'{skill_md}: missing mandatory description:')
    return problems


def main() -> None:
    listing = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_LISTING
    if not listing.is_file():
        sys.exit(f'not a file: {listing}')
    problems = validate(listing)
    print('\n'.join(problems) or 'all listed skills valid')
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
