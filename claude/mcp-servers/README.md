# MCP servers

Model Context Protocol servers that give Claude Code extra native tools. Each
subdirectory is one server.

## filetypes (deprecated)

No longer registered: agents can't call MCP tools inside compound Bash
commands, so `../CLAUDE.md` now has them use `ls -F` instead. Kept as a
template of a working MCP server.

A stdio server whose tools annotate every entry by type (file / directory /
symlink-and-its-target / executable):

- `glob_plus` does recursive pattern matching, most-recently-modified first,
  with every result annotated by type.
- `list_directory` is an annotated `ls` of a single directory.

To register it at user scope for every Claude session on the machine (this
writes to `~/.claude.json`, not to this repo):

```bash
claude mcp add filetypes -s user -- \
    uv run --script "$PWD/filetypes/server.py"
```

## Gotcha: the `mcp` package is on version 2

As of `mcp` 2.0 the server helper class `FastMCP` was renamed to `MCPServer`:

```python
from mcp.server import MCPServer          # version 2
# from mcp.server.fastmcp import FastMCP  # version 1, and most tutorials online
```

Nearly every tutorial online still shows the version 1 `FastMCP` import, so code
copied from them fails with `No module named 'mcp.server.fastmcp'`. Pin
`mcp<2` only if you specifically need the old API.
