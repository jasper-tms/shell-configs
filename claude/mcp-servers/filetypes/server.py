#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=2,<3"]
# ///
"""
A Model Context Protocol (MCP) server that gives Claude filesystem tools which
annotate every entry with its type — regular file, directory, symbolic link
(with its target), or executable.

This exists because Claude Code's built-in tools omit that type information:
the Glob tool returns bare matching paths, so an agent exploring the filesystem
cannot tell a symbolic link apart from a regular file, and cannot even tell a
directory from a file. These tools fill that gap the way `ls -laF` and
`find`-with-annotation would for a human.

Two tools are exposed:

- `glob_plus` is a superset of the built-in Glob tool: it does the same
  recursive pattern matching, sorted most-recently-modified first, but every
  result is annotated by type. It is meant to replace Glob entirely.
- `list_directory` lists a single directory's entries, annotated and sorted
  directories-first — an annotated `ls` for when you want to see one directory
  rather than search a tree.

The `MCPServer` helper from the official `mcp` package handles all of the
protocol machinery, so the only thing left to write is the tool functions
themselves, decorated with `@server.tool()`.
"""
import os
import stat
from pathlib import Path

from mcp.server import MCPServer

# The name given here becomes the server's identity. Inside Claude Code the
# tools appear as `mcp__filetypes__glob_plus` and
# `mcp__filetypes__list_directory` (the `mcp__<server_name>__` prefix is added
# automatically).
server = MCPServer('filetypes')

# A single glob_plus call could match an entire large tree. Cap the number of
# lines returned so the result stays readable and does not flood the context;
# the caller is told when the cap was hit so they can narrow the pattern.
MAXIMUM_RESULTS = 1000


def annotate(full_path: str, display: str) -> str:
    """
    Build a one-line, human-readable description of a single filesystem path,
    annotated with its type.

    Uses `lstat` semantics throughout, so a symbolic link is reported as a link
    (with its target) rather than being silently followed. This is the whole
    point of these tools: a plain listing would follow the link and hide the
    fact that it is a link at all.

    Parameters
    ----------
    full_path : str
        The path on disk to inspect (used for `lstat`, `readlink`, etc.).
    display : str
        The text to show for this entry — a bare name for `list_directory`, or
        the full matched path for `glob_plus`.

    Returns
    -------
    str
        A line such as `is-this-a-link.png -> bg-2.png  [symlink to file]` or
        `scripts/  [directory]`.
    """
    try:
        link_stat = os.lstat(full_path)
    except OSError:
        return f'{display}  [unreadable]'

    if stat.S_ISLNK(link_stat.st_mode):
        try:
            target = os.readlink(full_path)
        except OSError:
            target = '(unreadable)'
        # Resolve what the link ultimately points at, following the chain.
        if not os.path.exists(full_path):
            kind = 'broken symlink'
        elif os.path.isdir(full_path):
            kind = 'symlink to directory'
        else:
            kind = 'symlink to file'
        return f'{display} -> {target}  [{kind}]'

    if stat.S_ISDIR(link_stat.st_mode):
        return f'{display}/  [directory]'

    if stat.S_ISREG(link_stat.st_mode):
        if link_stat.st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH):
            return f'{display}*  [executable file]'
        return f'{display}  [file]'

    # Anything else: a socket, a named pipe, a block or character device, etc.
    return f'{display}  [other]'


@server.tool()
def glob_plus(pattern: str, path: str = '.') -> str:
    """
    Find files and directories matching a glob pattern, annotating each match
    with its type (file / directory / symlink-and-target / executable) — the
    type information the built-in Glob tool omits.

    This is a superset of the built-in Glob tool and should be used in its
    place for every file or pattern search. It does the same recursive pattern
    matching and sorts matches most-recently-modified first, but every result
    line is annotated so symbolic links, directories, and executables are
    distinguishable from regular files without any extra step.

    Parameters
    ----------
    pattern : str
        A glob pattern, for example `*.py`, `src/**/*.ts`, or `**/test_*`. Use
        `**` to match across nested directories.
    path : str
        The directory to search within. Defaults to the current working
        directory. A leading `~` is expanded to the user's home directory.

    Returns
    -------
    str
        The search base and pattern, followed by one annotated line per match
        (absolute paths, most recently modified first), or a message if
        nothing matched.
    """
    base = Path(os.path.abspath(os.path.expanduser(path)))

    if not base.exists():
        return f'Error: no such path: {base}'
    if not base.is_dir():
        return f'Error: not a directory: {base}'

    try:
        matches = list(base.glob(pattern))
    except (ValueError, OSError) as error:
        return f'Error: could not match pattern {pattern!r}: {error}'

    if not matches:
        return f'No matches for pattern {pattern!r} under {base}'

    # Sort most-recently-modified first, mirroring the built-in Glob tool. Use
    # lstat so a symbolic link is ordered by the link's own timestamp rather
    # than by whatever it points at (which may not exist).
    def modification_time(match: Path) -> float:
        try:
            return match.lstat().st_mtime
        except OSError:
            return 0.0

    matches.sort(key=modification_time, reverse=True)

    truncated = len(matches) > MAXIMUM_RESULTS
    shown = matches[:MAXIMUM_RESULTS]

    lines = [f'{base} (pattern {pattern!r}):']
    lines.extend(annotate(str(match), str(match)) for match in shown)
    if truncated:
        lines.append(
            f'... {len(matches) - MAXIMUM_RESULTS} more matches not shown; '
            f'narrow the pattern to see them.'
        )
    return '\n'.join(lines)


@server.tool()
def list_directory(path: str = '.') -> str:
    """
    List the contents of a single directory, annotating each entry with its
    type so that symbolic links, directories, and executables are
    distinguishable from regular files.

    This is an annotated `ls` of one directory. To search a tree by pattern,
    use `glob_plus` instead.

    Parameters
    ----------
    path : str
        The directory to list. Defaults to the current working directory. A
        leading `~` is expanded to the user's home directory.

    Returns
    -------
    str
        The absolute path that was listed, followed by one annotated line per
        entry, sorted with directories first and then alphabetically.
    """
    expanded_path = os.path.abspath(os.path.expanduser(path))

    if not os.path.exists(expanded_path):
        return f'Error: no such path: {expanded_path}'
    if not os.path.isdir(expanded_path):
        return f'Error: not a directory: {expanded_path}'

    try:
        entries = list(os.scandir(expanded_path))
    except PermissionError:
        return f'Error: permission denied: {expanded_path}'

    # Sort directories first, then alphabetically within each group, using a
    # case-insensitive comparison so the ordering reads naturally.
    entries.sort(
        key=lambda entry: (
            not entry.is_dir(follow_symlinks=False),
            entry.name.lower(),
        )
    )

    lines = [f'{expanded_path}:']
    lines.extend(annotate(entry.path, entry.name) for entry in entries)
    return '\n'.join(lines)


if __name__ == '__main__':
    # With no arguments, MCPServer serves over standard input and output, which
    # is exactly what Claude Code expects for a locally launched ("stdio")
    # server.
    server.run()
