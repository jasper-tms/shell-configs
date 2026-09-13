# MCP servers

Model Context Protocol servers that give Claude Code extra native tools. Each
subdirectory is one server; `../configure.sh` registers them at user scope with
`claude mcp add`, so every Claude session on the machine can call them.

## filetypes

A stdio server whose tools annotate every entry by type (file / directory /
symlink-and-its-target / executable) — the type information Claude Code's
built-in tools omit:

- `glob_plus` is a superset of the built-in Glob tool (same recursive pattern
  matching, most-recently-modified first) with every result annotated by type.
  The built-in Glob is denied in `settings.json` and this replaces it; a note
  in `../CLAUDE.md` tells Claude to reach for it.
- `list_directory` is an annotated `ls` of a single directory.

## Gotcha: the `mcp` package is on version 2

As of `mcp` 2.0 the server helper class `FastMCP` was renamed to `MCPServer`:

```python
from mcp.server import MCPServer          # version 2
# from mcp.server.fastmcp import FastMCP  # version 1, and most tutorials online
```

Nearly every tutorial online still shows the version 1 `FastMCP` import, so code
copied from them fails with `No module named 'mcp.server.fastmcp'`. Pin
`mcp<2` only if you specifically need the old API.
