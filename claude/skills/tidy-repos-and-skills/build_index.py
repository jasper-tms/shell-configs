#!/usr/bin/env python3
"""
Build an INDEX.md advertising the skills in an agent-skills folder.

A skill folder is not always auto-discovered from wherever an agent is
working, so each such folder carries an INDEX.md that lists its skills'
names and one-line descriptions. Another skill (for example movim's
`movim-repo-skills`) points agents at that INDEX.md so they can pick the
right SKILL.md to open.

Usage
-----
    build_index.py [SKILLS_DIR]

SKILLS_DIR defaults to the current directory. Every immediate subdirectory
that contains a SKILL.md is indexed. The INDEX.md is (over)written in
SKILLS_DIR and looks exactly like this, and nothing more:

    # Skill index for `<repo-relative-folder>/`
    Each skill below can be found at `<repo-relative-folder>/<skill-name>/SKILL.md`
    - name: <skill-1-name>. description: <description>
    - name: <skill-2-name>. description: <description>

The `<repo-relative-folder>` is the folder's path from its git repository
root, prefixed with the repo's own directory name (e.g.
`shell-configs/claude/skills`). That form is stable across every clone of
the repo, so the committed INDEX.md stays correct on other machines. If the
folder is not inside a git repository, its bare directory name is used.
"""
import subprocess
import sys
from pathlib import Path


def read_frontmatter(skill_md: Path) -> dict:
    """
    Return the YAML frontmatter of a SKILL.md as a flat dict of strings.

    Only the leading `---` fenced block is read, and only simple
    `key: value` lines. A value that wraps onto following indented lines
    (no `key:` of its own) is joined back into one space-separated string,
    so an accidentally hard-wrapped description still comes out whole.
    """
    lines = skill_md.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    fields: dict[str, str] = {}
    current_key: str | None = None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        stripped = line.strip()
        # A "key: value" line starts a new field; anything else continues
        # the value of the field above it.
        if current_key is not None and (not stripped or line[0] in " \t") \
                and ":" not in stripped.split(" ", 1)[0]:
            fields[current_key] = (fields[current_key] + " " + stripped).strip()
            continue
        if ":" in stripped:
            key, _, value = stripped.partition(":")
            key = key.strip()
            value = value.strip()
            if (value.startswith('"') and value.endswith('"')) or \
                    (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]
            fields[key] = value
            current_key = key
        else:
            current_key = None
    return fields


def repo_relative_folder(skills_dir: Path) -> str:
    """
    Return skills_dir's path from its git repo root, prefixed with the
    repo's own directory name (e.g. `shell-configs/claude/skills`).

    This form is identical in every clone of the repo regardless of where
    the clone lives, so it stays correct in the committed INDEX.md. If
    skills_dir is not inside a git repository, its bare name is returned.
    """
    skills_dir = skills_dir.resolve()
    try:
        top = subprocess.run(
            ["git", "-C", str(skills_dir), "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return skills_dir.name
    repo_root = Path(top)
    relative = skills_dir.relative_to(repo_root)
    # `repo_root.name / relative` unless skills_dir *is* the repo root, in
    # which case relative is "." and we want just the repo name.
    if str(relative) == ".":
        return repo_root.name
    return f"{repo_root.name}/{relative.as_posix()}"


def build_index(skills_dir: Path) -> str:
    """Return the full text of the INDEX.md for skills_dir."""
    folder = repo_relative_folder(skills_dir)
    entries = []
    for child in sorted(skills_dir.iterdir(), key=lambda p: p.name):
        skill_md = child / "SKILL.md"
        if not (child.is_dir() and skill_md.is_file()):
            continue
        fields = read_frontmatter(skill_md)
        name = fields.get("name") or child.name
        description = fields.get("description", "").strip()
        if not description:
            print(f"warning: {skill_md} has no description", file=sys.stderr)
        entries.append((name, description))

    header = f"# Skill index for `{folder}/`"
    path_line = (
        f"Each skill below can be found at "
        f"`{folder}/<skill-name>/SKILL.md`"
    )
    bullets = [f"- name: {name}. description: {description}"
               for name, description in entries]
    return "\n".join([header, path_line, *bullets]) + "\n"


def main() -> None:
    skills_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    if not skills_dir.is_dir():
        sys.exit(f"not a directory: {skills_dir}")
    index_path = skills_dir / "INDEX.md"
    index_path.write_text(build_index(skills_dir), encoding="utf-8")
    print(f"wrote {index_path}")


if __name__ == "__main__":
    main()
