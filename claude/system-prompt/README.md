# Claude Code system prompts

Tooling and archived captures of the **system prompt Claude Code sends to the
API**. That prompt is assembled inside the client binary (confirmed, not
server-side) and varies by model, so an old binary run today still emits its
own old prompt.

## get-system-prompt.sh

Captures the real system prompt an interactive `claude` session sends, via the
undocumented `OTEL_LOG_RAW_API_BODIES` hook (runs a throwaway session in a
detached `screen`, then reads the logged request body). Flags:

- `--model <id>` — request a specific model; the prompt is model-conditional.
- `--version <X.Y.Z>` — run an installed version binary instead of `claude` on
  PATH. Resolved against `CLAUDE_VERSIONS_DIR` if set, since the canonical
  versions folder auto-prunes and archival binaries live elsewhere.
- `--archive` — write to `archives/claude-code-v<version>_<model>.md` with a
  provenance header, instead of the default `system-prompt.md`.

## archives/

28 captures across 7 versions x {opus-4-8, opus-5, fable-5, sonnet-5}. Each
header records the exact reproducing command and notes when the binary sent a
different model than requested (pre-Opus-5 2.1.218 falls back opus-5 ->
opus-4-8). Size is set by model, not version: opus-4-8 ~8k, opus-5 ~11.5k,
fable-5 ~12.7k, sonnet-5 ~29.5k chars.
